# XML → Markdown Transformer

This project converts XML documentation into Markdown using an XSLT (`xform-md.xslt`). It includes a Node.js CLI that walks files or directories, applies the XSLT, and writes `.md` files mirroring the input structure.

## Features

- Faithful Markdown generation from the existing XML schema
- Code examples rendered as fenced code blocks (language from `example/@code` when provided)
- Headings, lists, tables, links, arguments/returns, properties, and methods mapped to Markdown
- Directory recursion with `--recurse`
- Output directory mirrors the source tree (only extension changes to `.md`)
- Multiple transform engines for portability and correctness

## Install

- Requirements: Node.js 16+ (recommended), PowerShell (on Windows).
- Install dependencies:

```bash
npm install
```

## CLI Usage

```bash
xml2md <inputPath> -o <outDir> [--recurse|-r] [--xslt <xsltPath>] [--engine dotnet|xslt-processor|libxml2-wasm] [-v]
```

- `inputPath`: XML file or directory containing `.xml`
- `-o, --out <dir>`: Output root directory (required)
- `-r, --recurse|--recursive`: Recurse into subdirectories when `inputPath` is a directory
- `--xslt <path>`: Path to XSLT (default: `./xform-md.xslt`)
- `--engine <name>`: Choose transform engine (see Engines below)
- `-v, --verbose`: Print extra details (like the XSLT path)
- Shortcuts: `--dotnet` or `--ps` are aliases for `--engine dotnet`

Examples:

```bash
# Convert a single file
node bin/xml2md.js docs/topic.xml -o out/

# Convert a directory (non-recursive)
node bin/xml2md.js docs -o out/

# Convert a directory (recursive)
node bin/xml2md.js docs -o out/ -r

# Explicitly select engine
node bin/xml2md.js docs -o out/ -r --engine xslt-processor
node bin/xml2md.js docs -o out/ -r --engine libxml2-wasm
node bin/xml2md.js docs -o out/ -r --engine dotnet

# Using the bin alias (after npm install)
xml2md docs -o out -r
```

## Engines

The CLI supports three engines to perform the XSLT transform. The default depends on your OS to maximize compatibility and avoid external dependencies.

- `dotnet` (default on Windows)
  - Uses PowerShell and .NET `System.Xml.Xsl.XslCompiledTransform`
  - Full XPath/XSLT 1.0 support; robust for complex stylesheets
  - No external tools required beyond standard Windows/PowerShell

- `xslt-processor` (default on macOS/Linux)
  - Pure Node.js library
  - Fast and easy to install
  - Note: Some environments have limited XPath axis support (e.g., `@attribute` axis). If you encounter XPath parse errors, switch to `dotnet` (on Windows) or try `libxml2-wasm`.

- `libxml2-wasm`
  - WebAssembly port of libxml2/libxslt
  - Standards-compliant XPath/XSLT, but the Node API varies by version
  - Use if you prefer libxml2 semantics; otherwise prefer the defaults

You can override the default engine at any time with `--engine`.

## Output Structure

- The output directory mirrors the input path. For example:
  - `docs/Argument/index.xml` → `out/Argument/index.md`
- Only the file extension changes from `.xml` to `.md`.

## XSLT Notes (`xform-md.xslt`)

- Headings: `topic`/`name` become `#` titles; sections/groups become `##`/`###` as appropriate
- Code samples: `example` elements render as fenced code blocks; language is taken from `example/@code` when present
- Syntax/Prototype: Rendered as fenced code blocks
- Lists: Custom `list` nodes and HTML-like `ul/ol/li` mapped to Markdown lists
- Tables: Rendered as basic Markdown tables (row/col spans are not supported)
- Links: Converted to Markdown links; See Also/Next sections mapped to bullets/inline
- Callouts: `warning`, `deprecated`, `obsolete`, `note`, `important`, `tip` mapped to blockquotes
- Arguments/Returns: Bullet lists with inline type info (e.g., \`name (`Type`) [optional]\`)

## Troubleshooting

- PowerShell error: `Add-Type : The assembly 'System.Xml.Xsl' could not be found`
  - The CLI no longer uses `Add-Type`. We instantiate .NET types directly; update and re-run with `--engine dotnet`.

- XPath parse error mentioning attribute axis (e.g., `topic/@parent`) when using `xslt-processor`
  - Some builds lack full XPath axis support. Use `--engine dotnet` (Windows) or `--engine libxml2-wasm`.

- ESM import error with `libxml2-wasm`
  - We use dynamic `import()` internally. If you still see errors, try `--engine xslt-processor` or `--engine dotnet`.

- Paths with spaces
  - Quote paths on Windows: `node bin/xml2md.js "SQL" -o "out" -r`

## Development

- CLI source: `bin/xml2md.js`
- Markdown stylesheet: `xform-md.xslt`
- Package metadata: `package.json`

---

If you want different heading depths, table formatting, or argument/return display tweaks, open an issue or adjust `xform-md.xslt` accordingly.
