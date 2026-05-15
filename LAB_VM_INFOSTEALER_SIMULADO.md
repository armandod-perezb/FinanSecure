# Laboratorio VM: Simulacion Defensiva de InfoStealer

Este laboratorio permite evidenciar comportamiento tipo InfoStealer sin malware real.

## 1) Objetivo

- Simular una cadena basica de comportamiento:
  - Acceso a archivo "sensible" (decoy)
  - Enumeracion de rutas de navegador
  - Preparacion de datos ficticios
  - Intento de conexion saliente sospechosa
- Generar evidencia util para SIEM/EDR/Firewall.

## 2) Requisitos

- VM Windows (idealmente con snapshot previo).
- PowerShell 5.1 o superior.
- Sysmon recomendado para telemetria de procesos/archivos/red.
- EDR o agente de logs (opcional pero recomendado).

## 3) Topologia recomendada (3 VMs)

### VM1: Kali Linux (simulacion de atacante)

- Rol: originar phishing simulado y pruebas de conectividad.
- IP sugerida: `192.168.56.10`
- Herramientas: Python3, navegador, utilidades de red basicas.

### VM2: Windows 10 (victima)

- Rol: usuario final que abre pagina falsa y ejecuta `infostealer_simulator.ps1`.
- IP sugerida: `192.168.56.20`
- Requisitos: Sysmon + agente SIEM/EDR.

### VM3: Windows Server (defensa)

- Rol: SIEM/collector + opcional AD/DNS.
- IP sugerida: `192.168.56.30`
- Requisitos: plataforma de monitoreo (Wazuh/Splunk/Elastic) y recepcion de logs.

Red sugerida:

- Todas las VMs en una red host-only o red interna de laboratorio.
- Sin salida a Internet para reducir riesgo.
- Sin puentes a red productiva.

## 4) Ejecucion

Desde la carpeta del proyecto:

```powershell
powershell -ExecutionPolicy Bypass -File .\infostealer_simulator.ps1 -OutputDir .\lab-output -VerboseMode
```

## 5) Flujo de prueba con 3 VMs

1. En Kali, prepara el "origen de phishing" simulado (correo o mensaje de prueba con URL interna).
2. En Windows Server, valida que el SIEM/collector este recibiendo eventos de Win10.
3. En Windows 10, abre la pagina falsa del proyecto y sigue el flujo academico.
4. En Windows 10, ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File .\infostealer_simulator.ps1 -OutputDir .\lab-output -VerboseMode
```

5. En Windows Server, verifica correlacion:
- Proceso PowerShell.
- Eventos de archivos `lab-output`.
- Intento de conexion a `198.51.100.10:443`.

## 6) Comandos minimos por VM (orden sugerido)

1. Kali Linux (`192.168.56.10`) - simular sitio phishing interno

```bash
cd /ruta/del/proyecto/FinanSecure
python3 -m http.server 8080
```

URL de prueba para la victima:
- `http://192.168.56.10:8080/index.html`

2. Windows Server (`192.168.56.30`) - validar recepcion de telemetria

```powershell
Get-Date
```

Checklist rapido en SIEM:
- Host Win10 reportando.
- Eventos de proceso habilitados.
- Eventos de archivo habilitados.
- Eventos de red habilitados.

3. Windows 10 (`192.168.56.20`) - ejecutar simulacion

```powershell
cd C:\Users\arman\Documents\FinanSecure
powershell -ExecutionPolicy Bypass -File .\infostealer_simulator.ps1 -OutputDir .\lab-output -VerboseMode
```

4. Windows 10 (`192.168.56.20`) - validar artefactos locales

```powershell
Get-ChildItem .\lab-output -Recurse
Get-Content .\lab-output\simulation_summary.txt
```

5. Windows Server (`192.168.56.30`) - aplicar reglas Sigma

- Cargar `.\sigma_infostealer_simulation.yml` en tu pipeline de reglas.
- Buscar coincidencias del host Win10 en ventana de tiempo de la prueba.

## 7) Evidencia esperada

Archivos generados:

- `.\lab-output\infostealer_simulation.log`
- `.\lab-output\simulation_summary.txt`
- `.\lab-output\staged_bundle.txt`
- `.\lab-output\decoy-data\decoy_credentials.txt`

Eventos/indicadores que deberias observar:

- Proceso `powershell.exe` ejecutando script con argumentos.
- Lectura/escritura de archivos en `lab-output`.
- Consulta de rutas de perfiles de navegador.
- Intento de conexion TCP saliente a `198.51.100.10:443` (IP de pruebas RFC5737).

## 8) Mapeo de deteccion (orientativo)

- T1059.001: PowerShell
- T1083: File and Directory Discovery
- T1555: Credentials from Password Stores (simulado, sin acceso real)
- T1041: Exfiltration Over C2 Channel (simulado por intento de conexion)

Reglas Sigma incluidas en el proyecto:

- `.\sigma_infostealer_simulation.yml`

## 9) Como presentar resultados

- Captura 1: consola ejecutando el script.
- Captura 2: contenido de `simulation_summary.txt`.
- Captura 3: logs SIEM/EDR con proceso + archivo + red correlacionados.
- Captura 4: alerta de firewall/EDR por actividad anomala.
 - Captura 5: evidencia del origen simulado desde Kali (mensaje/URL/log HTTP interno).

## 10) Conversion Sigma para SIEM

Ejemplo con `sigmac` (si lo usas en tu entorno SOC):

```bash
sigmac -t splunk .\sigma_infostealer_simulation.yml
sigmac -t es-qs .\sigma_infostealer_simulation.yml
```

Si no usas `sigmac`, toma las reglas como plantilla y adapta los campos a tu fuente:

- Sysmon Event ID 1 para `process_creation`
- Sysmon Event ID 11 para `file_event`
- Sysmon Event ID 3 para `network_connection`

## 11) Limpieza del laboratorio

```powershell
Remove-Item -Recurse -Force .\lab-output
```

Nota: este simulador no roba datos, no persiste en el sistema y no instala componentes maliciosos.
