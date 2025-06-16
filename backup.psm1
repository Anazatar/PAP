<#  Módulo de utilidades de backup
    Exporta: Test-BackupSource, Ensure-BackupDestination, Execute-Backup, Test-InstalledApps
#>

function Test-BackupSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Source
    )
    if (-not (Test-Path -Path $Source)) {
        return @{ Success = $false; Message = "❌ Diretório de origem não encontrado: $Source" }
    }
    return @{ Success = $true; Message = "✅ Diretório de origem encontrado:  $Source" }
}

function Ensure-BackupDestination {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Dest
    )
    if (-not (Test-Path -Path $Dest)) {
        try   { New-Item -Path $Dest -ItemType Directory -Force | Out-Null }
        catch { return @{ Success = $false; Message = "❌ Não foi possível criar o diretório de destino: $Dest" } }
    }
    return @{ Success = $true; Message = "✅ Diretório de destino pronto:      $Dest" }
}

function Execute-Backup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Source,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Dest
    )

    if ($Dest -like "$Source*") {
        return @{ Success = $false; Message = "❌ O diretório de destino não pode estar dentro da origem."; BackupPath = $null }
    }

    $date       = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupFile = Join-Path $Dest "Backup-$date.zip"

    try   { Compress-Archive -Path $Source -DestinationPath $backupFile -Force }
    catch { return @{ Success = $false; Message = "❌ Erro ao compactar: $_"; BackupPath = $null } }

    if (Test-Path $backupFile) {
        return @{ Success = $true; Message = "✅ Backup criado com sucesso: $backupFile"; BackupPath = $backupFile }
    }
    return @{ Success = $false; Message = "❌ Falha ao criar o backup em: $backupFile"; BackupPath = $null }
}

function Test-InstalledApps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$RequiredApps
    )

    $found   = @{}
    $missing = @()

    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($app in $RequiredApps) {
        $match = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -and $_.DisplayName -like "*$app*" } |
                 Select-Object -First 1
        if ($match) { $found[$app] = $match.DisplayVersion }
        else        { $missing += $app }
    }

    return [ordered]@{ Found = $found; Missing = $missing }
}

Export-ModuleMember -Function Test-BackupSource, Ensure-BackupDestination, Execute-Backup, Test-InstalledApps
