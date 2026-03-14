Clear-Host

$Banner = @"
 █████╗ ███╗   ██╗██████╗ ███████╗██╗   ██╗███████╗
██╔══██╗████╗  ██║██╔══██╗██╔════╝██║   ██║██╔════╝
███████║██╔██╗ ██║██║  ██║█████╗  ██║   ██║███████╗
██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██║   ██║╚════██║
██║  ██║██║ ╚████║██████╔╝███████╗╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝                                 
                      
  ▀▄▀▄▀▄▀▄▀▄▀▄  ☣︎ INFECTION ☣︎  ▀▄▀▄▀▄▀▄▀▄▀▄▀                   
"@

Write-Host "=========================================================" -ForegroundColor DarkGray
Write-Host "🕵️‍♂️ ESCÁNER GLOBAL DE MODS Y HACKS INICIADO..." -ForegroundColor Cyan
Write-Host "Consultando API de Modrinth y realizando autopsias internas." -ForegroundColor DarkGray
Write-Host "=========================================================`n" -ForegroundColor DarkGray

# 1. Zonas de cacería (Lugares típicos donde esconden hacks)
$Carpetas = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents"
)

# 2. Firmas internas de Hacks (Palabras clave que los hacks no pueden borrar)
$PalabrasMaliciosas = @("doomsday", "vape", "koid", "manthe", "reach", "autoclicker", "raven", "b7", "kurumi", "client")

# Herramienta nativa para abrir JARs
Add-Type -AssemblyName System.IO.Compression.FileSystem
$HacksAtrapados = 0

foreach ($Carpeta in $Carpetas) {
    # Buscar todos los archivos .jar en estas carpetas
    $Archivos = Get-ChildItem -Path $Carpeta -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue

    foreach ($Archivo in $Archivos) {
        try {
            # Sacar la huella digital (Hash SHA1) que usa la API de Modrinth
            $Hash = (Get-FileHash -Path $Archivo.FullName -Algorithm SHA1).Hash.ToLower()

            # Consultar a la API de Modrinth
            $Url = "https://api.modrinth.com/v2/version_file/$Hash?algorithm=sha1"
            $Respuesta = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction SilentlyContinue

            if ($Respuesta) {
                # Modrinth lo reconoce, es legal.
                Write-Host "[LIMPIO] $($Archivo.Name) -> Mod oficial verificado por Modrinth." -ForegroundColor Green
            } else {
                # Modrinth NO lo reconoce. Podría ser un mod de CurseForge, un mod privado... o un HACK.
                Write-Host "[?] $($Archivo.Name) -> Archivo desconocido. Iniciando autopsia interna..." -ForegroundColor Yellow
                
                $Zip = [System.IO.Compression.ZipFile]::OpenRead($Archivo.FullName)
                $EsHack = $false

                # Leer el interior del .jar
                foreach ($Entrada in $Zip.Entries) {
                    foreach ($Palabra in $PalabrasMaliciosas) {
                        if ($Entrada.FullName.ToLower() -match $Palabra) {
                            $HacksAtrapados++
                            Write-Host "   [!] HACK DETECTADO: El archivo finge ser un mod legal." -ForegroundColor Red
                            Write-Host "       => Ruta: $($Archivo.FullName)" -ForegroundColor Red
                            Write-Host "       => Evidencia: Contiene el código sospechoso '$($Entrada.FullName)'`n" -ForegroundColor Red
                            $EsHack = $true
                            break
                        }
                    }
                    if ($EsHack) { break }
                }
                
                $Zip.Dispose() # Cerrar el archivo

                if (-not $EsHack) {
                    Write-Host "   [i] Autopsia limpia. Parece un mod seguro no registrado en Modrinth.`n" -ForegroundColor DarkGray
                }
            }
        } catch {
            Write-Host "   [x] El archivo $($Archivo.Name) está bloqueado o en uso.`n" -ForegroundColor DarkRed
        }
    }
}

Write-Host "=========================================================" -ForegroundColor DarkGray
Write-Host "[i] Escaneo finalizado. $HacksAtrapados hacks camuflados encontrados." -ForegroundColor Cyan
