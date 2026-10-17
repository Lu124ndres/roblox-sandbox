--!strict
--[[
	Dragon/Posturas/Tipos

	Lo que comparten las posturas del dragón posado (Dragon/Posturas):
		Ctx       la etapa, la semilla de esta vez (la misma en todos los clientes:
		          sale de la vuelta de la rutina) para elegir variantes (de qué
		          lado se acicala o se enrosca) y cuánto dura de verdad (seconds:
		          dormir dura lo que quede de la estadía)
		Event     un momento con sonido o efecto (at: avance 0..1)
		Behavior  una postura: dura seconds (por el pace de la etapa), pose(u, ctx)
		          es lo que se suma a la pose del dragón posado para el avance u y
		          events(ctx) sus momentos
]]

local Etapas = require(script.Parent.Parent.Etapas)

export type Pose = { [string]: number }
export type Ctx = { profile: Etapas.Profile, seed: number, seconds: number }
export type Event = { at: number, kind: string }
export type Behavior = {
	name: string,
	seconds: number,
	events: (ctx: Ctx) -> { Event },
	pose: (u: number, ctx: Ctx) -> Pose,
}

return {}
