--!strict
--[[
	Dragon/Evolucion

	La pose mientras evoluciona (el servidor publica en EstadoGigante la hora en
	que termina: Protocol.GiantAttributes.EvolvingUntil; dura
	Config.Giants.cycle.evolveSeconds). Va en segundos desde que empieza porque
	el destello y el cambio de modelo (GiantEvolution, en el cliente) caen en
	BURST:
		0 .. BURST     se envuelve en las alas y se encoge (agachado, cuello y
		               cabeza abajo, la cola enroscada), sin aletear, temblando
		               cada vez más (evolve al empezar)
		BURST          abre las alas de golpe bien arriba, se estira con el pecho
		               afuera, la cabeza al cielo y la boca abierta (se pasa y vuelve)
		ROAR ..        ruge sacudiendo la cabeza (roar)
		SETTLE ..      se asienta: pliega las alas (o vuelve a aletear) y baja la
		               cabeza
	En el aire se queda quieto donde estaba (hover); posado, en la roca.
	watch() sigue el atributo y da en cada cuadro los segundos desde que empezó
	(o nil) y sus eventos; si el cliente llega tarde, no repite los que pasaron.
]]

local Config = require(script.Parent.Parent.Config)
local Protocol = require(script.Parent.Parent.Protocol)
local C = require(script.Parent.Parent.Minotauro.Trucos.Curvas)

local BURST = 1.3
local ROAR = 1.45
local SETTLE = 2.4
local SECONDS = Config.Giants.cycle.evolveSeconds
local LATE = 0.4 -- s: si lo ve empezar más tarde que esto, no suena el evolve
local EVENTS = { { at = 0, kind = "evolve" }, { at = ROAR, kind = "roar" } }

local Evolucion = {}

Evolucion.BURST = BURST

-- folder: EstadoGigante. La función devuelve t (segundos desde que empezó) o nil.
function Evolucion.watch(folder: Instance): (now: number, out: { { kind: string } }) -> number?
	local key, last = 0, 0
	return function(now: number, out: { { kind: string } }): number?
		local untilAt = folder:GetAttribute(Protocol.GiantAttributes.EvolvingUntil)
		if type(untilAt) ~= "number" or untilAt <= now then
			return nil
		end
		local t = math.max(0, SECONDS - (untilAt - now))
		if untilAt ~= key then -- empezó otra
			key, last = untilAt, if t < LATE then -1 else t
		end
		for _, event in EVENTS do
			if event.at > last and event.at <= t then
				table.insert(out, { kind = event.kind })
			end
		end
		last = t
		return t
	end
end

-- t: segundos desde que empezó.
function Evolucion.pose(t: number): { [string]: number }
	if t < 0 or t > SECONDS then
		return {}
	end
	local function span(a: number, b: number): number
		return C.span(t, a, b)
	end
	local gather = C.smooth(span(0, 0.7)) * (1 - C.easeIn(span(BURST - 0.08, BURST)))
	local tremble = math.sin(t * 80) * C.smooth(span(0.2, BURST - 0.05)) * gather
	local burst = C.overshoot(span(BURST, BURST + 0.22)) * (1 - C.smooth(span(SETTLE, SECONDS)))
	local roar = C.smooth(span(ROAR - 0.05, ROAR + 0.1)) * (1 - C.smooth(span(2.1, SETTLE)))
	local shake = math.sin(t * 45) * roar
	local open = 1 - C.smooth(span(SETTLE - 0.2, SECONDS))
	return {
		wrap = gather,
		tuck = -1 * (gather + burst * open),
		spread = 0.7 * burst + 0.04 * tremble,
		cup = -0.3 * burst,
		flap = 0.1 + 1.2 * C.smooth(span(SETTLE, SECONDS)),
		hover = 1,
		crouch = 0.8 * gather - 0.45 * burst,
		neck = -0.45 * gather + 0.7 * burst,
		head = -0.4 * gather + 0.55 * burst + 0.05 * shake,
		look = 0.06 * tremble + 0.1 * shake,
		chest = -0.15 * gather + 0.35 * burst,
		jaw = 0.1 * gather + 1.2 * burst,
		tailCurl = 1.2 * gather,
		tailUp = -0.2 * gather + 0.5 * burst,
		calm = gather,
	}
end

return table.freeze(Evolucion)
