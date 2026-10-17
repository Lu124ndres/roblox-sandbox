--!strict
--[[
	Minotauro/Trucos

	Los trucos del minotauro. Su rutina (Minotauro/Rutina) elige cuándo hace uno
	y cuál de los de su etapa (Minotauro/Etapas: tricks), con la hora del servidor:
	todos los ven a la vez. pose(u) da, para el avance u (0..1), lo que se suma a
	su pose (Minotauro/Pose). Uno por módulo, armados con Curvas y con los
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

-- El truco con ese nombre (los de Etapas.tricks); nil si no existe.
function Trucos.get(name: string): Trick?
	return TRICKS[name]
end

return table.freeze(Trucos)
