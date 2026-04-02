<#
.DESCRIPTION
    Verifica se há nova versão do script no GitHub.
    Possui controle de intervalo (6h) para evitar chamadas excessivas
    e opção de forçar verificação manual.

.PARAMETER ForceUpdateCheck
    Força a verificação ignorando o cache de 6 horas.
#>


param(
    [switch]$ForceUpdateCheck
)

########################################################################################
# FORÇA ENCODING UTF-8 (resolve acentuação)
########################################################################################
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


########################################################################################
# CARREGA ASSEMBLY
########################################################################################
Add-Type -AssemblyName System.Windows.Forms

########################################################################################
# CONFIGURAÇÕES
########################################################################################
$SCRIPT_VERSION = "0.10.0"
$BASEPATH = "C:\teste"
$UPDATECHECKFILE = "$BASEPATH\last-update-check.txt"
$VERSION_URL = "https://raw.githubusercontent.com/tcboeira/sup_model_simulacao/main/version.json"

########################################################################################
# GARANTE DIRETÓRIO BASE
########################################################################################
if (!(Test-Path $BASEPATH)) {
    New-Item -ItemType Directory -Path $BASEPATH | Out-Null
}

########################################################################################
# FUNÇÃO: Normaliza versão
########################################################################################
function Normalize-Version($v) {
    $parts = $v.ToString().Trim().Split('.')
    while ($parts.Count -lt 3) {
        $parts += "0"
    }
    return ($parts -join '.')
}

########################################################################################
# FUNÇÃO: Verifica se deve consultar atualização
########################################################################################
function Should-CheckUpdate {

    if (!(Test-Path $UPDATECHECKFILE)) {
        return $true
    }

    try {
        $LAST = Get-Content $UPDATECHECKFILE | Get-Date

        if ((Get-Date) - $LAST -gt (New-TimeSpan -Hours 6)) {
            return $true
        }
    }
    catch {
        return $true
    }

    return $false
}

########################################################################################
# FUNÇÃO: Verificar atualização
########################################################################################
function Check-ForUpdate {

    try {
        # 🔥 Busca versão remota
        $REMOTE = Invoke-RestMethod -Uri $VERSION_URL -TimeoutSec 5

        if (-not $REMOTE.version) {
            Write-Host "Não foi possível obter versão remota."
            return $false
        }

        # 🔥 Normaliza versões
        $REMOTE_VERSION = Normalize-Version $REMOTE.version
        $LOCAL_VERSION  = Normalize-Version $SCRIPT_VERSION

        Write-Host "Versão local : $LOCAL_VERSION"
        Write-Host "Versão remota: $REMOTE_VERSION"

        # 🔥 Comparação
        if ([version]$REMOTE_VERSION -gt [version]$LOCAL_VERSION) {

            $MSG = "Nova versão disponível: $REMOTE_VERSION`nVersão atual: $LOCAL_VERSION`n`nDeseja atualizar agora?"

            $RESULT = [System.Windows.Forms.MessageBox]::Show(
                $MSG,
                "Atualização disponível",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            if ($RESULT -eq "Yes" -and $REMOTE.download) {
                Start-Process $REMOTE.download
            }

            return $true
        }
        else {
            Write-Host "Script já está atualizado."
        }
    }
    catch {
        Write-Host "Erro ao verificar atualização:"
        Write-Host $_
    }
    finally {
        # 🔥 Registra última verificação
        (Get-Date) | Set-Content $UPDATECHECKFILE
    }

    return $false
}

########################################################################################
# EXECUÇÃO CONTROLADA
########################################################################################
$SHOULD_CHECK = Should-CheckUpdate
Write-Host ""
Write-Host "ShouldCheckUpdate: $SHOULD_CHECK"
Write-Host "ForceUpdateCheck: $ForceUpdateCheck"

if ($ForceUpdateCheck -or $SHOULD_CHECK) {
    Write-Host ""
    Write-Host "Verificando atualização..."
    Check-ForUpdate
    Write-Host ""

}
else {
    Write-Host ""
    Write-Host "Verificação ignorada (última checagem recente)."
    Write-Host ""
}
