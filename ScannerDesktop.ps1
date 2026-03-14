Clear-Host
Write-Host "=========================================================" -ForegroundColor DarkGray
Write-Host "🕵️‍♂️ ESCÁNER GLOBAL DE MODS (V3 - IDENTIFICADOR) INICIADO..." -ForegroundColor Cyan
Write-Host "Consultando API de Modrinth y analizando firmas internas." -ForegroundColor DarkGray
Write-Host "=========================================================`n" -ForegroundColor DarkGray

$Carpetas = @("$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents")

# EL DICCIONARIO FORENSE: Asocia la carpeta interna con el nombre del Hack
$DiccionarioHacks = @{
    "doomsday" = "Doomsday Client"
    "vape" = "Vape V4 / Lite"
    "manthe" = "Vape Client (Firma de Manthe)"
    "koid" = "Koid Injector"
    "raven" = "Raven B+ / B4"
    "b7" = "B7 Client"
    "kurumi" = "Kurumi Client"
    "autoclicker" = "Módulo de AutoClicker"
    "reach" = "Módulo de Reach / Hitbox"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$HacksAtrapados = 0

foreach ($Carpeta in $Carpetas) {
    $Archivos = Get-ChildItem -Path $Carpeta -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue

    foreach ($Archivo in $Archivos) {
        try {
            # 1. Consultar a la API de Modrinth
            $Hash = (Get-FileHash -Path $Archivo.FullName -Algorithm SHA1 -ErrorAction Stop).Hash.ToLower()
            $Url = "https://api.modrinth.com/v2/version_file/$Hash?algorithm=sha1"
            $Respuesta = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction SilentlyContinue

            if ($Respuesta) {
                Write-Host "[LIMPIO] $($Archivo.Name) -> Mod verificado por Modrinth." -ForegroundColor Green
            } else {
                Write-Host "[?] $($Archivo.Name) -> Desconocido. Analizando el interior..." -ForegroundColor Yellow
                
                # 2. Copia Ninja para evitar bloqueos
                $RutaTemp = "$env:TEMP\Analisis_$($Archivo.Name)"
                Copy-Item -Path $Archivo.FullName -Destination $RutaTemp -Force -ErrorAction SilentlyContinue
                
                if (Test-Path $RutaTemp) {
                    try {
                        # Intentar abrir el archivo como ZIP
                        $Zip = [System.IO.Compression.ZipFile]::OpenRead($RutaTemp)
                        $HackDetectado = $null
                        $Evidencia = ""

                        # 3. Buscar firmas en el Diccionario
                        foreach ($Entrada in $Zip.Entries) {
                            foreach ($Firma in $DiccionarioHacks.Keys) {
                                if ($Entrada.FullName.ToLower() -match $Firma) {
                                    $HackDetectado = $DiccionarioHacks[$Firma]
                                    $Evidencia = $Entrada.FullName
                                    break
                                }
                            }
                            if ($HackDetectado) { break }
                        }
                        
                        $Zip.Dispose() 

                        # 4. El Veredicto Detallado
                        if ($HackDetectado) {
                            $HacksAtrapados++
                            Write-Host "   [!] ALERTA CRÍTICA: CLIENTE ILEGAL IDENTIFICADO" -ForegroundColor Red
                            Write-Host "       => Nombre Falso: $($Archivo.Name)" -ForegroundColor DarkGray
                            Write-Host "       => Hack Identificado: $HackDetectado" -ForegroundColor Magenta
                            Write-Host "       => Evidencia Interna: Encontró la clase '$Evidencia'`n" -ForegroundColor Red
                        } else {
                            Write-Host "   [i] Autopsia limpia. Es un mod no registrado en Modrinth.`n" -ForegroundColor DarkGray
                        }
                    } catch {
                        # Si falla aquí, es porque el archivo .jar está vacío, corrupto o es falso
                        Write-Host "   [x] Archivo inválido o corrupto (No es un archivo Java real).`n" -ForegroundColor DarkRed
                    } finally {
                        # Siempre borrar la evidencia de la copia temporal
                        if (Test-Path $RutaTemp) { Remove-Item -Path $RutaTemp -Force -ErrorAction SilentlyContinue }
                    }
                }
            }
        } catch {}
    }
}
Write-Host "=========================================================" -ForegroundColor DarkGray
Write-Host "[i] Escaneo finalizado. $HacksAtrapados hacks identificados." -ForegroundColor Cyan
