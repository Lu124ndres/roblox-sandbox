--!strict
--[[
	OrcaMotion/Tipos

	Lo que OrcaMotion comparte con quien la usa (OrcaSwim, OrcaFx): el estado que
	publica cada cuadro y lo que recibe del cuerpo del gigante.
]]

local Rig = require(script.Parent.Rig)
local Schedule = require(script.Parent.Schedule)

export type State = {
	center: Vector3, -- centro del cuerpo en el mundo
	vy: number, -- studs/s hacia arriba
	speed: number,
	yaw: number,
	height: number,
	feeding: number, -- 0..1
	breath: number, -- ciclo de respirar (0 = en la superficie)
	trick: string?, -- nombre del truco que está haciendo
	splash: number?, -- tamaño de la salpicadura del truco al cruzar el agua (1 = normal)
	hidden: boolean, -- escondida bajo el lago (descanso)
	ghost: boolean, -- es la Orca fantasma (OrcaFx le pone su toque espectral)
	voice: number, -- tono de sus llamados (etapa)
	events: { Schedule.Event }, -- lo que pasó este cuadro (OrcaFx los consume)
	rig: Rig.Rig?,
}
export type Info = { height: number, lift: number, spin: number, anger: number, inner: Model? }

return {}
