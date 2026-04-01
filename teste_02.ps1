<#

O arquivo "last-update-check.txt", mencionado na função "Should-CheckUpdate" é neste que fica anotado de forma simples a data/hora da ultima atualização;
Por causa de "(Get-Date) - $LAST -gt 6 horas" ele confere o que há de tempo/data/hora anotado e faz ou não
Se foi consultado/atualizado há pouco tempo, o retorno é: Should-CheckUpdate → FALSE

#>


########################################################################################
# CARREGA ASSEMBLY (OBRIGATÓRIO ANTES DO MESSAGEBOX)
########################################################################################
    Add-Type -AssemblyName System.Windows.Forms

########################################################################################
# CONFIGURAÇÃO DE VERSÃO LOCAL
########################################################################################
    $SCRIPT_VERSION = "0.10.0"

########################################################################################
# FUNÇÃO: Normaliza versão (garante formato correto)
########################################################################################
    function Normalize-Version($v) {
        $parts = $v.ToString().Trim().Split('.')
        while ($parts.Count -lt 3) {
            $parts += "0"
        }
        return ($parts -join '.')
    }

########################################################################################
# FUNÇÃO: Verifica se deve checar atualização (evita chamadas constantes)
########################################################################################
    function Should-CheckUpdate {

        $BASEPATH = "C:\teste"
        $UPDATECHECKFILE = "$BASEPATH\last-update-check.txt"

        if (!(Test-Path $BASEPATH)) {
            New-Item -ItemType Directory -Path $BASEPATH | Out-Null
        }

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
# FUNÇÃO: Verificar atualização no GitHub
########################################################################################
    function Check-ForUpdate {

        $VERSION_URL = "https://raw.githubusercontent.com/tcboeira/sup_model_simulacao/main/version.json"
        $BASEPATH = "C:\teste"
        $UPDATECHECKFILE = "$BASEPATH\last-update-check.txt"

        try {
            # 🔥 Busca versão remota
            $REMOTE = Invoke-RestMethod -Uri $VERSION_URL -TimeoutSec 5

            if (-not $REMOTE.version) { return $false }

            # 🔥 Normaliza versões
            $REMOTE_VERSION = Normalize-Version $REMOTE.version
            $LOCAL_VERSION  = Normalize-Version $SCRIPT_VERSION

            # 🔥 Comparação segura
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
if (Should-CheckUpdate) {
    Check-ForUpdate
}

