#!/usr/bin/env bash
# Respaldo del lugar de Studio (los modelos de los monstruos, trajes y props solo viven en
# el .rbxl, no en git). Copia el .rbxl a una carpeta fuera del repo con fecha y hora y deja
# solo los últimos 20 respaldos.
#
# Uso (desde Git Bash, en la raíz del repo, después de guardar en Studio con Ctrl+S):
#     bash tools/respaldo_rbxl.sh
#     bash tools/respaldo_rbxl.sh otro_lugar.rbxl        # otro archivo
# Carpeta de destino: $RESPALDO_DIR, o ~/RespaldosJuegoRoblox si no está definida
# (en Windows: C:\Users\<usuario>\RespaldosJuegoRoblox).
set -euo pipefail

ORIGEN="${1:-PescaYAlimentaGigantes.rbxl}"
DESTINO="${RESPALDO_DIR:-$HOME/RespaldosJuegoRoblox}"
CONSERVAR=20

if [ ! -f "$ORIGEN" ]; then
	echo "No encuentro '$ORIGEN'. Corre el script desde la raíz del repo o pasa la ruta del .rbxl." >&2
	exit 1
fi

mkdir -p "$DESTINO"
base="$(basename "$ORIGEN" .rbxl)"
copia="$DESTINO/${base}_$(date +%Y-%m-%d_%H-%M-%S).rbxl"
cp "$ORIGEN" "$copia"

# La copia tiene que pesar lo mismo que el original (Studio pudo estar escribiendo).
if [ "$(wc -c < "$ORIGEN")" -ne "$(wc -c < "$copia")" ]; then
	echo "La copia no pesa lo mismo que el original: ¿Studio estaba guardando? Vuelve a correrlo." >&2
	rm -f "$copia"
	exit 1
fi
echo "Respaldo: $copia ($(du -h "$copia" | cut -f1))"

# Deja solo los últimos $CONSERVAR respaldos de este lugar. El orden sale del nombre
# (AAAA-MM-DD_HH-MM-SS), no de la fecha del archivo, que puede venir del original.
mapfile -t viejos < <(ls -1 "$DESTINO/${base}_"*.rbxl 2>/dev/null | sort -r | tail -n +$((CONSERVAR + 1)))
for viejo in "${viejos[@]}"; do
	rm -f "$viejo"
	echo "Borrado (más de $CONSERVAR): $(basename "$viejo")"
done
