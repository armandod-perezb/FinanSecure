param(
  [string]$OutputDir = ".\lab-output",
  [switch]$VerboseMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $line = "[$timestamp] $Message"
  Write-Host $line
  Add-Content -Path $global:LogFile -Value $line
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$global:LogFile = Join-Path $OutputDir "infostealer_simulation.log"
"=== INFOSTEALER DEFENSIVE SIMULATION ===" | Set-Content -Path $global:LogFile

Write-Step "Inicio de simulacion defensiva (sin robo real, sin exfiltracion real)."

$decoyDir = Join-Path $OutputDir "decoy-data"
if (-not (Test-Path -LiteralPath $decoyDir)) {
  New-Item -ItemType Directory -Path $decoyDir | Out-Null
}

$decoyFile = Join-Path $decoyDir "decoy_credentials.txt"
@"
usuario_demo=analista@finansecure.local
password_demo=PasswordFicticio123!
token_demo=eyJhbGciOiJIUzI1NiJ9.ficticio
"@ | Set-Content -Path $decoyFile

Write-Step "Decoy creado en: $decoyFile"

Write-Step "Simulando descubrimiento de rutas comunes de navegador."
$browserPaths = @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies",
  "$env:APPDATA\Mozilla\Firefox\Profiles"
)

foreach ($path in $browserPaths) {
  if (Test-Path -LiteralPath $path) {
    Write-Step "Ruta encontrada (solo inventario): $path"
  } else {
    Write-Step "Ruta no encontrada: $path"
  }
}

Write-Step "Simulando lectura de archivo sensible (decoy)."
$decoyPreview = Get-Content -Path $decoyFile -TotalCount 3
foreach ($line in $decoyPreview) {
  if ($VerboseMode) {
    Write-Step "Contenido decoy leido: $line"
  }
}

Write-Step "Simulando actividad de empaquetado de datos (ficticia)."
$bundleFile = Join-Path $OutputDir "staged_bundle.txt"
Get-Content -Path $decoyFile | Set-Content -Path $bundleFile
Write-Step "Archivo staged creado: $bundleFile"

Write-Step "Simulando intento de conexion saliente sospechosa hacia IP de pruebas RFC5737."
try {
  $connection = Test-NetConnection -ComputerName "198.51.100.10" -Port 443 -WarningAction SilentlyContinue
  Write-Step "Resultado conexion: TcpTestSucceeded=$($connection.TcpTestSucceeded)"
} catch {
  Write-Step "Conexion simulada genero excepcion controlada: $($_.Exception.Message)"
}

Write-Step "Generando artefactos finales de evidencia."
$summaryFile = Join-Path $OutputDir "simulation_summary.txt"
@(
  "Simulacion InfoStealer ejecutada (defensiva)."
  "Cookies detectadas (ficticio): 14"
  "Tokens detectados (ficticio): 6"
  "Credenciales simuladas (ficticio): 3"
  "SIEM: comportamiento anomalo esperado por secuencia de procesos/archivos/red."
  "Firewall/EDR: alertas esperadas por intento de conexion y acceso a rutas de navegador."
) | Set-Content -Path $summaryFile

Write-Step "Resumen generado en: $summaryFile"
Write-Step "Simulacion finalizada."

Write-Host ""
Write-Host "Simulacion InfoStealer ejecutada"
Write-Host "Cookies detectadas: 14 (ficticio)"
Write-Host "Tokens detectados: 6 (ficticio)"
Write-Host "Credenciales simuladas: 3 (ficticio)"
Write-Host "Salida de laboratorio: $OutputDir"
