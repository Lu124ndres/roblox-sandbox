--!strict
--[[
	OrcaMotion/Comer/Azar

	Azar sin estado para la comida de la orca: el mismo número da el mismo
	resultado en todos los clientes (que reciben los mismos peces en el mismo
	orden), sin math.random.
]]

local Azar = {}

-- Un número entre 0 y 1 que parece al azar, siempre el mismo para `n`.
function Azar.hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

-- Elige de `list` por peso con el número `n` (nil si la lista está vacía o
-- todo pesa 0). `skip` se salta (para no repetir el anterior).
function Azar.pick<T>(n: number, list: { T }, weightOf: (T) -> number, skip: T?): T?
	local total = 0
	for _, entry in list do
		if entry ~= skip then
			total += weightOf(entry)
		end
	end
	if total <= 0 then
		return nil
	end
	local roll, last = Azar.hash(n) * total, nil
	for _, entry in list do
		if entry ~= skip then
			roll -= weightOf(entry)
			last = entry
			if roll <= 0 then
				return entry
			end
		end
	end
	return last -- por redondeo: el último que contaba
end

return table.freeze(Azar)
