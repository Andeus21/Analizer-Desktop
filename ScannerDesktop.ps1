Clear-Host
Write-Host "🕵️‍♂️ INICIANDO ESCÁNER DE MEMORIA CON VIRUSTOTAL API..." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor DarkGray

# --- CONFIGURACIÓN ---
$ApiKey = "808766d0d632c4f596de2abac41993cfffed00f9910ef4135bd57daf91d62758"  
$Headers = @{ "x-apikey" = $ApiKey }

# 1. Filtro Inteligente: Solo buscar procesos que se ejecuten desde la carpeta del Usuario (C:\Users\...)
$ProcesosSospechosos = Get-Process | Where-Object { $_.Path -like "*\Users\*" }

if ($ProcesosSospechosos.Count -eq 0) {
    Write-Host "[i] No hay procesos sospechosos corriendo en el espacio del usuario." -ForegroundColor Green
    exit
}

Write-Host "[!] Se encontraron $($ProcesosSospechosos.Count) procesos activos en zonas de riesgo. Analizando Hashes..." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray

foreach ($Proceso in $ProcesosSospechosos) {
    try {
        # 2. Calcular la Huella Digital (Hash SHA-256)
        $Hash = (Get-FileHash -Path $Proceso.Path -Algorithm SHA256 -ErrorAction Stop).Hash
        
        # 3. Consultar a la API de VirusTotal
        $Url = "https://www.virustotal.com/api/v3/files/$Hash"
        $Respuesta = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -ErrorAction SilentlyContinue
        
        if ($Respuesta) {
            $Maliciosos = $Respuesta.data.attributes.last_analysis_stats.malicious
            $Totales = $Respuesta.data.attributes.last_analysis_results.PSObject.Properties.Count
            
            # 4. Mostrar el Veredicto
            if ($Maliciosos -gt 0) {
                Write-Host "[PELIGRO] $($Proceso.Name) (PID: $($Proceso.Id))" -ForegroundColor Red
                Write-Host "   => Ruta: $($Proceso.Path)" -ForegroundColor Red
                Write-Host "   => Detecciones: $Maliciosos / $Totales antivirus lo marcan como Hack/Malware!`n" -ForegroundColor Red
            } else {
                Write-Host "[LIMPIO] $($Proceso.Name) -> 0/$Totales detecciones." -ForegroundColor Green
            }
        } else {
            Write-Host "[?] $($Proceso.Name) -> Archivo desconocido para VirusTotal (Posible Hack Privado o archivo nuevo)." -ForegroundColor Yellow
        }
        
        # Pausa de 15 segundos para no saturar la API gratuita
        Start-Sleep -Seconds 15 
    } catch {
        # Ignorar procesos protegidos que no se dejan leer
    }
}
Write-Host "========================================================" -ForegroundColor DarkGray

Write-Host "🕵️‍♂️ ESCANEO FINALIZADO." -ForegroundColor Cyan
