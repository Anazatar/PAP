function Test-BackupSource {
    param([string]$source)

    if (-not (Test-Path -Path $source)) {
        return @{ Success = $false; Message = "❌ Diretório de origem não encontrado: $source" }
    }
    return @{ Success = $true; Message = "✅ Diretório de origem encontrado: $source" }
}

function Ensure-BackupDestination {
    param([string]$dest)

    if (-not (Test-Path -Path $dest)) {
        try {
            New-Item -Path $dest -ItemType Directory -Force | Out-Null
        } catch {
            return @{ Success = $false; Message = "❌ Não foi possível criar o diretório de destino: $dest" }
        }
    }
    return @{ Success = $true; Message = "✅ Diretório de destino pronto: $dest" }
}

function Execute-Backup {
    param(
        [string]$source,
        [string]$dest
    )

    $date = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path -Path $dest -ChildPath "Backup-$date.zip"

    try {
        Compress-Archive -Path $source -DestinationPath $backupFile -Force
    } catch {
        return @{ Success = $false; Message = "❌ Erro ao compactar: $_"; BackupPath = $null }
    }

    if (Test-Path -Path $backupFile) {
        return @{ Success = $true; Message = "✅ Backup criado com sucesso: $backupFile"; BackupPath = $backupFile }
    } else {
        return @{ Success = $false; Message = "❌ Falha ao criar o backup em: $backupFile"; BackupPath = $null }
    }
}
