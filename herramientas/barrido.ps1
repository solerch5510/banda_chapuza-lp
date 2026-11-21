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

$antiguo = @(
    @('src/contratos.pl', 'recompensa([quesos(pago), objeto(pocion)])',          'recompensa([quesos(9), objeto(pocion)])'),
    @('src/contratos.pl', 'recompensa([quesos(pago), objeto(venda_de_caballos)])', 'recompensa([quesos(7), objeto(venda_de_caballos)])'),
    @('src/contratos.pl', 'recompensa([quesos(pago), queso(brie, 0, 1)])',        'recompensa([quesos(14), queso(brie, 0, 1)])'))

# Cada variante cambia numeros del texto de src/. Los pagos salen de la formula de contratos:pago_de/2
# (base + por_dia * dias de ruta + por_enemigo * enemigos, con un minimo); los parametros estan en src/mundo.pl.
$rata = 'botin(rata_quesera,    1,  60).'
$variantes = [ordered]@{
    'sin botin de ratas (0 %)'            = @(,
        @('src/mundo.pl', $rata, 'botin(rata_quesera,    1,   0).'))
    'ratas 30 %'                          = @(,
        @('src/mundo.pl', $rata, 'botin(rata_quesera,    1,  30).'))
    'ratas 60 % (actual)'                 = @()
    'ratas 100 %'                         = @(,
        @('src/mundo.pl', $rata, 'botin(rata_quesera,    1, 100).'))
    'ratas 2 quesos al 60 %'              = @(,
        @('src/mundo.pl', $rata, 'botin(rata_quesera,    2,  60).'))
    'ratas 60 % y bandidos al 70 %'       = @(
        @('src/mundo.pl', 'botin(bandido_torpe,   1, 100).', 'botin(bandido_torpe,   1,  70).'),
        @('src/mundo.pl', 'botin(bandido_montado, 1, 100).', 'botin(bandido_montado, 1,  70).'))
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
