<# ============================================================================
  NAVEGADOR SEGURO - Captura de Streams m3u8/m3u
  streams_capture.ps1 - Detecta e salva streams de vídeo ao vivo.
  ============================================================================ #>

#region Verificação de Dependências
$ffmpegPath = "ffmpeg"
$ffmpegCheck = Get-Command $ffmpegPath -ErrorAction SilentlyContinue
if (-not $ffmpegCheck) {
    Write-Warning "ffmpeg não encontrado no PATH."
    Write-Word "Para capturar streams, instale o ffmpeg ou use a extensão Video DownloadHelper."
    $ffmpegAvailable = $false
} else {
    $ffmpegAvailable = $true
}
#endregion

#region Funções de Captura

function Detect-M3U8-URL {
    param(
        [string]$url
    )
    try {
        $webClient = New-Object System.Net.WebClient
        $content = $webClient.DownloadString($url)
        # Procura por padrão m3u8
        if ($content -match "EXTM3U") {
            # Extrai a primeira URL de stream encontrada
            if ($content -match "URI:\s*(.+)") {
                $streamUrl = $matches[1].Trim()
                # Remover aspas se houver
                $streamUrl = $streamUrl -replace '"', ''
                $streamUrl = $streamUrl -replace ']', ''
                return $streamUrl
            }
        }
        return $null
    } catch {
        Write-Error "Erro ao acessar URL: $_"
        return $null
    }
}

function Save-Stream-M3U8 {
    param(
        [string]$streamUrl,
        [string]$outputPath
    )
    if (-not $ffmpegAvailable) {
        Write-Host "⚠ ffmpeg não disponível. Não é possível salvar o stream automaticamente." -ForegroundColor Yellow
        Write-Host "💡 Recomendação: Use a extensão 'Video DownloadHelper' no Firefox para salvar." -ForegroundColor Cyan
        return
    }
    
    $outputFile = "$outputPath\stream_$(Get-Date -Format 'yyyyMMdd_HHmmss').mp4"
    
    Write-Host "Iniciando captura do stream m3u8..." -ForegroundColor Cyan
    Write-Host "URL: $streamUrl" -ForegroundColor White
    Write-Host "Saída: $outputFile" -ForegroundColor White
    
    # Comando ffmpeg para baixar stream m3u8
    # -headers necessário alguns casos, mas mantemos simples
    $command = "ffmpeg -i `"$streamUrl`" -c copy -map 0:v:0 -map 0:a:0 -y `"$outputFile`""
    
    try {
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -RedirectOutput -PassThru -Wait
        if ($process.ExitCode -eq 0) {
            Write-Host "✅ Stream salvo com sucesso em: $outputFile" -ForegroundColor Green
        } else {
            Write-Word "⚠ ffmpeg terminou com código $($process.ExitCode). O stream pode estar protegido ou exigir headers." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Erro ao executar ffmpeg: $_"
    }
}

#endregion

#region Interface Principal

Write-Host "=== CAPTURA DE STREAMS M3U8/M3U - NAVEGADOR SEGURO ===" -ForegroundColor Magenta

# Modo interativo ou parâmetros
if ($args.Count -ge 1) {
    $action = $args[0]
} else {
    $action = "menu"
}

switch ($action) {
    case 'detect':
        if ($args.Count -ge 2) {
            $url = $args[1]
            $detected = Detect-M3U8-URL -url $url
            if ($detected) {
                Write-Host "✅ Stream m3u8 detectado:" -ForegroundColor Green
                Write-Host "   URL: $detected" -ForegroundColor White
            } else {
                Write-Host "❌ Não foi possível detectar stream m3u8 na URL fornecida." -ForegroundColor Red
            }
        } else {
            Write-Host "Uso: .\streams_capture.ps1 detect <URL_do_site>" -ForegroundColor Red
        }
    }
    case 'save':
        if ($args.Count -ge 3) {
            $streamUrl = $args[1]
            $outputDir = $args[2]
            Save-Stream-M3U8 -streamUrl $streamUrl -outputPath $outputDir
        } else {
            Write-Host "Uso: .\streams_capture.ps1 save <URL_stream> <pasta_saida>" -ForegroundColor Red
        }
    case 'menu':
    default:
        Write-Host "Opções disponíveis:" -ForegroundColor Cyan
        Write-Host "1. detect <URL> - Detectar stream m3u8 em uma URL" -ForegroundColor White
        Write-Host "2. save <URL> <pasta> - Salvar stream usando ffmpeg" -ForegroundColor White
        Write-Host "3. verificar - Verificar se ffmpeg está disponível" -ForegroundColor White
        Write-Host "sair - Encerrar" -ForegroundColor Magenta
        
        do {
            $input = Read-Host "Escolha uma opção"
            switch ($input) {
                case 'detect':
                    $u = Read-Host "URL do site"
                    Detect-M3U8-URL -url $u
                    break
                case 'save':
                    $s = Read-Host "URL do stream"
                    $d = Read-Host "Pasta de saída (ex: ./videos)"
                    Save-Stream-M3U8 -streamUrl $s -outputPath $d
                    break
                case 'verificar':
                    if ($ffmpegAvailable) {
                        Write-Host "✅ ffmpeg está disponível." -ForegroundColor Green
                    } else {
                        Write-Host "⚠ ffmpeg não encontrado. Instale para salvar streams." -ForegroundColor Yellow
                    }
                    break
                case 'sair':
                    break
                default:
                    Write-Host "Opção inválida." -ForegroundColor Red
                    break
            }
        } while ($input -ne 'sair')
}
#endregion