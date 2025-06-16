function Test-BackupIntegrity {
    <#
        .SYNOPSIS
            Verifica se o ZIP de backup é íntegro conferindo SHA-256.

        .PARAMETER BackupFile
            Caminho completo do arquivo Backup-AAAAmmdd-HHMMSS.zip
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupFile
    )

    $checksumFile = "$BackupFile.sha256"

    if (-not (Test-Path $BackupFile)) {
        return @{ Success = $false; Message = "❌ Arquivo de backup não encontrado: $BackupFile" }
    }

    if (-not (Test-Path $checksumFile)) {
        return @{ Success = $false; Message = "❌ Arquivo de checksum não encontrado: $checksumFile" }
    }

    try {
        # Remove quebras de linha e normaliza caixa para comparar
        $storedHash = (Get-Content $checksumFile -Raw).Trim().ToUpper()
        $actualHash = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash.ToUpper()

        if ($storedHash -eq $actualHash) {
            return @{ Success = $true;  Message = "✅ Backup íntegro: hash confere." }
        } else {
            return @{ Success = $false; Message = "❌ Backup corrompido ou modificado: hash não confere." }
        }
    }
    catch {
        return @{ Success = $false; Message = "❌ Erro ao verificar integridade: $_" }
    }
}

Export-ModuleMember -Function Test-BackupIntegrity
