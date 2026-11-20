# barrido.ps1
# Barrido de parametros de balance: para cada VARIANTE copia el juego a una carpeta temporal, cambia unos
# numeros del texto de src/ (sin tocar el repositorio) y ejecuta el simulador sobre la copia.
#
# Uso (desde la raiz del repositorio):
#   powershell -ExecutionPolicy Bypass -File herramientas/barrido.ps1 [-Partidas 100] [-Semilla 1]
#
# Cada variante es: nombre, y una lista de cambios @(archivo, texto_viejo, texto_nuevo). Se muestra por politica
# el numero de victorias, derrotas por hambre, y los dias y el queso final de las partidas ganadas.
param([int]$Partidas = 100, [int]$Semilla = 1, [string]$Swipl = 'C:\Program Files\pl\bin\swipl.exe')

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$variantes = [ordered]@{
    'base (9/7/14, 12 de inicio)'      = @()
    'pagos 12/12/18'                   = @(
        @('src/contratos.pl', 'quesos(9)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(7)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(14)', 'quesos(18)'))
    'pagos 12/12/16'                   = @(
        @('src/contratos.pl', 'quesos(9)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(7)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(14)', 'quesos(16)'))
    'pagos 14/12/20 (por distancia)'   = @(
        @('src/contratos.pl', 'quesos(9)',  'quesos(14)'),
        @('src/contratos.pl', 'quesos(7)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(14)', 'quesos(20)'))
    'inicio 16 quesos'                 = @(,
        @('src/mundo.pl', 'queso(cheddar, 0, 12)', 'queso(cheddar, 0, 16)'))
    'pagos 12/12/18 + inicio 16'       = @(
        @('src/contratos.pl', 'quesos(9)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(7)',  'quesos(12)'),
        @('src/contratos.pl', 'quesos(14)', 'quesos(18)'),
        @('src/mundo.pl', 'queso(cheddar, 0, 12)', 'queso(cheddar, 0, 16)'))
}

foreach ($nombre in $variantes.Keys) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('barrido-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        foreach ($d in 'src', 'herramientas', 'examples') {
            Copy-Item (Join-Path $raiz $d) (Join-Path $tmp $d) -Recurse
        }
        foreach ($c in $variantes[$nombre]) {
            $f = Join-Path $tmp $c[0]
            $t = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)
            if (-not $t.Contains($c[1])) { throw "No aplica el cambio '$($c[1])' en $($c[0])" }
            [IO.File]::WriteAllText($f, $t.Replace($c[1], $c[2]), (New-Object Text.UTF8Encoding($false)))
        }
        Write-Host "=== $nombre"
        Push-Location $tmp
        try {
            $null | & $Swipl -q -s herramientas/simulador -g "informe($Partidas, $Semilla)" -t halt 2>&1 |
                Where-Object { $_ -match '^(REF|POLITICA|PARTIDAS|GANADAS)' } | ForEach-Object { Write-Host "  $_" }
        } finally { Pop-Location }
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
