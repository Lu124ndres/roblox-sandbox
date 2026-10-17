--!strict
--[[
	Minotauro/Evolucion

	La pose mientras evoluciona (el servidor publica en EstadoGigante la hora en
	que termina: Protocol.GiantAttributes.EvolvingUntil; dura
	Config.Giants.cycle.evolveSeconds). Va en segundos desde que empieza, no en
	avance, porque el destello y el cambio de modelo (otra parte del cliente) caen
	en BURST:
		0 .. BURST     se agacha y junta fuerza: rodillas dobladas, puños al pecho,
		               cabeza abajo, orejas atrás, temblando cada vez más (evolve)
		BURST          explota hacia arriba: piernas estiradas, brazos arriba, pecho
		               afuera, cabeza atrás y la boca abierta (se pasa y vuelve)
		ROAR ..        ruge sacudiendo la cabeza con el pecho agitado (roar)
		.. SETTLE      se asienta: baja los brazos y dobla un poco las rodillas
	Después de SECONDS la pose vale cero. watch() sigue el atributo y da, en cada
	cuadro, los segundos desde que empezó (o nil) y sus eventos: evolve al empezar
	y roar en ROAR; si el cliente llega tarde, no repite los que ya pasaron.
]]

local Config = require(script.Parent.Parent.Config)
local Protocol = require(script.Parent.Parent.Protocol)
local C = require(script.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Pose)

local BURST = 1.3
local ROAR = 1.45
local SETTLE = 2.6
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
function Evolucion.pose(t: number): Pose.Pose
	local seconds = SECONDS
	if t < 0 or t > seconds then
		return {}
	end
	local function span(a: number, b: number): number
		return C.span(t, a, b)
	end
	local gather = C.smooth(span(0, 1)) * (1 - C.easeIn(span(BURST - 0.1, BURST)))
	local tremble = math.sin(t * 80) * 0.04 * C.smooth(span(0.15, BURST - 0.05)) * gather
	local burst = C.overshoot(span(BURST, BURST + 0.2)) * (1 - C.smooth(span(2.2, seconds - 0.1)))
	local roar = C.smooth(span(ROAR - 0.05, ROAR + 0.1)) * (1 - C.smooth(span(2.15, SETTLE)))
	local shake = math.sin(t * 45) * 0.06 * roar
	local settle = C.bell(span(SETTLE - 0.3, seconds))
	return {
		legL = 0.55 * gather + 0.2 * settle,
		legR = 0.55 * gather + 0.2 * settle,
		kneeL = 1.1 * gather + 0.4 * settle,
		kneeR = 1.1 * gather + 0.4 * settle,
		lean = -0.35 * gather + tremble + 0.3 * burst + 0.04 * math.sin(t * 22) * roar,
		sway = tremble * 0.5,
		lookPitch = -0.35 * gather + 0.5 * burst + shake,
		lookYaw = 1.5 * tremble + 1.5 * shake,
		jaw = 0.15 * gather + 1.2 * burst,
		armL = 0.3 * gather + 0.55 * burst,
		armR = 0.3 * gather + 0.55 * burst,
		elbowL = 1.4 * gather + 0.3 * burst,
		elbowR = 1.4 * gather + 0.3 * burst,
		outL = -0.1 * gather + 1.6 * burst,
		outR = -0.1 * gather + 1.6 * burst,
		elbowOutL = 0.3 * burst,
		elbowOutR = 0.3 * burst,
		earL = -0.5 * gather + 0.3 * burst,
		earR = -0.5 * gather + 0.3 * burst,
		tailUp = 0.45 * burst,
	}
end

return table.freeze(Evolucion)
