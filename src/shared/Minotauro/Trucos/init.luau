--!strict
--[[
	Minotauro/Trucos

	Los trucos del minotauro, sincronizados por la hora del servidor (todos los
	ven a la vez): cada trickEvery segundos de la etapa (Minotauro/Etapas) puede
	empezar uno de los suyos. pose(u) da, para el avance u (0..1), lo que se suma
	a su pose (Minotauro/Pose). Uno por módulo, armados con Curvas y con los
	principios de docs/estilo_modelos.md (anticipación, aplastarse y estirarse con
	la pose, arcos, rebote al llegar); orejas, cola y faldón los mueve Resortes:
		pisoton   levanta una pata y la estampa: ola y temblor
		rugido    toma aire, se echa atrás y ruge con la boca abierta
		musculo   saca músculo y bombea un brazo y el otro
		baile     se mece, cabecea y mueve los brazos en círculos
		rascarse  se rasca la cabeza y golpetea el pie de gusto
		salto     se agacha, salta y cae aplastándose; al caer, salpica
	events: momentos con sonido o efecto (stomp, roar, flex, happy, land).
	La etapa los hace más lentos (pace): la forma final tarda más en todo.
]]

local Etapas = require(script.Parent.Etapas)
local Pose = require(script.Parent.Pose)

export type Trick = {
	name: string,
	seconds: number,
	events: { { at: number, kind: string } },
	pose: (u: number) -> Pose.Pose,
}

local TRICKS: { [string]: Trick } = {
	pisoton = require(script.Pisoton),
	rugido = require(script.Rugido),
	musculo = require(script.Musculo),
	baile = require(script.Baile),
	rascarse = require(script.Rascarse),
	salto = require(script.Salto),
}

local Trucos = {}

-- Truco que está haciendo ahora (o nil), su avance 0..1 y el tramo (para los eventos).
function Trucos.current(now: number, profile: Etapas.Profile): (Trick?, number, number)
	local every = profile.trickEvery
	local slot = math.floor(now / every)
	local hash = (slot * 2654435761) % 1000 / 1000
	if hash < 0.2 then
		return nil, 0, slot -- este tramo sin truco
	end
	local trick = TRICKS[profile.tricks[slot % #profile.tricks + 1]]
	local u = (now - slot * every - every * 0.3) / (trick.seconds * profile.pace)
	if u < 0 or u > 1 then
		return nil, 0, slot
	end
	return trick, u, slot
end

return table.freeze(Trucos)
