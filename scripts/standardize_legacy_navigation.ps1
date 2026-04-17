
# standardize_legacy_navigation.ps1
# Standardizes footer navigation and scripts for both .htm and .html legacy pages.

$baseDir = "c:\Projetos\Football Collection\public\paises"

$files = Get-ChildItem -Path $baseDir -Recurse -Include *.htm, *.html

$footerHtml = @"
    <footer>
        <a href="javascript:history.back()" class="back-link">VOLTAR / BACK</a>
    </footer>
"@

$bridgeScript = @"
    <script>
      document.addEventListener('click', (e) => {
        const link = e.target.closest('a');
        if (link && link.href && link.href.startsWith(window.location.origin)) {
          if (link.href.includes('javascript') || link.href.includes('#')) return;
          const path = link.href.replace(window.location.origin, '');
          window.parent.postMessage({ type: 'NAVIGATE', path }, '*');
        }
      });
      const sh = () => { window.parent.postMessage({ type: 'RESIZE', height: document.documentElement.scrollHeight }, '*'); };
      window.addEventListener('load', sh); window.addEventListener('resize', sh); setTimeout(sh, 500);
      setInterval(sh, 2000);
    </script>
"@

foreach ($file in $files) {
    Write-Host "Standardizing navigation: $($file.FullName)..."
    $content = Get-Content -Path $file.FullName -Raw -Encoding utf8
    
    # 1. Ensure modern-legacy.css link
    if ($content -notmatch 'href="/modern-legacy.css"') {
        $content = $content -replace '</head>', "    <link rel=`"stylesheet`" href=`"/modern-legacy.css`">`n</head>"
    }
    
    # 2. Add classes to body
    if ($content -notmatch 'body class="[^"]*legacy-page') {
        $content = $content -replace '(<body\s+class=")([^"]*)(")', '$1$2 legacy-page align-left$3'
        # Fallback
        if ($content -match '<body[^>]*>') {
            $content = $content -replace '(<body[^>]*>)', '<body class="legacy-page align-left" $1'
            $content = $content -replace '<body class="legacy-page align-left" <body', '<body class="legacy-page align-left"'
        }
    }

    # 3. Remove Legacy Navigation Links (TEAMS, COLLECTION, etc.)
    # This regex looks for blocks containing TEAMS and COLLECTION links with multiple spaces
    $oldNavRegex = '(?s)<div[^>]*>.*?<a[^>]*>.*?TEAMS.*?</a>.*?</div>'
    $content = $content -replace $oldNavRegex, ""
    
    # More specific search for the block seen in saopaulo/2013.html
    $specNav1 = '(?s)<div align="center">\s*<div align="center"><i><b><font.*?COLLECTION.*?</font></b></i>\s*</div>\s*</div>'
    $content = $content -replace $specNav1, ""
    
    # 4. Remove existing FOOTER or BACK button to avoid duplication
    $content = $content -replace '(?s)<footer>.*?</footer>', ""
    $content = $content -replace '(?s)<a[^>]*back-link[^>]*>.*?</a>', ""
    
    # 5. Insert New Footer and Script
    if ($content -notmatch '<footer>') {
        $content = $content -replace '</body>', "$footerHtml`n$bridgeScript`n</body>"
    }

    # 6. Sanitize Decade Titles (Remove 's')
    $content = [regex]::Replace($content, '(<div class="decade-title">)(\d+)s(</div>)', '$1$2$3')
    $content = [regex]::Replace($content, '(<font[^>]*>)(\d+)s(</font>)', '$1$2$3')

    # Save back
    $content | Set-Content -Path $file.FullName -Encoding utf8
}

Write-Host "Navigation standardization complete!"
