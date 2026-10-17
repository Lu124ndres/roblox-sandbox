--!strict
--[[
	Etapas/Perfil

	Lo que define la forma de moverse de cada etapa de la orca (un script por
	etapa: OrcaBebe, OrcaJoven, OrcaAdulta, OrcaAnciana). OrcaMotion lo lee
	cada cuadro, así que al crecer cambia de carácter sin cortes.
]]

local Tricks = require(script.Parent.Parent.OrcaMotion.Tricks)

export type Swim = {
	speed: number, -- multiplica la velocidad de crucero
	beat: number, -- aleteos por segundo a velocidad de crucero
	amplitude: number, -- qué tan ancha es la onda de la cola
	glide: number, -- 0..1: cuánto planea entre series de aletazos
	wiggle: number, -- bamboleo de lado (juguetona)
	bank: number, -- cuánto se inclina en las curvas
	flap: number, -- aleteo de las pectorales
}
export type Breath = {
	seconds: number, -- cada cuánto sale a respirar
	shallow: number, -- altura del centro al respirar (altos, negativa = bajo el agua)
	deep: number, -- y en lo más hondo del ciclo
}
export type Feed = {
	pitch: number, -- cuánto levanta la cabeza al comer (rad)
	rise: number, -- altura del centro sobre el agua al comer (altos)
	jaw: number, -- qué tan abierta tiene la boca (0..1.2)
	chew: number, -- mordiscos por segundo (sin peces llegando)
	wiggle: number, -- bamboleo de contenta al comer
}
export type Entry = { weight: number, trick: Tricks.Trick }
export type Gesture = { weight: number, name: string } -- nombre en Comer/Gestos
export type Meal = {
	tempo: number, -- multiplica la duración de los gestos (1 = la adulta)
	snap: number, -- fuerza del mordisco hacia arriba con cada pez
	roll: number, -- amplitud de los giros de costado
	hz: number, -- resorte de los gestos: qué tan rápido responde
	damping: number, -- y cuánto rebota (menos = más rebote)
	gap: number, -- segundos entre gestos de gusto
	gestures: { Gesture },
	rare: Tricks.Trick, -- con un pez raro
	party: { Tricks.Trick }, -- festejos de combo en orden (el primero de la racha, el segundo, el tercero y siguientes)
}
export type Profile = {
	name: string,
	voice: number, -- tono de sus llamados (1 = normal, más alto = más aguda)
	swim: Swim,
	breath: Breath,
	feed: Feed,
	trickEvery: number, -- tramo en segundos en que puede hacer un truco
	trickChance: number, -- probabilidad de truco en cada tramo
	tricks: { Entry },
	meal: Meal,
}

return {}
