--!strict
--[[
	Minotauro/Posturas/Tipos

	Lo que comparten las posturas de la rutina (Minotauro/Posturas):
		Ctx       la etapa y la semilla de esta vez (la misma en todos los clientes:
		          sale del tramo de la rutina), para elegir variantes
		Event     un momento con sonido o efecto (at: avance 0..1)
		Leave     cómo sale si lo interrumpen (darle de comer manda): dura seconds,
		          pose(k) con k de 0 a 1 y sus propios eventos
		Behavior  una postura: dura seconds (por pace de la etapa), pose(u, ctx) es lo
		          que se suma a la pose para el avance u, events(ctx) sus momentos,
		          leave(from, ctx) la salida si la cortan en `from` (nil: se desvanece)
		          y looks si se da vuelta hacia alguien (Posturas.lookAt)
]]

local Etapas = require(script.Parent.Parent.Etapas)
local Pose = require(script.Parent.Parent.Pose)

export type Ctx = { profile: Etapas.Profile, seed: number }
export type Event = { at: number, kind: string }
export type Leave = { seconds: number, events: { Event }, pose: (k: number) -> Pose.Pose }
export type Behavior = {
	name: string,
	seconds: number,
	events: (ctx: Ctx) -> { Event },
	pose: (u: number, ctx: Ctx) -> Pose.Pose,
	leave: ((from: number, ctx: Ctx) -> Leave?)?,
	looks: boolean?,
}

return {}
