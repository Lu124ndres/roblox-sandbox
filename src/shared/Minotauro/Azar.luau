--!strict
--[[
	Minotauro/Azar

	Azar repetible: el mismo número para los mismos enteros en todos los
	clientes, sin estado y sin math.random. Solo usa operaciones enteras de 32
	bits (bit32 y productos partidos en mitades de 16 bits), así no depende de
	cómo redondea cada plataforma; un seno o un producto gigante en coma
	flotante podrían dar distinto en un celular y en una PC.
		unit(a, b?)     número en [0, 1) para el par (a, b)
		pick(n, a, b?)  índice entre 1 y n
]]

local TWO32 = 4294967296

-- (a * b) mod 2^32 sin perder precisión: cada producto parcial cabe en un double.
local function mul(a: number, b: number): number
	local lo, hi = a % 65536, a // 65536
	return ((hi * b) % 65536 * 65536 + lo * b) % TWO32
end

-- Mezcla de 32 bits (la de "lowbias32"): cambia la mitad de los bits por cada bit de entrada.
local function mix(h: number): number
	h = bit32.bxor(h, bit32.rshift(h, 16))
	h = mul(h, 0x7feb352d)
	h = bit32.bxor(h, bit32.rshift(h, 15))
	h = mul(h, 0x846ca68b)
	return bit32.bxor(h, bit32.rshift(h, 16))
end

local Azar = {}

function Azar.unit(a: number, b: number?): number
	local h = mix(math.floor(a) % TWO32)
	h = mix(bit32.bxor(h, math.floor(b or 0) % TWO32 + 0x9e3779b9))
	return h / TWO32
end

function Azar.pick(n: number, a: number, b: number?): number
	return math.min(n, math.floor(Azar.unit(a, b) * n) + 1)
end

return table.freeze(Azar)
