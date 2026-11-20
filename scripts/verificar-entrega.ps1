# verificar-entrega.ps1
# La lista de verificacion de la entrega (docs/10-checklist-entrega.md), automatizada: clona el repositorio
# (lo COMMITEADO, no la copia de trabajo) en una carpeta temporal y comprueba lo que se puede comprobar.
#
#   powershell -ExecutionPolicy Bypass -File scripts/verificar-entrega.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/verificar-entrega.ps1 -Swipl "D:\pl\bin\swipl.exe"
#
# Sale con codigo 0 si todo pasa y 1 si algo falla. Solo ASCII a proposito (PowerShell 5.1 lee mal los acentos).

param(
    [string]$Swipl = "C:\Program Files\pl\bin\swipl.exe",
    [string]$Repo = (git rev-parse --show-toplevel)
)

$fallos = 0
function Comprobar([string]$nombre, [bool]$ok, [string]$detalle = "") {
    if ($ok) { Write-Host ("  [ok]  " + $nombre) }
    else { Write-Host ("  [FALLA] " + $nombre + $(if ($detalle) { " -> " + $detalle } else { "" })); $script:fallos++ }
}
function Aviso([string]$texto) { Write-Host ("  [aviso] " + $texto) }

if (-not (Test-Path $Swipl)) { Write-Host "No encuentro swipl en $Swipl (usa -Swipl)"; exit 1 }

$tmp = Join-Path $env:TEMP ("chapuza-verif-" + [guid]::NewGuid().ToString("N"))
Write-Host "Clonando $Repo en $tmp ..."
git clone -q $Repo $tmp
if ($LASTEXITCODE -ne 0) { Write-Host "No se pudo clonar"; exit 1 }
Push-Location $tmp
$vacio = Join-Path $tmp "entrada-vacia.txt"
New-Item -ItemType File -Path $vacio -Force | Out-Null

function Ejecutar([string[]]$argumentos, [string]$entrada) {
    $salida = Join-Path $tmp ("salida-" + [guid]::NewGuid().ToString("N") + ".txt")
    $error_ = $salida + ".err"
    $p = Start-Process -FilePath $Swipl -ArgumentList $argumentos -WorkingDirectory $tmp -NoNewWindow -Wait -PassThru `
        -RedirectStandardInput $entrada -RedirectStandardOutput $salida -RedirectStandardError $error_
    $texto = (Get-Content $salida -Raw -ErrorAction SilentlyContinue) + (Get-Content $error_ -Raw -ErrorAction SilentlyContinue)
    return @{ Codigo = $p.ExitCode; Texto = $texto }
}

Write-Host "`n== Estado del repositorio"
$sucio = git -C $Repo status --porcelain
Comprobar "la copia de trabajo no tiene cambios sin commitear" (-not $sucio) ($sucio -join "; ")
$ultimo = git -C $Repo log -1 --format="%h %s"
Write-Host "  ultimo commit: $ultimo"

Write-Host "`n== Clon limpio: el juego arranca"
$entrada = Join-Path $tmp "entrada-juego.txt"
Set-Content -Path $entrada -Value "mirar.`r`nsalir." -Encoding ASCII
$r = Ejecutar @("-q", "-s", "src/main", "-g", "main", "-t", "halt") $entrada
Comprobar "swipl src/main arranca y termina con 'salir.'" ($r.Codigo -eq 0 -and $r.Texto -match "Hasta la pr") ("codigo " + $r.Codigo)

Write-Host "`n== Clon limpio: todas las pruebas"
$r = Ejecutar @("-q", "-s", "tests/todas", "-g", "run_tests,halt", "-t", "halt(1)") $vacio
$resumen = ($r.Texto -split "`n" | Where-Object { $_ -match "suites en verde" } | Select-Object -First 1)
Comprobar "tests/todas termina con codigo 0 y TODO EN VERDE" ($r.Codigo -eq 0 -and $r.Texto -match "TODO EN VERDE") ("codigo " + $r.Codigo)
Write-Host ("  " + $resumen)
$real = [regex]::Match($r.Texto, '(\d+) suites en verde, \d+ con fallos; (\d+) pruebas declaradas')
$doc = [regex]::Match((Get-Content (Join-Path $tmp "README.md") -Raw), '\((\d+) suites, (\d+) pruebas\)')
$coinciden = $real.Success -and $doc.Success -and ($real.Groups[1].Value -eq $doc.Groups[1].Value) -and ($real.Groups[2].Value -eq $doc.Groups[2].Value)
Comprobar "las cifras del README (suites y pruebas) coinciden con las reales" $coinciden ("README: " + $doc.Value + " / real: " + $real.Value)

Write-Host "`n== Reglas de codigo"
$fuentes = Get-ChildItem -Path (Join-Path $tmp "src") -Filter *.pl
$fuera = $fuentes | Where-Object { $_.Name -ne "estado.pl" } |
    Select-String -Pattern '\b(assert|asserta|assertz|retract|retractall)\('
Comprobar "assert/retract solo en src/estado.pl" (-not $fuera) (($fuera | ForEach-Object { $_.Filename + ":" + $_.LineNumber }) -join ", ")
$prohibidas = $fuentes | Select-String -Pattern '>>|foldl\(|sum_list\(|max_member\(|random_between\(|random_member\(|split_string\(|atom_string\('
Comprobar "ninguna funcion inexistente en SWI-Prolog 5.10.4" (-not $prohibidas) (($prohibidas | ForEach-Object { $_.Filename + ":" + $_.LineNumber }) -join ", ")

Write-Host "`n== Historial y archivos"
$autores = git log --format=%an | Sort-Object -Unique
Comprobar "un unico autor en el historial" (@($autores).Count -eq 1) ($autores -join ", ")
$p1 = "co-" + "authored"; $p2 = "generated " + "with"; $p3 = "cla" + "ude"; $p4 = "anthr" + "opic"
$mensajes = git log --format=%B | Select-String -Pattern "(?i)$p1|$p2|$p3|$p4"
Comprobar "mensajes de commit sin coautorias ni atribuciones de herramientas" (-not $mensajes)
$archivos = git ls-files | Where-Object { $_ -ne "scripts/verificar-entrega.ps1" } |
    ForEach-Object { Select-String -Path (Join-Path $tmp $_) -Pattern "(?i)$p3|$p4" -ErrorAction SilentlyContinue }
Comprobar "ningun archivo del repositorio menciona herramientas de IA" (-not $archivos) (($archivos | ForEach-Object { $_.Filename }) -join ", ")
$sobrantes = git ls-files | Where-Object { $_ -match '\.qlf$|\.bak$|^out/|^saves/|\.zip$|\.log$|~$' }
Comprobar "sin archivos sobrantes (.qlf, .bak, out/, saves/, .zip, .log)" (-not $sobrantes) ($sobrantes -join ", ")

Write-Host "`n== Demostracion reproducible"
$r = Ejecutar @("-q", "-s", "examples/generar", "-g", "generar", "-t", "halt") $vacio
$cambios = git status --porcelain | Where-Object { $_ -notmatch "entrada-|salida-" }
Comprobar "regenerar examples/ da exactamente lo guardado (byte a byte)" (-not $cambios) ($cambios -join "; ")

Write-Host "`n== Etiquetas (informativo)"
$etiquetas = git -C $Repo tag
if ($etiquetas) { Write-Host ("  etiquetas: " + ($etiquetas -join ", ")) } else { Aviso "todavia no hay etiquetas (v0.1-diseno, v0.5-motor, v0.9-jugable, v1.0-rc1, v1.0-entrega)" }

Pop-Location
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Write-Host ""
if ($fallos -eq 0) { Write-Host "TODO CORRECTO: la parte automatica de la lista de verificacion pasa."; exit 0 }
else { Write-Host ("FALLAN " + $fallos + " comprobaciones."); exit 1 }
