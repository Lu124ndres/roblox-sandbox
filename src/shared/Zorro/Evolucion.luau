--!strict
--[[
	Zorro/Evolucion

	La pose del zorro mientras evoluciona (el servidor publica en EstadoGigante la
	hora en que termina: Protocol.GiantAttributes.EvolvingUntil; dura
	Config.Giants.cycle.evolveSeconds, 3 s). Va en segundos desde que empieza, no en
	avance, porque el destello y el cambio de modelo (GiantEvolution/EvolveFx, en el
	cliente) caen en BURST (EvolveLook.burstSeconds):
		0 .. 0.7      se agacha cargando energía: patas dobladas, cabeza baja, orejas
		              atrás, ojos cerrados y las colas recogidas, temblando cada vez
		              más (crouch)
		0.7 .. 1.15   se sacude como al salir del agua, de la cabeza a la cola: la
		              cabeza va de lado a lado, después el cuerpo, al final las colas
		              (shake)
		1.15 .. BURST un último golpe hacia abajo (la anticipación del salto)
		BURST         estalla: se estira y se yergue, abre el abanico entero (fan) y
		              aúlla al cielo con la boca abierta y los ojos bien abiertos
		              (howl); se pasa un poco y vuelve
		2.3 .. 3      se calma: baja la cabeza, cierra el abanico y suelta el aire
	En el estallido cambia el modelo: la pose sigue igual en el nuevo (sale del
	tiempo, no del rig). Empieza y termina en cero; fuera de 0..SECONDS vale cero.
	Mientras dura, la Mirada no lo tira hacia el jugador (lookHold).
	watch() sigue el atributo y da, en cada cuadro, los segundos desde que empezó
	(o nil) y sus eventos; si el cliente llega tarde, no repite los que ya pasaron.
]]

local Config = require(script.Parent.Parent.Config)
local Protocol = require(script.Parent.Parent.Protocol)
local Curvas = require(script.Parent.Comer.Curvas)
local Pose = require(script.Parent.Pose)

local span, smooth, bell, hold = Curvas.span, Curvas.smooth, Curvas.bell, Curvas.hold

local BURST = 1.3 -- = EvolveLook.burstSeconds()
local SECONDS = Config.Giants.cycle.evolveSeconds
local LATE = 0.4 -- s: si lo ve empezar más tarde que esto, no suena el agacharse
local EVENTS = {
	{ at = 0.05, kind = "crouch" },
	{ at = 0.72, kind = "shake" },
	{ at = BURST, kind = "fan" },
	{ at = BURST + 0.08, kind = "howl" },
}

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
	if t <= 0 or t >= seconds then
		return {}
	end
	local function s(a: number, b: number): number
		return span(t, a, b)
	end
	local function hold2(a: number, b: number, c: number, d: number): number
		return hold(t, a, b, c, d)
	end
	-- Carga: se agacha y junta fuerza (sube hasta 0.7, aguanta y suelta en el estallido).
	local gather = smooth(s(0, 0.7)) * (1 - Curvas.easeOut(s(BURST - 0.06, BURST + 0.04)))
	local tremble = math.sin(t * 70) * 0.03 * smooth(s(0.2, 0.7)) * gather
	-- Sacudida de la cabeza a la cola: la cabeza primero, el cuerpo y las colas después.
	local shakeW = bell(s(0.7, 1.15))
	local head = math.sin(2 * math.pi * 4 * s(0.7, 1.05)) * bell(s(0.7, 1.05))
	local body = bell(s(0.78, 1.12))
	local dip = bell(s(1.12, BURST + 0.02)) -- el último golpe hacia abajo
	-- Estallido: se pasa un poco (overshoot) y queda; el aullido lo mantiene.
	local burst = Curvas.overshoot(s(BURST, BURST + 0.22)) * (1 - smooth(s(2.3, seconds)))
	local howl = hold2(BURST + 0.05, BURST + 0.2, 2.15, 2.5)
	local quiver = math.sin(t * 50) * 0.02 * howl
	local calm = bell(s(2.3, seconds)) -- suelta el aire
	return {
		-- Tope del modelo: agacharse hasta ~1 (la carga 0.7 más el último golpe 0.3).
		crouch = 0.7 * gather - 0.3 * shakeW * gather + 0.3 * dip - 0.2 * burst + 0.15 * calm,
		lean = -0.12 * gather + tremble + 0.18 * burst - 0.05 * calm,
		sway = 0.6 * tremble,
		breathe = 0.03 * gather - 0.04 * calm,
		lookPitch = -0.4 * gather + 0.3 * shakeW * gather - 0.15 * dip + 0.85 * howl + quiver,
		lookYaw = 0.45 * head,
		tilt = -0.35 * head,
		jaw = 0.85 * howl + 0.1 * calm,
		earL = -0.65 * gather + 0.3 * burst - 0.35 * howl,
		earR = -0.6 * gather + 0.3 * burst - 0.4 * howl,
		earTipL = 0.5 * head,
		earTipR = -0.5 * head,
		shake = body,
		eyesClosed = 0.75 * gather * (1 - shakeW) + 0.4 * calm,
		emoSorpresa = 0.5 * hold2(BURST, BURST + 0.08, BURST + 0.3, BURST + 0.6),
		emoFeliz = 0.7 * hold2(BURST + 0.3, BURST + 0.6, 2.4, seconds),
		tailLift = -0.35 * gather + 0.7 * burst,
		tailFan = -0.3 * gather + 1.4 * burst,
		tailCalm = -0.5 * gather + 0.6 * shakeW - 0.4 * howl,
		tailWag = 1.2 * bell(s(0.85, 1.2)),
		tailAlert = 0.6 * burst,
		lookHold = hold2(0, 0.15, 2.6, seconds),
	}
end

return table.freeze(Evolucion)
