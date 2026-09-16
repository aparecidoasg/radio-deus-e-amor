<# ============================================================================
  NAVEGADOR SEGURO - Gerenciador de Downloads tipo IDM
  downloads_manager.ps1 - Monitora a pasta Downloads e gerencia transferências
  ============================================================================ #>

#region Configurações Globais
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$configPath = Join-Path $scriptDir "downloads_config.json"

# Arquivo de configuração para persistir estado dos downloads
if (-not (Test-Path $configPath)) {
    $initialConfig = @{
        "downloads" = @()
        "lastThreadCount" = 4
    }
    $initialConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath
}

$config = Get-Content $configPath | ConvertFrom-Json
$threadCount = $config.lastThreadCount
#endregion

#region Funções Auxiliares

function Get-Download-Status {
    param(
        [string]$downloadId
    )
    $downloads = $config.downloads
    foreach ($d in $downloads) {
        if ($d.id -eq $downloadId) {
            return $d
        }
    }
    return $null
}

function Set-Download-Status {
    param(
        [string]$downloadId,
        [object]$newStatus
    )
    $downloads = $config.downloads
    $existing = $downloads | Where-Object { $_.id -eq $downloadId }
    if ($existing) {
        $index = $downloads.IndexOf($existing)
        $downloads[$index] = $newStatus
    } else {
        $newStatus.id = $downloadId
        $config.downloads += $newStatus
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
}

function Invoke-Threads {
    param(
        [int]$count,
        [scriptblock]$action
    )
    $threads = @()
    for ($i = 0; $i -lt $count; $i++) {
        $threads += [System.Threading.Thread]::new($action)
        $threads[$i].Start()
    }
    return $threads
}
#endregion

#region Principais Comandos

# LISTAR todos os downloads monitorados
function List-Downloads {
    Write-Host "=== DOWNLOADS MONITOREADOS ===" -ForegroundColor Cyan
    $count = 0
    foreach ($d in $config.downloads) {
        $count++
        Write-Host "$count. ID: $($d.id)"
        Write-Host "   Status: $($d.status) | Progresso: $($d.progress)% | Velocidade: $($d.speed) | Threads: $($d.threads)"
        if ($d.filePath) {
            Write-Host "   Arquivo: $($d.filePath)"
        }
        Write-Host "----------------------------------------"
    }
    if ($count -eq 0) { Write-Host "Nenhum download monitorado." -ForegroundColor Yellow }
}

# ADICIONAR novo download monitorado
function Add-Download {
    param(
        [string]$url,
        [string]$filePath,
        [int]$threads
    )
    $newDownload = @{
        id = [Guid]::NewGuid().Guid
        url = $url
        filePath = $filePath
        status = "Paused"
        progress = 0
        speed = "0 KB/s"
        threads = $threads
        startTime = (Get-Date)
        lastUpdate = (Get-Date)
    }
    Set-Download-Status -downloadId $newDownload.id -newStatus $newDownload
    Write-Host "Download adicionado: $($newDownload.id)" -ForegroundColor Green
    return $newDownload.id
}

# ATUALIZAR status de um download
function Update-Download {
    param(
        [string]$downloadId,
        [string]$status,
        [string]$progress,
        [string]$speed
    )
    $d = Get-Download-Status -downloadId $downloadId
    if ($d) {
        $d.status = $status
        $d.progress = $progress
        $d.speed = $speed
        $d.lastUpdate = Get-Date
        Set-Download-Status -downloadId $downloadId -newStatus $d
        Write-Host "Download $downloadId atualizado: Status=$status Progresso=$progress" -ForegroundColor Cyan
    } else {
        Write-Host "Download $downloadId não encontrado." -ForegroundColor Red
    }
}

# PAUSAR um download
function Pause-Download {
    param([string]$downloadId)
    Update-Download -downloadId $downloadId -status "Paused" -progress $config.downloads | Where-Object { $_.id -eq $downloadId } -progress 0 -speed "0 KB/s"
    Write-Host "Download $downloadId pausado." -ForegroundColor Yellow
}

# RETOMAR um download
function Resume-Download {
    param([string]$downloadId)
    Update-Download -downloadId $downloadId -status "Active" -progress "0" -speed "Calculando..."
    Write-Host "Download $downloadId retomado." -ForegroundColor Green
}

# EXCLUIR registro de download
function Remove-Download {
    param([string]$downloadId)
    $config.downloads = $config.downloads | Where-Object { $_.id -ne $downloadId }
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-Host "Download $downloadId removido do monitor." -ForegroundColor Magenta
}

#endregion

#region Monitor de Pasta (Watcher)

# Este bloco roda em loop verificando a pasta Downloads do usuário
$watchedFolder = [Environment]::GetFolderPath('Personal') + "\Downloads"

function Start-Download-Watcher {
    Write-Host "Iniciando monitoramento da pasta: $watchedFolder" -ForegroundColor White
    
    do {
        try {
            $files = Get-ChildItem -Path $watchedFolder -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $fileName = $file.Name
                $filePath = $file.FullName
                $fileSize = $file.Length
                
                # Verificar se já está sendo monitorado
                $existing = $config.downloads | Where-Object { $_.filePath -eq $filePath }
                if ($existing) { continue }
                
                # Novo arquivo detectado - perguntar ao usuário (via console)
                Write-Host "Novo arquivo detectado: $fileName ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Yellow
                
                # Simular adição do download (em ambiente real, isso seria disparado por um link clicado)
                # Aqui adicionamos com threads padrão 4
                Add-Download -url "file://$filePath" -filePath $filePath -threads 4
                
                # Em um ambiente real, aqui teria lógica para detectar o download via browser
                # e começar o monitoramento de progresso via API do browser
            }
        } catch {
            Write-Error "Erro ao ler pasta de downloads: $_"
        }
        
        Start-Sleep -Seconds 5
        
    } while ($true)
}

# Endregion

#region Interface de Linha de Comando (CLI)

# Se o script for executado com argumentos, processa-os
if ($args.Count -gt 0) {
    switch ($args[0]) {
        case 'list':
            List-Downloads
            break
        case 'add':
            if ($args.Count -ge 4) {
                Add-Download -url $args[1] -filePath $args[2] -threads (int)$args[3]
            } else {
                Write-Host "Uso: powershell -ExecutionPolicy Bypass -File downloads_manager.ps1 add <url> <caminho> <threads>" -ForegroundColor Red
            }
            break
        case 'pause':
            if ($args.Count -ge 2) {
                Pause-Download -downloadId $args[1]
            }
            break
        case 'resume':
            if ($args.Count -ge 2) {
                Resume-Download -downloadId $args[1]
            }
            break
        case 'remove':
            if ($args.Count -ge 2) {
                Remove-Download -downloadId $args[1]
            }
            break
        default:
            Write-Host "Comando desconhecido. Use: list, add, pause, resume, remove" -ForegroundColor Red
            break
    }
} else {
    # Se nenhum argumento, mostrar menu interativo
    Write-Host "=== GERENCIADOR DE DOWNLOADS TIPO IDM ===" -ForegroundColor Cyan
    Write-Host "Comandos disponíveis: list, add, pause, resume, remove" -ForegroundColor White
    Write-Host "Ou execute sem argumentos para monitorar pasta (aperte Ctrl+C para sair)" -ForegroundColor Magenta
    
    # Iniciar o watcher em background (apenas demonstração)
    # Start-Download-Watcher
}
#endregion