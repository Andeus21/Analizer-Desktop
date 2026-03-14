# ====================================================================
# ESCÁNER - Client Ilegales
# ====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

$Banner = @"
 █████╗ ███╗  ██╗██████╗ ███████╗██╗   ██╗███████╗
██╔══██╗████╗  ██║██╔══██╗██╔════╝██║   ██║██╔════╝
███████║██╔██╗ ██║██║  ██║█████╗  ██║   ██║███████╗
██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██║   ██║╚════██║
██║  ██║██║ ╚████║██████╔╝███████╗╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝                                 
                      
  ▀▄▀▄▀▄▀▄▀▄▀▄  ☣︎ INFECTION ☣︎  ▀▄▀▄▀▄▀▄▀▄▀▄▀                   
"@

Write-Host $Banner -ForegroundColor Green
Write-Host "_____________________________________________________" -ForegroundColor DarkGreen
Write-Host ""

$Carpetas = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Pictures",
    "$env:TEMP"
)

$Clientes = @("fapcraft", "doomsday", "asteria", "prestige", "xenon", "argon", "hellion", "grim client", "virgin", "donut", "dev.krypton", "dev.gambleclient", "raven", "bplus", "keystrokesmod", "liquidbounce", "net.ccbluex", "meteor client", "meteorclient", "wurst", "kamiblue", "impact client")
$ModulosIlegales = @("aimassist", "autocrystal", "triggerbot", "shieldbreaker", "antiknockback", "flight", "autototem", "blockesp", "packspoof", "cheststeal", "autoclicker", "xray", "advanced xray", "attack through grass", "attackthroughgrass", "inventory profiles next", "inventoryprofilesnext", "freecam", "accurate block placement", "accurateblockplacement", "marlow crystal", "marlowcrystal", "macro", "reach")
$PatronesOcultos = @("org.chainlibs", "keyboardmixin", "clientplayerinteractionmanagermixin", "phantom-refmap.json", "xyz.greaj", "jnativehook", "licensecheckmixin", "imgui", "imgui.gl3", "sub_classes")

# ¡NUEVA BASE DE DATOS! Armas de los Inyectores Externos
$FirmasInyectores = @("com/sun/tools/attach", "sun/tools/attach", "virtualmachine.class", "jna/win32", "agentmain", "premain", ".dll")

Add-Type -AssemblyName System.IO.Compression.FileSystem
$hacksEncontrados = 0

foreach ($Carpeta in $Carpetas) {
    if (-not (Test-Path $Carpeta)) { continue }
    Write-Host "Escaneando directorio: $Carpeta`n" -ForegroundColor Yellow

    $archivos = Get-ChildItem -Path $Carpeta -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 150MB -and $_.Extension -ne ".lnk" }

    foreach ($archivo in $archivos) {
        $RutaDeLectura = $archivo.FullName
        $CopiaForense = $false

        try { $hash = (Get-FileHash $RutaDeLectura -Algorithm SHA1 -ErrorAction Stop).Hash.ToLower() } 
        catch {
            $RutaTemp = "$env:TEMP\Forense_$($archivo.Name)"
            Copy-Item -Path $RutaDeLectura -Destination $RutaTemp -Force -ErrorAction SilentlyContinue
            $RutaDeLectura = $RutaTemp
            $CopiaForense = $true
            try { $hash = (Get-FileHash $RutaDeLectura -Algorithm SHA1 -ErrorAction Stop).Hash.ToLower() } catch { continue }
        }

        try {
            $Bytes = Get-Content -Path $RutaDeLectura -Encoding Byte -TotalCount 2 -ErrorAction Stop
            $Hex = [System.BitConverter]::ToString($Bytes)
            if ($Hex -ne "50-4B") { 
                if ($CopiaForense) { Remove-Item -Path $RutaDeLectura -Force -ErrorAction SilentlyContinue }
                continue 
            }
        } catch { continue }

        Write-Host "Analizando: [$($archivo.Name)]" -ForegroundColor Gray
        Write-Host "   [ID]: $hash" -ForegroundColor DarkGray
        $esVerificado = $false

        try {
            $respModrinth = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$hash" -Method Get -ErrorAction Stop
            Write-Host "   >> VEREDICTO: ✅ SEGURO (Validado por Modrinth API)" -ForegroundColor Cyan
            $esVerificado = $true
        } catch {
            try {
                $respMegabase = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$hash" -Method Get -ErrorAction Stop
                if ($respMegabase -and $respMegabase.name) {
                    Write-Host "   >> VEREDICTO: ✅ SEGURO (Validado por Megabase API)" -ForegroundColor Cyan
                    $esVerificado = $true
                }
            } catch { }
        }

        if (-not $esVerificado) {
            Write-Host "   [i] Archivo Desconocido. Escaneando interior..." -ForegroundColor DarkYellow
            $esHack = $false
            $motivo = ""

            # MOTOR A: Estructura Interna (Atrapa a Doomsday Inyector y Mods)
            try {
                $Zip = [System.IO.Compression.ZipFile]::OpenRead($RutaDeLectura)
                foreach ($Entrada in $Zip.Entries) {
                    $RutaInterna = $Entrada.FullName.ToLower()
                    
                    # Caza de Inyectores (El secreto)
                    foreach ($arma in $FirmasInyectores) { if ($RutaInterna -match $arma) { $esHack = $true; $motivo += "ArmaInyector:$arma " } }
                    
                    foreach ($firma in $Clientes) { if ($RutaInterna -match $firma) { $esHack = $true; $motivo += "Carpeta:$firma " } }
                    foreach ($modulo in $ModulosIlegales) { if ($RutaInterna -match $modulo) { $esHack = $true; $motivo += "Clase:$modulo " } }
                    if ($esHack) { break }
                }
                $Zip.Dispose()
            } catch { }

            # MOTOR B: Fuerza Bruta de Texto
            if (-not $esHack) {
                try {
                    $contenido = [System.IO.File]::ReadAllText($RutaDeLectura, [System.Text.Encoding]::ASCII).ToLower()
                    if ($contenido -match "jnativehook" -and $archivo.Name -match "voicechat") {
                        Write-Host "   [i] Excepción aplicada: Mod de VoiceChat detectado." -ForegroundColor DarkCyan
                    } else {
                        foreach ($arma in $FirmasInyectores) { if ($contenido -match $arma) { $esHack = $true; $motivo += "ArmaTxt:$arma " } }
                        foreach ($firma in $Clientes) { if ($contenido -match $firma) { $esHack = $true; $motivo += "FirmaTxt:$firma " } }
                        foreach ($modulo in $ModulosIlegales) { if ($contenido -match $modulo) { $esHack = $true; $motivo += "ModTxt:$modulo " } }
                        foreach ($patron in $PatronesOcultos) { if ($contenido -match $patron) { $esHack = $true; $motivo += "MixinTxt:$patron " } }
                    }
                } catch { }
            }

            if ($esHack) {
                $hacksEncontrados++
                Write-Host "   >> VEREDICTO: ❌ HACK DETECTADO ($motivo)" -ForegroundColor Red
                Write-Host "      Ubicación: $($archivo.FullName)" -ForegroundColor Red
            } else {
                Write-Host "   >> VEREDICTO: ⚠️ MODIFICADO / DESCONOCIDO (Revisar manual)" -ForegroundColor Yellow
                Write-Host "      Ubicación: $($archivo.FullName)" -ForegroundColor DarkGray
            }
        }
        
        if ($CopiaForense -and (Test-Path $RutaDeLectura)) { Remove-Item -Path $RutaDeLectura -Force -ErrorAction SilentlyContinue }
        Write-Host ""
    }
}

Write-Host "======================================================" -ForegroundColor DarkGreen
Write-Host "Resumen: Se encontraron $hacksEncontrados archivos ilegales." -ForegroundColor Yellow
