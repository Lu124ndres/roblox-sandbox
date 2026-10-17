--!strict
--[[
	Dragon/Posturas

	Lo que el dragón hace posado en una roca (Dragon/Rutina elige cuál y
	cuándo), una postura por módulo, con los principios de
	docs/estilo_modelos.md (anticipación, aplastarse y estirarse con la pose,
	arcos, rebote al llegar, más lento cuanto más grande):
		mirar        mira a un lado y al otro, ladeando la cabeza
		estirarse    se encoge y estira las dos alas bien arriba con un bostezo
		acicalarse   gira la cabeza hacia un costado y se mordisquea el ala
		rugir        baja la cabeza, se echa atrás y ruge al cielo
		fuegoCielo   toma aire y echa fuego hacia arriba
		brinco       se agacha y da un saltito en la roca (la cría)
		dormir       se enrosca (sobre todo en el nido), duerme y despierta
	Además, fuera de la lista: posarse (el asiento después de tocar la roca),
	aterrizar (la bajada y el frenado) y despegar (Dragon/Posturas/Vuelo).
	base() es la pose de estar posado: de pie, alas plegadas, respirando y
	mirando alrededor despacio; las posturas se suman encima.
]]

local Tipos = require(script.Tipos)

export type Behavior = Tipos.Behavior
export type Ctx = Tipos.Ctx
export type Event = Tipos.Event
export type Pose = Tipos.Pose

local POSTURAS: { [string]: Behavior } = {
	mirar = require(script.Mirar),
	estirarse = require(script.Estirarse),
	acicalarse = require(script.Acicalarse),
	rugir = require(script.Rugir),
	fuegoCielo = require(script.FuegoCielo),
	brinco = require(script.Brinco),
	dormir = require(script.Dormir),
	posarse = require(script.Posarse),
}

local Posturas = {}

function Posturas.get(name: string): Behavior?
	return POSTURAS[name]
end

-- De pie en la roca: respira (el pecho sube y baja), mira alrededor despacio y
-- la cola cuelga por el borde (Posado no la deja meterse en la roca).
function Posturas.base(now: number, breathe: number): Pose
	local tau = 2 * math.pi
	return {
		legs = 1,
		tuck = 1,
		tailDroop = 1.3,
		calm = 0.6,
		neck = 0.2,
		chest = 0.04 * math.sin(now * tau / breathe),
		look = 0.35 * math.sin(now * tau / 11) + 0.15 * math.sin(now * tau / 4.3),
		head = 0.06 * math.sin(now * tau / 6.1),
		tilt = 0.08 * math.sin(now * tau / 7.7),
	}
end

return table.freeze(Posturas)
