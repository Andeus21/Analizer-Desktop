Clear-Host
Write-Host "🕵️‍♂️ INICIANDO ESCÁNER DE MEMORIA AVANZADO (VT API)..." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor DarkGray

# --- CONFIGURACIÓN ---
$ApiKey = "808766d0d632c4f596de2abac41993cfffed00f9910ef4135bd57daf91d62758"  # ¡Pon tu nueva llave generada!
$Headers = @{ "x-apikey" = $ApiKey }

# 1. Usar WMI para poder leer los "Argumentos" ocultos de los procesos
$ProcesosWMI = Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -like "*\Users\*" -or $_.Name -match "java" }

if ($ProcesosWMI.Count -eq 0) {
    Write-Host "[i] No hay procesos sospechosos corriendo." -ForegroundColor Green
    exit
}

Write-Host "[!] Se encontraron $($ProcesosWMI.Count) procesos activos. Analizando Hashes y Argumentos..." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray

foreach ($proc in $ProcesosWMI) {
    try {
        $RutaAAnalizar = $proc.ExecutablePath
        $NombreProceso = $proc.Name

        # 2. EL FILTRO ANTI-JAVA: Extraer el .jar malicioso de los argumentos
        if ($NombreProceso -match "java" -and $proc.CommandLine -match "\.jar") {
            # Buscar la ruta exacta del .jar usando Regex (ignora las comillas)
            if ($proc.CommandLine -match '(?i)(?:")?([A-Za-z]:\\[^"]+\.jar)(?:")?') {
                $RutaAAnalizar = $matches[1]
                $NombreProceso = Split-Path $RutaAAnalizar -Leaf
                Write-Host "[*] PASAJERO DETECTADO: Java está ejecutando -> $NombreProceso" -ForegroundColor Magenta
            }
        }

        # Evitar escanear carpetas vacías o rutas nulas
        if (-not $RutaAAnalizar -or -not (Test-Path $RutaAAnalizar -PathType Leaf)) { continue }

        # 3. Calcular la Huella Digital del Archivo Real
        $Hash = (Get-FileHash -Path $RutaAAnalizar -Algorithm SHA256 -ErrorAction Stop).Hash
        
        # 4. Consultar a la API de VirusTotal
        $Url = "https://www.virustotal.com/api/v3/files/$Hash"
        $Respuesta = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -ErrorAction SilentlyContinue
        
        if ($Respuesta) {
            $Maliciosos = $Respuesta.data.attributes.last_analysis_stats.malicious
            $Totales = $Respuesta.data.attributes.last_analysis_results.PSObject.Properties.Count
            
            if ($Maliciosos -gt 0) {
                Write-Host "[PELIGRO] $NombreProceso (PID: $($proc.ProcessId))" -ForegroundColor Red
                Write-Host "   => Ruta: $RutaAAnalizar" -ForegroundColor Red
                Write-Host "   => Detecciones: $Maliciosos / $Totales antivirus lo marcan como Hack/Malware!`n" -ForegroundColor Red
            } else {
                Write-Host "[LIMPIO] $NombreProceso -> 0/$Totales detecciones." -ForegroundColor Green
            }
        } else {
            Write-Host "[?] $NombreProceso -> Archivo desconocido para VirusTotal (Posible Hack Privado o recién renombrado)." -ForegroundColor Yellow
        }
        
        Start-Sleep -Seconds 15 
    } catch {
        # Ignorar errores de permisos
    }
}
Write-Host "========================================================" -ForegroundColor DarkGray
Write-Host "🕵️‍♂️ ESCANEO FINALIZADO." -ForegroundColor Cyan
