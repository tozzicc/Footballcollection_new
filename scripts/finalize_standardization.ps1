
# finalize_standardization.ps1
# A safer version of the standardization script.

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
    # Skip one-off pages we already manually fixed if needed, but script should be idempotent
    Write-Host "Processing: $($file.FullName)"
    $content = Get-Content -Path $file.FullName -Raw -Encoding utf8
    
    # 1. Clean Up Old Navigation Links (SAFELY - only text replace)
    # We look for the common navigation anchors
    $content = [regex]::Replace($content, '(?i)<a[^>]*>TEAMS</a>', "")
    $content = [regex]::Replace($content, '(?i)<a[^>]*>COLLECTION</a>', "")
    $content = [regex]::Replace($content, '(?i)<a[^>]*>S&Atilde;O\s+PAULO</a>', "")
    $content = [regex]::Replace($content, '(?i)&nbsp;', " ") # Simplify nbsp
    
    # 2. Ensure CSS link
    if ($content -notmatch 'modern-legacy.css') {
        $content = $content -replace '</title>', "</title>`n    <link rel=`"stylesheet`" href=`"/modern-legacy.css`">"
        $content = $content -replace '</HEAD>', "<link rel=`"stylesheet`" href=`"/modern-legacy.css`">`n</HEAD>"
    }

    # 3. Handle Body Classes
    if ($content -match '<body[^>]*>') {
        if ($content -notmatch 'legacy-page') {
             $content = $content -replace '(<body)', '$1 class="legacy-page align-left"'
             # Cleanup if double class
             $content = $content -replace 'class="legacy-page align-left"\s+class="', 'class="legacy-page align-left '
        }
    }

    # 4. Remove previous standardization footer/script to avoid double-up
    $content = $content -replace '(?s)<footer>.*?</footer>', ""
    $content = $content -replace '(?s)<script>.*?window.parent.postMessage.*?NAVIGATE.*?</script>', ""

    # 5. Insert New Footer and Script before </body>
    if ($content -match '</body>') {
        $content = $content -replace '</body>', "$footerHtml`n$bridgeScript`n</body>"
    }

    # 6. Sanitize Decade Titles (Remove 's')
    $content = [regex]::Replace($content, '(<div class="decade-title">)(\d+)s(</div>)', '$1$2$3')
    $content = [regex]::Replace($content, '(<font[^>]*>)(\d+)s(</font>)', '$1$2$3')

    # Save
    $content | Set-Content -Path $file.FullName -Encoding utf8
}

Write-Host "Standardization complete!"
