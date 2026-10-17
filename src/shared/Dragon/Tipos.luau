--!strict
--[[
	Dragon/Tipos

	Tipos del dragón y su estado inicial (aparte para que init no pase de 200
	líneas). state.events: lo que Dragon.Fx convierte en sonido y efectos:
		flap      aletazo fuerte (picada al recuperarse, brinco)
		whoosh    el aire al pasar rápido (picada, voltereta)
		roar      rugido (truco, posado al cielo, al evolucionar y al festejar)
		fire      empieza el fuego del truco en el aire (hacia la lava)
		fireSky   empieza el fuego hacia el cielo (posado o festejando)
		land      toca la roca (al posarse y al caer del brinco)
		fold      pliega las alas sobre el lomo ya posado
		takeoff   el salto al despegar (con el aletazo hacia abajo)
		stretch   se estira con las alas arriba
		preen     empieza a mordisquearse el ala
		sleep     termina de enroscarse para dormir
		wake      despierta
		evolve    empieza a evolucionar (el estallido es 1.3 s después)
	Al comer (Dragon/Comer):
		chomp     muerde el pez; gulp lo traga; savor resopla de gusto
		dedicate  le dedica el gesto al jugador de este cliente
		treat     un pez raro: chispas de su color; treatFlare, su llamarada
		joy       vuelta o aletazo de alegría (estelas); cheer, su grito
		fireRing  anillo de fuego alrededor; feast, lluvia de chispas doradas
	Fed: lo que llega con cada pez (como client/Giant/FedInfo).
]]

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
export type Fed = {
	from: Vector3, -- de dónde vino (quien lo alimentó)
	fishId: string,
	rarity: number, -- 1 = común; más alto = más raro
	isLocal: boolean, -- lo dio el jugador de este cliente
	streak: number, -- peces seguidos
}
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	mouth: () -> Vector3,
	top: () -> Vector3,
	water: () -> Vector3,
	point: (name: string) -> Vector3?,
	bite: () -> (),
	fed: (info: Fed) -> (), -- le llegó un pez: su animación especial (Dragon/Comer)
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
