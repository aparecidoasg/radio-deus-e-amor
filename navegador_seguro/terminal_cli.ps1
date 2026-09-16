<# ============================================================================
  NAVEGADOR SEGURO - Terminal Integrado
  terminal_cli.ps1 - Acesso rápido a comandos úteis no perfil do navegador
  ============================================================================ #>

#region Configurações
$firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
$secureProfile = Get-ChildItem $firefoxProfilePath | Where-Object { $_.Name -match "secure$" -or $_.Name -match "Secure$" } | Select-Object -First 1

if (-not $secureProfile) {
    Write-Host "⚠ Perfil 'Secure' do Firefox não encontrado." -ForegroundColor Red
    Write-Host "Execute o instalador primeiro ou verifique o perfil." -ForegroundColor Yellow
    return
}

$prefsJs = Join-Path $secureProfile "prefs.js"
#endregion

#region Funções de Manutenção

function Clean-Cache {
    Write-Host "Limpando cache do Firefox..." -ForegroundColor Cyan
    # Limpar cache da disque
    $cacheDir = Join-Path $secureProfile "cache2"
    if (Test-Path $cacheDir) {
        Remove-Item -Path "$cacheDir\*" -Force -ErrorAction SilentlyContinue
        Write-Host "Cache limpo." -ForegroundColor Green
    }
    
    # Limpar cache da memoria
    $memoryCache = Join-Path $secureProfile "webapps-store"
    if (Test-Path $memoryCache) {
        Remove-Item -Path "$memoryCache\*" -Force -ErrorAction SilentlyContinue
    }
    
    # Limpar dados offline
    $offlineCache = Join-Path $secureProfile "offline-cache"
    if (Test-Path $offlineCache) {
        Remove-Item -Path "$offlineCache\*" -Force -ErrorAction SilentlyContinue
    }
}

function Clean-Cookies-Domain {
    param([string]$domain)
    Write-Host "Limpando cookies do domínio: $domain" -ForegroundColor Cyan
    # O Firefox armazena cookies em sqlite; limpar entries específicas requer sqlite3
    # Aqui simplificamos: remover arquivos de cookie do domínio
    $cookieFiles = Get-ChildItem "$secureProfile\cookies*" -ErrorAction SilentlyContinue
    foreach ($cf in $cookieFiles) {
        # Remover apenas cookies do domínio especificado (baseado em nome de arquivo)
        if ($cf.Name -match "$domain") {
            Remove-Item -Path $cf.FullName -Force
        }
    }
    Write-Host "Cookies do domínio $domain removidos." -ForegroundColor Green
}

function List-Extensions {
    Write-Host "Extensões instaladas no perfil Secure:" -ForegroundColor Cyan
    $extensionsDir = Join-Path $secureProfile "extensions"
    if (Test-Path $extensionsDir) {
        $exts = Get-ChildItem $extensionsDir -Directory
        foreach ($ext in $exts) {
            Write-Host "  - $($ext.Name)" -ForegroundColor White
        }
    } else {
        Write-Host "Nenhuma extensão encontrada." -ForegroundColor Yellow
    }
}

function Show-Firefox-Status {
    Write-Host "=== STATUS DO FIREFOX SEGURO ===" -ForegroundColor Magenta
    if ($secureProfile) {
        Write-Host "Perfil: $($secureProfile.Name)" -ForegroundColor White
        Write-Host "Caminho: $($secureProfile.FullName)" -ForegroundColor White
        $prefs = Test-Path $prefsJs
        Write-Host "Arquivo prefs.js existe: $prefs" -ForegroundColor White
    } else {
        Write-Host "Perfil não encontrado." -ForegroundColor Red
    }
}

#endregion

#region Interface de Linha de Comando

# Se executado com argumentos, processa os comandos
if ($args.Count -gt 0) {
    switch ($args[0]) {
        case 'limpar-cache':
            Clean-Cache
            break
        case 'limpar-cookies':
            if ($args.Count -ge 2) {
                Clean-Cookies-Domain -domain $args[1]
            } else {
                Write-Host "Uso: .\terminal_cli.ps1 limpar-cookies <dominio>" -ForegroundColor Red
            }
            break
        case 'list-ext':
            List-Extensions
            break
        case 'status':
            Show-Firefox-Status
            break
        case 'ajuda':
            Write-Host "=== COMANDOS DISPONÍVEIS ===" -ForegroundColor Cyan
            Write-Host "1. limpar-cache          - Limpa cache e dados temporários" -ForegroundColor White
            Write-Host "2. limpar-cookies <dom>  - Remove cookies de um domínio específico" -ForegroundColor White
            Write-Host "3. list-ext              - Lista extensões instaladas" -ForegroundColor White
            Write-Host "4. status                - Mostra status do perfil Firefox" -ForegroundColor White
            Write-Host "5. sair                - Encerra o terminal" -ForegroundColor White
            break
        case 'sair':
            Write-Host "Encerrando terminal..." -ForegroundColor Magenta
            return
        default:
            Write-Host "Comando desconhecido. Digite 'ajuda' para ver os comandos." -ForegroundColor Red
            break
    }
} else {
    # Menu interativo se nenhum argumento
    Write-Host "=== TERMINAL INTEGRADO FIREFOX SEGURO ===" -ForegroundColor Cyan
    Write-Host "Digite 'ajuda' para ver os comandos disponíveis." -ForegroundColor White
    Write-Host "----------------------------------------"
    
    # Loop simples
    do {
        $input = Read-Host "Comando>"
        switch ($input) {
            case 'limpar-cache':
                Clean-Cache
                break
            case 'limpar-cookies':
                $d = Read-Host "Dominio"
                Clean-Cookies-Domain -domain $d
                break
            case 'list-ext':
                List-Extensions
                break
            case 'status':
                Show-Firefox-Status
                break
            case 'sair':
                Write-Host "Encerrando..." -ForegroundColor Magenta
                break
            default:
                Write-Host "Comando desconhecido. Digite 'ajuda'." -ForegroundColor Red
                break
        }
    } while ($input -ne 'sair')
}
#endregion