--!strict
-- Tipos del dragón y su estado inicial (aparte para que init no pase de 200 líneas).

local Rig = require(script.Parent.Rig)

export type Event = { kind: string }
export type State = {
	center: Vector3,
	velocity: Vector3,
	yaw: number,
	length: number, -- largo del dragón en studs
	feeding: number,
	fire: boolean,
	phase: number, -- fase del aleteo (rad): DragonFx suena cada aletazo
	fold: number, -- 0..1 alas plegadas (picada): estelas en las puntas
	hidden: boolean,
	voice: number,
	fireSize: number,
	events: { Event },
	rig: Rig.Rig?,
	perched: number, -- 0 volando .. 1 de pie en una roca
	mode: string, -- tramo de la rutina: fly, approach, stay, takeoff (o evolve)
}
export type Info = { height: number, lift: number, spin: number, anger: number, inner: Model? }
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	mouth: () -> Vector3,
	top: () -> Vector3,
	water: () -> Vector3,
	point: (name: string) -> Vector3?,
	bite: () -> (),
	destroy: () -> (),
}

local Tipos = {}

function Tipos.newState(center: Vector3): State
	return {
		center = center,
		velocity = Vector3.zero,
		yaw = 0,
		length = 10,
		feeding = 0,
		fire = false,
		phase = 0,
		fold = 0,
		hidden = false,
		voice = 1,
		fireSize = 1,
		events = {},
		rig = nil,
		perched = 0,
		mode = "fly",
	}
end

return table.freeze(Tipos)
