--!strict
--[[
	Minotauro/Comer/Elegir

	Qué reacción toca (Minotauro/Comer decide cuándo):
		milestone(streak)  cuántos combos lleva la racha: a los 5, 15 y 30 peces
		                   seguidos y después cada 25 (55, 80...)
		party(k)           el festejo del combo k: tambor, puño, victoria y después
		                   puño y victoria alternados
		rare(rarity)       el gusto del pez raro: brillo (raro), alegría (épico),
		                   dorado (legendario y mítico)
		bite(turn, angle)  el bocado de un pez común. Alterna para que muchos peces
		                   seguidos no se vean iguales: uno de cada tres traga y se
		                   palmea la panza o se sacude de gusto; los otros lo atrapa
		                   con las manos si viene de un costado (o uno de cada cuatro,
		                   para variar) y si no, con la boca
		side(angle, turn)  hacia qué lado lo hace (+1 su izquierda, -1 su derecha): el
		                   del pez o, si vino de frente, uno y otro alternados
	angle: desde dónde vino el pez respecto de adonde mira (rad, + a su izquierda).
]]

local Bocados = require(script.Parent.Bocados)
local Festejos = require(script.Parent.Festejos)
local Gustos = require(script.Parent.Gustos)
local Tipos = require(script.Parent.Tipos)

local MILESTONES = { 5, 15, 30 }
local EVERY = 25 -- después del último, un combo más cada tantos peces
local SIDE_ANGLE = 0.35 -- rad: más de esto a un costado, lo atrapa con las manos
local FRONT = 0.1 -- rad: menos que esto, vino de frente
local RARE = 3 -- índice de rareza desde el que es "raro" (Config: Raro)

local Elegir = {}

Elegir.RARE = RARE

function Elegir.milestone(streak: number): number
	local last = MILESTONES[#MILESTONES]
	if streak >= last then
		return #MILESTONES + math.floor((streak - last) / EVERY)
	end
	local reached = 0
	for index, value in MILESTONES do
		if streak >= value then
			reached = index
		end
	end
	return reached
end

function Elegir.party(k: number): Tipos.Move
	if k <= 1 then
		return Festejos.tambor
	elseif k == 2 then
		return Festejos.puno
	end
	return if k % 2 == 1 then Festejos.victoria else Festejos.puno
end

function Elegir.rare(rarity: number): Tipos.Move
	if rarity >= RARE + 2 then
		return Gustos.dorado
	elseif rarity == RARE + 1 then
		return Gustos.alegria
	end
	return Gustos.brillo
end

function Elegir.bite(turn: number, angle: number): Tipos.Move
	if turn % 3 == 0 then
		return if turn % 6 == 0 then Bocados.gusto else Bocados.panza
	elseif math.abs(angle) > SIDE_ANGLE or turn % 4 == 1 then
		return Bocados.manos
	end
	return Bocados.atrapa
end

function Elegir.side(angle: number, turn: number): number
	if math.abs(angle) < FRONT then
		return if turn % 2 == 0 then 1 else -1
	end
	return if angle < 0 then -1 else 1
end

return table.freeze(Elegir)
