########################################################################################
# Declaração de versão Script
########################################################################################
$SCRIPT_VERSION = "0.12.0"


function Check-ForUpdate {

    $VERSION_URL = "https://raw.githubusercontent.com/tcboeira/pro_model_sim/main/version.json"

    try {
        $REMOTE = Invoke-RestMethod -Uri $VERSION_URL -TimeoutSec 5

        if (-not $REMOTE.version) { return $false }

        $REMOTE_VERSION = $REMOTE.version

        if ([version]$REMOTE_VERSION -gt [version]$SCRIPT_VERSION) {

            $MSG = "Nova versão disponível: $REMOTE_VERSION`nVersão atual: $SCRIPT_VERSION`n`nDeseja atualizar agora?"

            $RESULT = [System.Windows.Forms.MessageBox]::Show(
                $MSG,
                "Atualização disponível",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            if ($RESULT -eq "Yes") {
                Start-Process $REMOTE.download
            }

            return $true
        }
    }
    catch {
        # silencioso
    }

    return $false
}



Check-ForUpdate


