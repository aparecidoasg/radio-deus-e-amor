<# ============================================================================
  NAVEGADOR SEGURO - Filtro de Conteúdo e Blocklists
  content_filters.ps1 - Bloqueia anúncios, rastreamento, conteúdo adulto/violento
  e injeta hosts file para bloqueio de nível de sistema.
  ============================================================================ #>

#region Variáveis Globais
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$backupPath = "$env:USERPROFILE\navegador_seguro\hosts_backup.txt"
$blockLists = @(
    "http://someonewhocares.org/hosts.txt",
    "http://winhelp2002.mvps.org/hosts.txt",
    "https://hosts-file.net/gr.html",
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
)
#endregion

#region Funções de Blocklist

function Download-Blocklist {
    param([string]$url)
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Timeout = 30000
        $content = $webClient.DownloadString($url)
        return $content
    } catch {
        Write-Warning "Não foi possível baixar blocklist: $url - $_"
        return $null
    }
}

function Parse-Hosts-Content {
    param([string]$content)
    $blockedSites = @()
    $lines = $content -split "`n" | ForEach-Object { $_ -split "`r" | Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^$' } }
    foreach ($line in $lines) {
        $parts = $line -split "\s+", 2
        if ($parts.Count -ge 2 -and $parts[0] -eq "127.0.0.1") {
            $site = $parts[1].Trim()
            if ($site) { $blockedSites += $site }
        }
    }
    return $blockedSites
}

function Get-All-Blocked-Sites {
    $allSites = @()
    foreach ($listUrl in $blockLists) {
        $content = Download-Blocklist -url $listUrl
        if ($content) {
            $sites = Parse-Hosts-Content -content $content
            $allSites += $sites
        }
    }
    # Remover duplicatas
    return $allSites | Get-Unique
}

#endregion

#region Bloqueio no Hosts File

function Install-Hosts-Blocklist {
    Write-Host "Atualizando bloqueio no hostsfile do Windows..." -ForegroundColor Cyan
    
    # Fazer backup do hosts atual
    if (-not (Test-Path $backupPath)) {
        try {
            $currentHosts = Get-Content $hostsPath | Out-File $backupPath -Encoding UTF8
            Write-Host "Backup criado em: $backupPath" -ForegroundColor Green
        } catch {
            Write-Error "Não foi possível fazer backup do hosts file."
        }
    }

    # Baixar e juntar todas as blocklists
    $allSites = Get-All-Blocked-Sites
    Write-Host "Total de sites bloqueados encontrados: $($allSites.Count)" -ForegroundColor Yellow

    # Construir novo conteúdo do hosts file
    $currentHosts = Get-Content $hostsPath
    $newHostsLines = @()

    # Manter comentários e linhas existentes que não sejam de blocklist
    foreach ($line in $currentHosts) {
        $lowerLine = $line.ToLower()
        # Manter linhas que sejam comentários (começam com #) ou sejam IPs/VÁLIDOS
        if ($lowerLine.StartsWith("#") -or ($line -match "^\s*192\.168\." -or $line -match "^\s*10\." -or $line -match "^\s*172\.1[6-9]\.")) {
            $newHostsLines += $line
        }
    }

    # Adicionar novas blocklists (127.0.0.1 + site)
    foreach ($site in $allSites) {
        # Evitar adicionar se já existir no hosts atual
        $exists = $currentHosts | Where-Object { $_ -match [regex]::Escape($site) }
        if (-not $exists) {
            $newHostsLines += "127.0.0.1 $site"
        }
    }

    # Escrever novo hosts file (REQUER ADMINISTRADOR)
    try {
        $newHostsLines | Out-File -FilePath $hostsPath -Encoding UTF8 -Force
        Write-Host "✅ Hosts file atualizado com sucesso!" -ForegroundColor Green
        Write-Host "   Novos blocos: $($allSites.Count)" -ForegroundColor Yellow
        Write-Host "   Nota: Reinicie o computador para o efeito total." -ForegroundColor DimGray
    } catch {
        Write-Error "❌ Erro ao escrever o hosts file (pode precisar de Admin): $_"
    }
}

#endregion

#region Bloqueio por about:config (Sem precisar de Admin)

function Apply-Content-Filters-Config {
    Write-Host "Aplicando filtros via about:config (não requer Admin)..." -ForegroundColor Cyan
    
    # Estas configurações são aplicadas no user.js ou diretamente via pref()
    # Aqui criamos um script para ser usado no about:config ou no user.js
    
    $filterConfigs = @"
    // Content Filter Preferences
    // Bloqueio de rastreamento avançado
    user_pref("privacy.trackingprotection.enabled", true);
    user_pref("privacy.trackingprotection.social.enabled", true);
    user_pref("privacy.trackingprotection.cryptomining.enabled", true);
    user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
    
    // Nível de proteção estrito
    user_pref("privacy.trackingprotection.security.level", 2); // 0=Standard, 1=Strict, 2=Strictest
    
    // Impedir scripts de minerar criptomoedas no minerador de conteúdo
    user_pref("privacy.miner.enabled", false);
    
    // Desabilitar carga remota de fontes de anúncios
    user_pref("gfx.font_rendering.fontconfig.custom", true);
    user_pref("webgl.disabled", true); // Desabilitar WebGL (pode ser usado para fingerprinting)
    
    // Bloqueio de notificações
    user_pref("dom.webnotifications.enabled", false);
    
    // Impedir auto-play de áudio/vídeo
    user_pref("media.autoplay.enabled", false);
    user_pref("media.autoplay.block-event.enabled", true);
    user_pref("media.autoplay.block-user-gesture-required", false);
    
    // Impedir rastreamento cross-site
    user_pref("network.cookie.cookieBehavior", 1);  // Apenas do servidor
    user_pref("network.cookie.lifetimePolicy", 2);   // Session only
    
    // Desabilitar telemetry de conteúdo
    user_pref("toolkit.telemetry.enabled", false);
    user_pref("toolkit.telemetry.unified", false);
    
    // Proteção contra mineração de CPU
    user_pref("dom.miner.enabled", false);
"@
    
    # Escrever no user.js ou informar ao usuário
    $profileDir = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -match "secure" } | Select-Object -First 1
    if ($profileDir) {
        $userJsPath = Join-Path $profileDir "user.js"
        # Se o user.js já existir, adicionar apenas as linhas que não existem
        if (Test-Path $userJsPath) {
            Write-Host "user.js já existe. Novas configurações serão adicionadas no final." -ForegroundColor Yellow
        }
        # Append das configurações
        $filterConfigs | Out-File -FilePath $userJsPath -Encoding UTF8 -Append
        Write-Host "Configurações de filtro adicionadas a user.js." -ForegroundColor Green
    } else {
        Write-Host "Perfil Firefox Secure não encontrado para aplicar filtros." -ForegroundColor Red
    }
}

#endregion

#region Interface

# Main menu
Write-Host "=== BLOQUEADOR DE CONTEÚDO - NAVEGADOR SEGURO ===" -ForegroundColor Magenta
Write-Host "1. Atualizar bloqueio no hosts file (requer Admin)" -ForegroundColor White
Write-Host "2. Aplicar filtros via about:config (usuário)" -ForegroundColor White
Write-Host "3. Mostrar estatísticas" -ForegroundColor White
Write-Host "4. Restaurar backup do hosts file" -ForegroundColor White
Write-Host "5. Sair" -ForegroundColor White

$choice = Read-Host "Escolha uma opção"

switch ($choice) {
    case 1 {
        Install-Hosts-Blocklist
    }
    case 2 {
        Apply-Content-Filters-Config
    }
    case 3 {
        Write-Host "Estatísticas:" -ForegroundColor Cyan
        $allSites = Get-All-Blocked-Sites
        Write-Host "Total de sites nas blocklists: $($allSites.Count)" -ForegroundColor Yellow
        Write-Host "Listas configuradas: $($blockLists.Count)" -ForegroundColor Yellow
    }
    case 4 {
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $hostsPath -Force
            Write-Host "Backup restaurado." -ForegroundColor Green
        } else {
            Write-Host "Backup não encontrado." -ForegroundColor Red
        }
    }
    case 5 {
        Write-Host "Saindo..." -ForegroundColor Magenta
    }
    default {
        Write-Host "Opção inválida." -ForegroundColor Red
    }
}
#endregion