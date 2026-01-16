#!/usr/bin/env node

/*
  xml2md - Convert XML docs to Markdown via XSLT (Node-only)

  Usage:
    xml2md <inputPath> -o <outDir> [--recurse|-r] [--xslt <xsltPath>] [--engine xslt-processor|libxml2-wasm]

  Notes:
  - Uses a pure Node engine. Default engine: xslt-processor
  - Optionally supports libxml2-wasm if installed.
  - Writes Markdown files under <outDir>, mirroring the input structure and changing .xml to .md.
*/

const fs = require('fs');
const fsp = fs.promises;
const path = require('path');
const { spawn } = require('child_process');

function printHelp() {
  console.log(`xml2md - Convert XML docs to Markdown via XSLT\n\nUsage:\n  xml2md <inputPath> -o <outDir> [--recurse|-r] [--xslt <xsltPath>] [--engine dotnet|xslt-processor|libxml2-wasm] [-v]\n\nNotes:\n  - Default engine on Windows: dotnet (PowerShell + XslCompiledTransform)\n  - Default elsewhere: xslt-processor\n\nExamples:\n  xml2md docs/ -o out/ --recurse\n  xml2md topic.xml -o out/ --xslt xform-md.xslt\n  xml2md docs/ -o out/ -r --engine xslt-processor\n  xml2md docs/ -o out/ -r --engine libxml2-wasm\n  xml2md docs/ -o out/ -r --engine dotnet\n`);
}

function parseArgs(argv) {
  const args = { _: [], verbose: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') { args.help = true; }
    else if (a === '-o' || a === '--out') { args.out = argv[++i]; }
    else if (a === '-r' || a === '--recurse' || a === '--recursive') { args.recurse = true; }
    else if (a === '--xslt') { args.xslt = argv[++i]; }
    else if (a === '--engine') { args.engine = argv[++i]; }
    else if (a === '--ps' || a === '--dotnet') { args.engine = 'dotnet'; }
    else if (a === '-v' || a === '--verbose') { args.verbose = true; }
    else if (a.startsWith('-')) { throw new Error(`Unknown option: ${a}`); }
    else { args._.push(a); }
  }
  return args;
}

async function pathExists(p) { try { await fsp.access(p); return true; } catch { return false; } }

async function ensureDir(p) { await fsp.mkdir(p, { recursive: true }); }

function isXmlFile(filePath) { return filePath.toLowerCase().endsWith('.xml'); }

async function collectXmlFiles(inputPath, recurse) {
  const stat = await fsp.stat(inputPath);
  if (stat.isFile()) {
    if (!isXmlFile(inputPath)) throw new Error(`Input file is not .xml: ${inputPath}`);
    return { base: path.dirname(path.resolve(inputPath)), files: [path.resolve(inputPath)] };
  }
  if (!stat.isDirectory()) throw new Error(`Input path is neither file nor directory: ${inputPath}`);
  const base = path.resolve(inputPath);
  const files = [];
  async function walk(dir, depth = 0) {
    const entries = await fsp.readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (recurse) await walk(full, depth + 1);
      } else if (e.isFile() && isXmlFile(e.name)) {
        files.push(full);
      }
    }
  }
  await walk(base, 0);
  return { base, files };
}

function chooseEngine(requested) {
  if (requested) return requested;
  // Prefer .NET on Windows for full XPath/XSLT 1.0 support
  if (process.platform === 'win32') return 'dotnet';
  return process.platform === 'win32' ? 'dotnet' : 'xslt-processor';
}

async function transformWithXsltProcessor(xmlPath, xsltPath, outPath) {
  const xslt = require('xslt-processor');
  const xmlStr = await fsp.readFile(xmlPath, 'utf8');
  const xsltStr = await fsp.readFile(xsltPath, 'utf8');

  if (typeof xslt.xsltProcess === 'function' && typeof xslt.xmlParse === 'function') {
    // Preferred API for text output
    const xml = xslt.xmlParse(xmlStr);
    const xsl = xslt.xmlParse(xsltStr);
    const resultStr = xslt.xsltProcess(xml, xsl);
    await ensureDir(path.dirname(outPath));
    await fsp.writeFile(outPath, resultStr);
    return;
  }

  // Fallback to DOM-based processor
  const { XSLTProcessor, DOMParser, XMLSerializer } = xslt;
  const xml = new DOMParser().parseFromString(xmlStr, 'text/xml');
  const xsl = new DOMParser().parseFromString(xsltStr, 'text/xml');
  const proc = new XSLTProcessor();
  proc.importStylesheet(xsl);
  const result = proc.transformToDocument(xml);
  // Try to pull text content if output method is text
  let text = result && result.textContent ? result.textContent : '';
  if (!text) {
    try { text = new XMLSerializer().serializeToString(result); } catch { /* ignore */ }
  }
  await ensureDir(path.dirname(outPath));
  await fsp.writeFile(outPath, text);
}

async function transformWithDotNet(xmlPath, xsltPath, outPath) {
  // PowerShell + .NET XslCompiledTransform without Add-Type (PS 7 compatible)
  const xsltQ = xsltPath.replace(/'/g, "''");
  const xmlQ = xmlPath.replace(/'/g, "''");
  const outQ = outPath.replace(/'/g, "''");
  const ps = [
    "$ErrorActionPreference='Stop';",
    `$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;`,
    `$xslt.Load('${xsltQ}');`,
    `$reader = [System.Xml.XmlReader]::Create('${xmlQ}');`,
    `$settings = New-Object System.Xml.XmlWriterSettings;`,
    `$settings.OmitXmlDeclaration = $true;`,
    `$settings.ConformanceLevel = [System.Xml.ConformanceLevel]::Auto;`,
    `$settings.Encoding = [System.Text.Encoding]::UTF8;`,
    `[System.IO.Directory]::CreateDirectory((Split-Path '${outQ}' -Parent)) | Out-Null;`,
    `$outStream = [System.IO.File]::Create('${outQ}');`,
    `try { $writer = [System.Xml.XmlWriter]::Create($outStream, $settings); try { $xslt.Transform($reader, $writer) } finally { $writer.Dispose() } } finally { $outStream.Dispose(); $reader.Dispose() }`
  ].join(' ');
  await new Promise((resolve, reject) => {
    const child = spawn('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', ps], { stdio: 'inherit' });
    child.on('error', reject);
    child.on('exit', code => code === 0 ? resolve() : reject(new Error(`dotnet transform failed (${code})`)));
  });
}

async function transformWithLibxml2Wasm(xmlPath, xsltPath, outPath) {
  const mod = await import('libxml2-wasm');
  const libxml = mod.default || mod;
  const xmlStr = await fsp.readFile(xmlPath, 'utf8');
  const xsltStr = await fsp.readFile(xsltPath, 'utf8');
  await libxml.ready;
  // API surface differs by version; try multiple entry points
  const parseXml = libxml.parseXml || libxml.parseXmlString || (libxml.XMLDoc && libxml.XMLDoc.fromString ? (s) => libxml.XMLDoc.fromString(s) : null);
  const parseXslt = libxml.parseXslt || libxml.parseXsltString || (libxml.XSLTStylesheet && libxml.XSLTStylesheet.fromString ? (d) => libxml.XSLTStylesheet.fromString(d) : null);
  if (!parseXml || !parseXslt) {
    throw new Error('libxml2-wasm API not recognized. Try --engine dotnet or --engine xslt-processor');
  }
  const doc = parseXml(xmlStr);
  const styleDoc = parseXml(xsltStr);
  const stylesheet = parseXslt(styleDoc);
  const result = stylesheet.apply(doc);
  const out = typeof result === 'string' ? result : String(result);
  await ensureDir(path.dirname(outPath));
  await fsp.writeFile(outPath, out);
}

async function run() {
  try {
    const args = parseArgs(process.argv);
    if (args.help || args._.length === 0) { printHelp(); process.exit(args.help ? 0 : 1); }

    const inputPath = path.resolve(args._[0]);
    const outRoot = args.out ? path.resolve(args.out) : null;
    if (!outRoot) throw new Error('Missing required -o/--out output directory');

    async function resolveXsltPath(arg) {
      if (arg) {
        const p = path.resolve(arg);
        if (await pathExists(p)) return p;
        throw new Error(`XSLT not found at --xslt path: ${p}`);
      }
      const cwdDefault = path.resolve(path.join(process.cwd(), 'xform-md.xslt'));
      if (await pathExists(cwdDefault)) return cwdDefault;
      const bundled = path.resolve(__dirname, '..', 'xform-md.xslt');
      if (await pathExists(bundled)) return bundled;
      try {
        const resolved = require.resolve('xml2md-cli/xform-md.xslt');
        if (resolved) return resolved;
      } catch {}
      throw new Error('XSLT not found. Pass --xslt <path> or ensure xform-md.xslt is in the current directory or module folder.');
    }

    const xsltPath = await resolveXsltPath(args.xslt);

    if (!(await pathExists(inputPath))) throw new Error(`Input not found: ${inputPath}`);
    await ensureDir(outRoot);

    const { base, files } = await collectXmlFiles(inputPath, !!args.recurse);
    if (files.length === 0) { console.warn('No XML files found to process.'); return; }

    const engine = chooseEngine(args.engine);
    console.log(`Engine: ${engine}`);
    console.log(`Input base: ${base}`);
    console.log(`Output dir: ${outRoot}`);
    if (args.verbose) console.log(`XSLT: ${xsltPath}`);

    for (const xml of files) {
      const rel = path.relative(base, xml);
      const outRel = rel.replace(/\.xml$/i, '.md');
      const outPath = path.join(outRoot, outRel);
      await ensureDir(path.dirname(outPath));
      console.log(`→ ${rel} -> ${path.relative(outRoot, outPath)}`);
      try {
        if (engine === 'xslt-processor') await transformWithXsltProcessor(xml, xsltPath, outPath);
        else if (engine === 'libxml2-wasm') await transformWithLibxml2Wasm(xml, xsltPath, outPath);
        else if (engine === 'dotnet') await transformWithDotNet(xml, xsltPath, outPath);
        else throw new Error(`Unknown engine: ${engine}`);
      } catch (e) {
        console.error(`[xml2md] Failed: ${rel}\n  ${e && e.stack ? e.stack : e}`);
      }
    }

    console.log(`Done. Wrote ${files.length} file(s).`);
  } catch (err) {
    console.error(`[xml2md] Error: ${err.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  run();
}
