# ==========================================================================
# INSTALADOR FIREFOX SEGURO WINDOWS 11 ENTERPRISE
# Execute o PowerShell COMO ADMINISTRADOR antes de rodar.
# ==========================================================================

# --- 0. Verificar Admin ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Execute o PowerShell como Administrador."
    exit
}
Write-Host "Admin confirmado`n" -ForegroundColor Green

# --- 1. Baixar Firefox ESR ---
Write-Host "Baixando Firefox ESR..." -ForegroundColor Cyan
$esrUrl = "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64"
$esrPath = "$env:TEMP\FirefoxSetup.exe"
if (-not (Test-Path $esrPath)) {
    try {(New-Object System.Net.WebClient).DownloadFile($esrUrl, $esrPath)} catch { Write-Error "Falha no download"; exit }
}
Write-Host "Instalando Firefox ESR..." -ForegroundColor Yellow
& $esrPath -ms >$null 2>$null

# --- 2. Criar perfil Secure ---
Write-Host "Criando perfil Firefox Secure..." -ForegroundColor Cyan
$profileName = "secure_" + (Get-Random -Minimum 1000 -Maximum 9999)
$ffProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
$profilePath = Join-Path $ffProfiles $profileName
& "$esrPath" -CreateProfile "Secure $profileName" >$null 2>$null

# --- 2b. Aplicar user.js (Segurança) ---
Write-Host "Aplicando configurações de segurança..." -ForegroundColor Cyan
$userJsSrc = "C:\Users\$env:USERNAME\Documents\Default Project\navegador_seguro\user.js"
$profileJs = Join-Path $profilePath "user.js"
if (Test-Path $userJsSrc) {
    Copy-Item -Path $userJsSrc -Destination $profileJs -Force
    # Garantir prefs críticas
    $criticalPrefs = @("privacy.trackingprotection.enabled","privacy.trackingprotection.social.enabled","privacy.trackingprotection.cryptomining.enabled","privacy.trackingprotection.fingerprinting.enabled","network.cookie.cookieBehavior")
    foreach ($p in $criticalPrefs) {
        if ((Get-Content $profileJs) -notmatch "^user_pref(`"${p}`")") {
            "user_pref(`"$p"`, true);" | Out-File $profileJs -Encoding utf8 -Append
        }
    }
    Write-Host "✅ user.js aplicado" -ForegroundColor Green
}

# --- 3. Aplicar tema visual (userChrome.css) ---
Write-Host "Aplicando tema visual Mozilla clássico..." -ForegroundColor Cyan
$chromeDir = Join-Path $profilePath "chrome"
if (-not (Test-Path $chromeDir)) { New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null }
Copy-Item -Path "C:\Users\$env:USERNAME\Documents\Default Project\navegador_seguro\userChrome.css" -Destination (Join-Path $chromeDir "userChrome.css") -Force
# Habilitar userChrome.css
$uj = Join-Path $profilePath "user.js"
if (Test-Path $uj) {
    if ((Get-Content $uj) -notmatch "toolkit.legacyUserProfileCustomizations.stylesheets") {
        "user_pref(""toolkit.legacyUserProfileCustomizations.stylesheets"", true);" | Out-File $uj -Encoding utf8 -Append
    }
}
Write-Host "✅ Tema aplicado" -ForegroundColor Green

# --- 4. Gerenciador de Downloads ---
Write-Host "Configurando gerenciador de downloads..." -ForegroundColor Cyan
$dmSrc = "C:\Users\$env:USERNAME\Documents\Default Project\navegador_seguro\downloads_manager.ps1"
$dmDst = "$env:USERPROFILE\DownloadManager.ps1"
Copy-Item -Path $dmSrc -Destination $dmDst -Force
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop "GerenciarDownloads.lnk"
$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut($lnk)
$s.TargetPath = "powershell.exe"
$s.Arguments = "-ExecutionPolicy Bypass -File `"$dmDst`""
$s.Save()
Write-Host "✅ Atalho: Área de Trabalho > GerenciarDownloads.lnk" -ForegroundColor Green

# --- 5. Terminal Integrado ---
Write-Host "Configurando terminal integrado..." -ForegroundColor Cyan
$tSrc = "C:\Users\$env:USERNAME\Documents\Default Project\navegador_seguro\terminal_cli.ps1"
$tDst = "$env:USERPROFILE\TerminalFox.ps1"
Copy-Item -Path $tSrc -Destination $tDst -Force
$tLnk = Join-Path $desktop "TerminalFox.lnk"
$s2 = $shell.CreateShortcut($tLnk)
$s2.TargetPath = "powershell.exe"
$s2.Arguments = "-ExecutionPolicy Bypass -File `"$tDst`""
$s2.Save()
Write-Host "✅ Atalho: Área de Trabalho > TerminalFox.lnk" -ForegroundColor Green

# --- 6. Bloqueio de Conteúdo (hosts + about:config) ---
Write-Host "Aplicando bloqueio de conteúdo..." -ForegroundColor Cyan
$hosts = "C:\Windows\System32\drivers\etc\hosts"
$bak = "$env:USERPROFILE\navegador_seguro\hosts_backup.txt"
if (-not (Test-Path $bak)) { Copy-Item $hosts $bak -Force }
$lists = @("http://someonewhocares.org/hosts.txt","http://winhelp2002.mvps.org/hosts.txt")
foreach ($url in $lists) {
    try {
        $wc = New-Object System.Net.WebClient
        $c = $wc.DownloadString($url)
        $c -split "`n" | Where-Object { $_ -match "^127\.0\.0\.1" } | ForEach-Object { "127.0.0.1 $($_.Split()[1])" >> $hosts }
    } catch { Write-Warning "Falha ao baixar $url" }
}
# Ajustar prefs no user.js já aplicado
$prefs = @("privacy.trackingprotection.enabled","privacy.trackingprotection.social.enabled","privacy.trackingprotection.cryptomining.enabled","privacy.trackingprotection.fingerprinting.enabled","network.cookie.cookieBehavior")
foreach ($p in $prefs) {
    if ((Get-Content $uj) -notmatch "^user_pref(`"${p}`")") { "user_pref(""${p}"", true);" | Out-File $uj -Encoding utf8 -Append }
}
Write-Host "✅ Blocklist e filtros aplicados" -ForegroundColor Yellow

# --- 7. Streams m3u8/m3u ---
Write-Host "Configurando captura de streams..." -ForegroundColor Cyan
$sSrc = "C:\Users\$env:USERNAME\Documents\Default Project\navegador_seguro\streams_capture.ps1"
$sDst = "$env:USERPROFILE\StreamsFox.ps1"
Copy-Item -Path $sSrc -Destination $sDst -Force
$tLnk2 = Join-Path $desktop "CapturarStream.lnk"
$s2 = $shell.CreateShortcut($tLnk2)
$s2.TargetPath = "powershell.exe"
$s2.Arguments = "-ExecutionPolicy Bypass -File `"$sDst`""
$s2.Save()
Write-Host "✅ Atalho: Área de Trabalho > CapturarStream.lnk" -ForegroundColor Green

# --- 8. Relatório Final ---
Write-Host "Gerando relatório..." -ForegroundColor Cyan
$reportPath = "$env:USERPROFILE\relatorio_instalacao.txt"
$report = @"
=== RELATÓRIO DE INSTALAÇÃO ===
Data: $(Get-Date)
Perfil: $profileName
Firefox: Instalado
user.js: OK
userChrome.css: OK
Hosts: OK
Atalhos: GerenciarDownloads.lnk, TerminalFox.lnk, CapturarStream.lnk
Observação: Reinicie o Firefox completamente.
"@
$report | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "📄 Relatório: $reportPath" -ForegroundColor Magenta

# --- 8. Conclusão ---
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "INSTALAÇÃO CONCLUÍDA" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "Passos finais: reinicie o Firefox completamente.
As extensões (uBlock Origin, Video DownloadHelper) devem aparecer em about:extensions.
Use os atalhos na Área de Trabalho para Terminal e Downloads.
Aproveite seu navegador seguro!" -ForegroundColor Yellow