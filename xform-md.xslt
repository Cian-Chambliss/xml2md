<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text" encoding="UTF-8"/>

  <!-- Whitespace helpers (copied from HTML transform) -->
  <xsl:variable name="whitespace" select="'&#09;&#10;&#13; '" />
  <xsl:template name="string-rtrim">
    <xsl:param name="string" />
    <xsl:param name="trim" select="$whitespace" />
    <xsl:variable name="length" select="string-length($string)" />
    <xsl:if test="$length &gt; 0">
      <xsl:choose>
        <xsl:when test="contains($trim, substring($string, $length, 1))">
          <xsl:call-template name="string-rtrim">
            <xsl:with-param name="string" select="substring($string, 1, $length - 1)" />
            <xsl:with-param name="trim" select="$trim" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$string" /></xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:template name="string-ltrim">
    <xsl:param name="string" />
    <xsl:param name="trim" select="$whitespace" />
    <xsl:if test="string-length($string) &gt; 0">
      <xsl:choose>
        <xsl:when test="contains($trim, substring($string, 1, 1))">
          <xsl:call-template name="string-ltrim">
            <xsl:with-param name="string" select="substring($string, 2)" />
            <xsl:with-param name="trim" select="$trim" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$string" /></xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:template name="string-trim">
    <xsl:param name="string" />
    <xsl:param name="trim" select="$whitespace" />
    <xsl:call-template name="string-rtrim">
      <xsl:with-param name="string">
        <xsl:call-template name="string-ltrim">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="trim" select="$trim" />
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="trim" select="$trim" />
    </xsl:call-template>
  </xsl:template>

  <!-- Root -->
  <xsl:template match="/">
    <xsl:for-each select="page">
      <xsl:call-template name="page-content"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="pages" name="pages">
    <xsl:for-each select="pages/page">
      <xsl:call-template name="page-content"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Page content to Markdown -->
  <xsl:template match="page-content" name="page-content">
    <!-- Precompute attributes to avoid predicate tests in XPath -->
    <xsl:variable name="topicParent"><xsl:value-of select="topic/*[@name='parent']|topic/@parent"/></xsl:variable>
    <xsl:variable name="topicElementName"><xsl:value-of select="topic/*[@name='elementName']|topic/@elementName"/></xsl:variable>
    <xsl:variable name="topicMethod"><xsl:value-of select="topic/*[@name='method']|topic/@method"/></xsl:variable>
    <xsl:variable name="topicScope"><xsl:value-of select="topic/*[@name='scope']|topic/@scope"/></xsl:variable>
    <xsl:variable name="apiVal"><xsl:value-of select="*[@name='api']|@api"/></xsl:variable>

    <!-- Title / Topic -->
    <xsl:choose>
      <xsl:when test="@depth">
        <xsl:if test="topic">
          <xsl:text># </xsl:text><xsl:value-of select="topic" /><xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="name">
          <xsl:text># </xsl:text><xsl:value-of select="name" /><xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$topicParent != ''">
        <xsl:text># </xsl:text>
        <xsl:value-of select="concat($topicParent, ' ', $topicElementName)"/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="$topicMethod != ''">
        <xsl:text># </xsl:text>
        <xsl:value-of select="$topicMethod"/><xsl:text> </xsl:text>
        <xsl:if test="$topicScope != ''">
          <xsl:text>[</xsl:text><xsl:value-of select="$topicScope" /><xsl:text>] </xsl:text>
        </xsl:if>
        <xsl:value-of select="topic" />
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="topic">
          <xsl:text># </xsl:text><xsl:value-of select="topic" /><xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="name">
          <xsl:text># </xsl:text><xsl:value-of select="name" /><xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

    <!-- API language badge -->
    <xsl:if test="$apiVal != ''">
      <xsl:text>_</xsl:text>
      <xsl:choose>
        <xsl:when test="$apiVal='xb'">Xbasic</xsl:when>
        <xsl:when test="$apiVal='js'">JavaScript</xsl:when>
        <xsl:when test="$apiVal='py'">Python</xsl:when>
        <xsl:when test="$apiVal='cstemplate'">Client Side Template</xsl:when>
        <xsl:otherwise><xsl:value-of select="$apiVal" /></xsl:otherwise>
      </xsl:choose>
      <xsl:text>_&#10;&#10;</xsl:text>
    </xsl:if>

    <xsl:call-template name="callouts-before"/>

    <!-- Syntax / Prototype -->
    <xsl:if test="syntax">
      <xsl:text>### Syntax&#10;</xsl:text>
      <xsl:text>```&#10;</xsl:text>
      <xsl:value-of select="syntax" />
      <xsl:text>&#10;```&#10;&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="prototype">
      <xsl:text>### Syntax&#10;</xsl:text>
      <xsl:text>```&#10;</xsl:text>
      <xsl:value-of select="prototype" />
      <xsl:text>&#10;```&#10;&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="prototypes">
      <xsl:text>### Syntax&#10;</xsl:text>
      <xsl:for-each select="prototypes/prototype">
        <xsl:text>```&#10;</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>&#10;```&#10;</xsl:text>
      </xsl:for-each>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Arguments / Returns -->
    <xsl:if test="arguments">
      <xsl:text>### Arguments&#10;</xsl:text>
      <xsl:call-template name="arguments"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="returns">
      <xsl:text>### Returns&#10;</xsl:text>
      <xsl:call-template name="returns-template"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Description / Discussion -->
    <xsl:if test="description">
      <xsl:choose>
        <xsl:when test="description/@title">
          <xsl:text>### </xsl:text><xsl:value-of select="description/@title"/><xsl:text>&#10;&#10;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>### Description&#10;&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:for-each select="description">
        <xsl:call-template name="text-content"/>
      </xsl:for-each>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="discussion/@include">
        <xsl:value-of select="discussion/@include" disable-output-escaping="yes"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="content">
        <xsl:text>### Discussion&#10;&#10;</xsl:text>
        <xsl:value-of select="content" disable-output-escaping="yes"/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="discussion/@type='html'">
        <xsl:text>### Discussion&#10;&#10;</xsl:text>
        <xsl:value-of select="discussion" disable-output-escaping="yes"/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="discussion">
        <xsl:text>### Discussion&#10;&#10;</xsl:text>
        <xsl:for-each select="discussion">
          <xsl:call-template name="text-content"/>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
    </xsl:choose>

    <!-- Lists / Examples / Sections -->
    <xsl:if test="list"><xsl:call-template name="list"/></xsl:if>
    <xsl:if test="example">
      <xsl:call-template name="example-template">
        <xsl:with-param name="default_title">Example</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="sections"><xsl:call-template name="section-content"/></xsl:if>

    <!-- Groups -->
    <xsl:if test="groups">
      <xsl:for-each select="groups/group">
        <xsl:if test="title">
          <xsl:text>## </xsl:text><xsl:value-of select="title"/><xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="section-content"/>
      </xsl:for-each>
    </xsl:if>

    <!-- Properties -->
    <xsl:if test="properties">
      <xsl:text>## Properties&#10;</xsl:text>
      <xsl:for-each select="properties/property">
        <xsl:text>- </xsl:text><xsl:value-of select="name"/>
        <xsl:if test="types/type or type">
          <xsl:text> (`</xsl:text>
          <xsl:choose>
            <xsl:when test="types/type">
              <xsl:for-each select="types/type">
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()"><xsl:text>|</xsl:text></xsl:if>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="type"><xsl:value-of select="."/></xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>`) </xsl:text>
        </xsl:if>
        <xsl:if test="@readonly"><xsl:text>[readonly] </xsl:text></xsl:if>
        <xsl:if test="@writeonly"><xsl:text>[writeonly] </xsl:text></xsl:if>
        <xsl:if test="@optional"><xsl:text>[optional] </xsl:text></xsl:if>
        <xsl:text>&#10;</xsl:text>
        <xsl:for-each select="description">
          <xsl:text>  </xsl:text>
          <xsl:call-template name="text-content"/>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Methods -->
    <xsl:if test="methods">
      <xsl:text>## Methods&#10;</xsl:text>
      <xsl:if test="methods/@nomethods">
        <xsl:text>_</xsl:text><xsl:value-of select="methods"/><xsl:text>_&#10;</xsl:text>
      </xsl:if>
      <xsl:for-each select="methods/method">
        <xsl:if test="name">
          <xsl:text>### </xsl:text><xsl:value-of select="name"/><xsl:text>&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="syntax">
          <xsl:text>```&#10;</xsl:text>
          <xsl:value-of select="syntax"/>
          <xsl:text>&#10;```&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="callouts-before"/>
        <xsl:if test="arguments"><xsl:text>#### Arguments&#10;</xsl:text><xsl:call-template name="arguments"/></xsl:if>
        <xsl:if test="returns"><xsl:text>#### Returns&#10;</xsl:text><xsl:call-template name="returns-template"/></xsl:if>
        <xsl:for-each select="description"><xsl:call-template name="text-content"/></xsl:for-each>
        <xsl:if test="example">
          <xsl:call-template name="example-template">
            <xsl:with-param name="default_title">Example</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="ref">
          <xsl:text>See: </xsl:text>
          <xsl:choose>
            <xsl:when test="@href">
              <xsl:text>[</xsl:text><xsl:value-of select="ref"/><xsl:text>](</xsl:text><xsl:value-of select="@href"/><xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="ref"/></xsl:otherwise>
          </xsl:choose>
          <xsl:text>&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="callouts-after"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="methods/methodref">
        <xsl:text>- </xsl:text>
        <xsl:choose>
          <xsl:when test="ref/@href">
            <xsl:text>[</xsl:text><xsl:value-of select="name"/><xsl:text>](</xsl:text><xsl:value-of select="ref/@href"/><xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:when test="ref/@link">
            <xsl:text>[</xsl:text><xsl:value-of select="name"/><xsl:text>](</xsl:text><xsl:value-of select="concat('((A5_BASE_PATH))index?search=', ref/@link)"/><xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:when test="ref">
            <xsl:text>[</xsl:text><xsl:value-of select="name"/><xsl:text>](</xsl:text><xsl:value-of select="concat('((A5_BASE_PATH))index?search=', ref)"/><xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Videos / Limitations / See Also / Next / Attribution -->
    <xsl:if test="videos"><xsl:call-template name="videos"/></xsl:if>
    <xsl:if test="limitations">
      <xsl:text>### Limitations&#10;&#10;</xsl:text>
      <xsl:value-of select="limitations"/>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="see"><xsl:call-template name="seeAlso"/></xsl:if>
    <xsl:if test="next"><xsl:call-template name="next"/></xsl:if>
    <xsl:if test="attribution">
      <xsl:for-each select="attribution"><xsl:call-template name="attribution"/></xsl:for-each>
    </xsl:if>

    <xsl:if test="pages"><xsl:call-template name="pages"/></xsl:if>
  </xsl:template>

  <!-- Lists (custom list structure) -->
  <xsl:template match="list" name="list">
    <xsl:choose>
      <xsl:when test="list/@bullet">
        <xsl:for-each select="list/item">
          <xsl:text>- </xsl:text>
          <xsl:choose>
            <xsl:when test="name/@href">
              <xsl:text>[</xsl:text><xsl:value-of select="name"/><xsl:text>](</xsl:text><xsl:value-of select="name/@href"/><xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
          </xsl:choose>
          <xsl:if test="description">
            <xsl:text> - </xsl:text>
            <xsl:for-each select="description"><xsl:call-template name="text-content"/></xsl:for-each>
          </xsl:if>
          <xsl:text>&#10;</xsl:text>
          <xsl:if test="list"><xsl:call-template name="list"/></xsl:if>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- Definition-like list rendered as bullets -->
        <xsl:for-each select="list/item">
          <xsl:choose>
            <xsl:when test="name-title">
              <xsl:text>**</xsl:text><xsl:value-of select="name-title"/><xsl:text>** — </xsl:text>
              <xsl:choose>
                <xsl:when test="description-title"><xsl:value-of select="description-title"/></xsl:when>
                <xsl:otherwise><xsl:text>Description</xsl:text></xsl:otherwise>
              </xsl:choose>
              <xsl:text>&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>- </xsl:text>
              <xsl:choose>
                <xsl:when test="name/@href">
                  <xsl:text>[</xsl:text><xsl:value-of select="name"/><xsl:text>](</xsl:text><xsl:value-of select="name/@href"/><xsl:text>)</xsl:text>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
              </xsl:choose>
              <xsl:text>: </xsl:text>
              <xsl:for-each select="description"><xsl:call-template name="text-content"/></xsl:for-each>
              <xsl:text>&#10;</xsl:text>
              <xsl:if test="list"><xsl:call-template name="list"/></xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Section/Step/Case containers -->
  <xsl:template match="sectionstep-content" name="sectionstep-content">
    <xsl:if test="title">
      <xsl:text>### </xsl:text><xsl:value-of select="normalize-space(title)"/><xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="content">
        <xsl:value-of select="content" disable-output-escaping="yes"/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="discussion">
        <xsl:for-each select="discussion"><xsl:call-template name="text-content"/></xsl:for-each>
      </xsl:when>
      <xsl:when test="description">
        <xsl:for-each select="description"><xsl:call-template name="text-content"/></xsl:for-each>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="list"><xsl:call-template name="list"/></xsl:if>
    <xsl:if test="pages"><xsl:call-template name="pages"/></xsl:if>
    <xsl:if test="example"><xsl:call-template name="example-template"/></xsl:if>
    <xsl:if test="steps"><xsl:call-template name="step-content"/></xsl:if>
    <xsl:if test="cases"><xsl:call-template name="case-content"/></xsl:if>
    <xsl:call-template name="callouts-before"/>
    <xsl:call-template name="callouts-after"/>
  </xsl:template>

  <xsl:template match="step-content" name="step-content">
    <xsl:for-each select="steps/step">
      <xsl:text>1. </xsl:text>
      <xsl:call-template name="sectionstep-content"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="case-content" name="case-content">
    <xsl:for-each select="cases/case">
      <xsl:text>- </xsl:text>
      <xsl:call-template name="sectionstep-content"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="section-content" name="section-content">
    <xsl:for-each select="sections/section">
      <xsl:call-template name="sectionstep-content"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Arguments / Returns as bullets -->
  <xsl:template match="arguments" name="arguments">
    <xsl:for-each select="arguments/argument">
      <xsl:call-template name="inputs-outputs"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="inputs-outputs">
    <xsl:text>- </xsl:text>
    <xsl:value-of select="name"/>
    <xsl:if test="types/type or type">
      <xsl:text> (`</xsl:text>
      <xsl:choose>
        <xsl:when test="types/type">
          <xsl:for-each select="types/type">
            <xsl:value-of select="."/>
            <xsl:if test="position() != last()"><xsl:text>|</xsl:text></xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="type"><xsl:value-of select="."/></xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>`) </xsl:text>
    </xsl:if>
    <xsl:if test="@readonly"><xsl:text>[readonly] </xsl:text></xsl:if>
    <xsl:if test="@writeonly"><xsl:text>[writeonly] </xsl:text></xsl:if>
    <xsl:if test="@optional"><xsl:text>[optional] </xsl:text></xsl:if>
    <xsl:text>&#10;</xsl:text>
    <xsl:choose>
      <xsl:when test="content">
        <xsl:text>  </xsl:text><xsl:value-of select="content" disable-output-escaping="yes"/><xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="description">
        <xsl:for-each select="description"><xsl:text>  </xsl:text><xsl:call-template name="text-content"/></xsl:for-each>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="list"><xsl:call-template name="list"/></xsl:if>
  </xsl:template>

  <xsl:template name="returns-template">
    <xsl:choose>
      <xsl:when test="returns/return">
        <xsl:for-each select="returns/return"><xsl:call-template name="inputs-outputs"/></xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
        <xsl:text>&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Example blocks to fenced code -->
  <xsl:template name="example-template">
    <xsl:param name="default_title" />
    <xsl:choose>
      <xsl:when test="example/@caption">
        <xsl:text>_</xsl:text><xsl:value-of select="example/@caption"/><xsl:text>_&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="$default_title = 'Example'"><xsl:text>### Example&#10;</xsl:text></xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="example/@include">
        <xsl:text>```&#10;</xsl:text>
        <xsl:value-of select="example/@include" disable-output-escaping="yes"/>
        <xsl:text>&#10;```&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="example/@code">
        <xsl:text>```</xsl:text><xsl:value-of select="example/@code"/><xsl:text>&#10;</xsl:text>
        <xsl:call-template name="string-trim"><xsl:with-param name="string" select="example"/></xsl:call-template>
        <xsl:text>&#10;```&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>```&#10;</xsl:text>
        <xsl:call-template name="string-trim"><xsl:with-param name="string" select="example"/></xsl:call-template>
        <xsl:text>&#10;```&#10;&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Text-content to Markdown -->
  <xsl:template match="text-content" name="text-content">
    <xsl:choose>
      <xsl:when test="./@include">
        <xsl:value-of select="./@include" disable-output-escaping="yes"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="p or ul or ol or table or list or strike or li">
        <xsl:call-template name="text-html"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="." />
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="text-html">
    <xsl:for-each select="*">
      <xsl:choose>
        <xsl:when test="local-name() = 'p'">
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text>&#10;&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'list'">
          <xsl:call-template name="list"/>
        </xsl:when>
        <xsl:when test="local-name() = 'ul'">
          <xsl:for-each select="li">
            <xsl:text>- </xsl:text><xsl:value-of select="."/>
            <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
          <xsl:text>&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'ol'">
          <xsl:for-each select="li">
            <xsl:text>1. </xsl:text><xsl:value-of select="."/>
            <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
          <xsl:text>&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'strike'">
          <xsl:text>~~</xsl:text><xsl:value-of select="."/><xsl:text>~~&#10;&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'table'">
          <!-- Simple Markdown table rendering (no rowspan/colspan support) -->
          <xsl:variable name="hasHeader" select="boolean(tr[1]/th)"/>
          <xsl:if test="$hasHeader">
            <xsl:for-each select="tr[1]/th">
              <xsl:text>| </xsl:text><xsl:value-of select="normalize-space(.)"/>
              <xsl:text> </xsl:text>
            </xsl:for-each>
            <xsl:text>|&#10;</xsl:text>
            <xsl:for-each select="tr[1]/th"><xsl:text>| --- </xsl:text></xsl:for-each>
            <xsl:text>|&#10;</xsl:text>
          </xsl:if>
          <xsl:for-each select="tr">
            <xsl:if test="not($hasHeader) or position() &gt; 1">
              <xsl:for-each select="td">
                <xsl:text>| </xsl:text><xsl:value-of select="normalize-space(.)"/>
                <xsl:text> </xsl:text>
              </xsl:for-each>
              <xsl:text>|&#10;</xsl:text>
            </xsl:if>
          </xsl:for-each>
          <xsl:text>&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'li'">
          <xsl:text>- </xsl:text><xsl:value-of select="."/>
          <xsl:text>&#10;</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- Callouts to blockquotes -->
  <xsl:template name="callouts-before">
    <xsl:if test="warning">
      <xsl:choose>
        <xsl:when test="warning/p">
          <xsl:for-each select="warning">
            <xsl:text>&gt; Warning: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Warning: </xsl:text><xsl:value-of select="warning"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="deprecated">
      <xsl:choose>
        <xsl:when test="deprecated/p">
          <xsl:for-each select="deprecated">
            <xsl:text>&gt; Deprecated: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Deprecated: </xsl:text><xsl:value-of select="deprecated"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="obsolete">
      <xsl:choose>
        <xsl:when test="obsolete/p">
          <xsl:for-each select="obsolete">
            <xsl:text>&gt; Obsolete: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Obsolete: </xsl:text><xsl:value-of select="obsolete"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template name="callouts-after">
    <xsl:if test="note">
      <xsl:choose>
        <xsl:when test="note/p">
          <xsl:for-each select="note">
            <xsl:text>&gt; Note: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Note: </xsl:text><xsl:value-of select="note"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="important">
      <xsl:choose>
        <xsl:when test="important/p">
          <xsl:for-each select="important">
            <xsl:text>&gt; Important: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Important: </xsl:text><xsl:value-of select="important"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="tip">
      <xsl:choose>
        <xsl:when test="tip/p">
          <xsl:for-each select="tip">
            <xsl:text>&gt; Tip: </xsl:text><xsl:call-template name="text-content"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&gt; Tip: </xsl:text><xsl:value-of select="tip"/><xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="postscript">
      <xsl:choose>
        <xsl:when test="postscript/p">
          <xsl:for-each select="postscript"><xsl:call-template name="text-content"/></xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="postscript"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Next / See Also / Videos / Attribution -->
  <xsl:template match="next" name="next">
    <xsl:for-each select="next/link">
      <xsl:text>Next: </xsl:text>
      <xsl:choose>
        <xsl:when test="@href and @target">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="@href"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@href">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="@href"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@link">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="concat('((A5_BASE_PATH))index?search=', @link)"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
      <xsl:text> &#187;&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="seeAlso" name="seeAlso">
    <xsl:text>### See Also&#10;</xsl:text>
    <xsl:for-each select="see/ref">
      <xsl:text>- </xsl:text>
      <xsl:choose>
        <xsl:when test="@href and @target">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="@href"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@href">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="@href"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@link">
          <xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>](</xsl:text><xsl:value-of select="concat('((A5_BASE_PATH))index?search=', @link)"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="videos" name="videos">
    <xsl:if test="videos/title"><xsl:text>### </xsl:text><xsl:value-of select="videos/title"/><xsl:text>&#10;</xsl:text></xsl:if>
    <xsl:if test="videos/description">
      <xsl:for-each select="videos/description"><xsl:call-template name="text-content"/></xsl:for-each>
    </xsl:if>
    <xsl:for-each select="videos/video">
      <xsl:text>- </xsl:text>
      <xsl:choose>
        <xsl:when test="@local or @embedded">
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>[</xsl:text>
          <xsl:choose>
            <xsl:when test="name"><xsl:value-of select="name"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
          </xsl:choose>
          <xsl:text>](</xsl:text><xsl:value-of select="link | ."/><xsl:text>)</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:if test="videos/resources">
      <xsl:for-each select="videos/resources/resource">
        <xsl:text>- </xsl:text>
        <xsl:text>[</xsl:text>
        <xsl:choose>
          <xsl:when test="name"><xsl:value-of select="name"/></xsl:when>
          <xsl:otherwise>Download Component</xsl:otherwise>
        </xsl:choose>
        <xsl:text>](</xsl:text><xsl:value-of select="link | ."/><xsl:text>)&#10;</xsl:text>
      </xsl:for-each>
    </xsl:if>
    <xsl:if test="videos/date"><xsl:text>_</xsl:text><xsl:value-of select="videos/date"/><xsl:text>_&#10;</xsl:text></xsl:if>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="attribution" name="attribution">
    <xsl:text>---&#10;</xsl:text>
    <xsl:if test="title"><xsl:text>**Title:** </xsl:text><xsl:value-of select="title"/><xsl:text>&#10;</xsl:text></xsl:if>
    <xsl:if test="author"><xsl:text>**Author:** </xsl:text><xsl:value-of select="author"/><xsl:text>&#10;</xsl:text></xsl:if>
    <xsl:if test="source"><xsl:text>**Source:** </xsl:text><xsl:value-of select="source"/><xsl:text>&#10;</xsl:text></xsl:if>
    <xsl:if test="license"><xsl:text>**License:** </xsl:text><xsl:value-of select="license"/><xsl:text>&#10;</xsl:text></xsl:if>
    <xsl:text>---&#10;&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
