--!strict
--[[
	Zorro/Comer/Elegir

	Qué reacción le toca a cada pez, según la etapa (cada una come a su manera):
		bocado   el ciclo de la etapa (alterna para no repetir); tras una pausa, el
		         de la pausa; con una reacción grande en curso, el más corto
		           E1 cría       juega: atrapa, zarpazo, sacude; tras una pausa salta
		                         (brinco) o salta torpe y se le escapa (torpe)
		           E2 joven      atrapa, zarpazo, atrapa, sacude; tras una pausa, brinco
		           E3 adulto     atrapa, sacude, atrapa, zarpazo; tras una pausa, brinco
		           E4 forma final calma (con peso), atrapa, calma, sacude; nunca salta
		grande   pez raro: pirueta (raro) o salto mortal (épico o más); la forma
		         final, su majestad
		festejo  la racha: a los 5 persigue su cola (cría y joven) o se luce (adulto
		         y forma final); a los 15 la carrera (la forma final, la ola); a los
		         30 el gran festejo
	La pausa del torpe es más larga que la del brinco: si los peces llegan seguidos,
	el próximo lo fundiría antes de que lo termine.
]]

local Bocados = require(script.Parent.Bocados)
local Clip = require(script.Parent.Clip)
local Cria = require(script.Parent.Cria)
local Festejos = require(script.Parent.Festejos)
local Final = require(script.Parent.Final)
local Grandes = require(script.Parent.Grandes)

local CYCLES = {
	{ "atrapa", "zarpazo", "atrapa", "sacude", "zarpazo" },
	{ "atrapa", "zarpazo", "atrapa", "sacude" },
	{ "atrapa", "sacude", "atrapa", "zarpazo" },
	{ "calma", "atrapa", "calma", "sacude" },
}
local PAUSE = 1.5 -- s sin comer: el próximo pez es el de la pausa
local CLUMSY_PAUSE = 2.2 -- s sin comer: la cría puede saltar torpe
local RARE_SPIN, RARE_FLIP = 3, 4 -- rareza (índice) de la pirueta y del mortal

local SMALL: { [string]: Clip.Clip } = table.clone(Bocados)
SMALL.torpe = Cria.torpe
SMALL.calma = Final.calma

local Elegir = {}

Elegir.RARE = RARE_SPIN
Elegir.relamer = Bocados.relamer

-- count: peces comidos; since: s desde el pez anterior; busy: hay una grande.
function Elegir.bocado(stage: number, count: number, since: number, busy: boolean): Clip.Clip
	local cycle = CYCLES[stage] or CYCLES[1]
	local name = cycle[count % #cycle + 1]
	if busy then
		name = if stage >= 4 then "calma" else "atrapa"
	elseif stage == 1 and since > CLUMSY_PAUSE and count % 2 == 0 then
		name = "torpe" -- a veces se le escapa
	elseif since > PAUSE then
		name = if stage >= 4 then "calma" else "brinco"
	end
	return SMALL[name]
end

-- La reacción grande de un pez raro (nil si no es raro).
function Elegir.grande(stage: number, rarity: number): Clip.Clip?
	if rarity < RARE_SPIN then
		return nil
	elseif stage >= 4 then
		return Final.majestad
	end
	return if rarity >= RARE_FLIP then Grandes.mortal else Grandes.pirueta
end

-- El festejo de la racha (Animo.festejo: "cola", "carrera" o "gran").
function Elegir.festejo(stage: number, party: string): Clip.Clip
	if party == "cola" then
		return if stage >= 3 then Festejos.lucirse else Festejos.cola
	elseif party == "carrera" then
		return if stage >= 4 then Final.ola else Festejos.carrera
	end
	return if stage >= 4 then Final.gran else Festejos.gran
end

return table.freeze(Elegir)
