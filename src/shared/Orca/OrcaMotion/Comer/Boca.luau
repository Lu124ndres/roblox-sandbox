--!strict
--[[
	OrcaMotion/Comer/Boca

	La boca y la cabeza de la orca al comer, pez por pez:
		abre    antes de que llegue el pez (Estilo.lead s antes), grande, y
		        la cabeza apunta al bocado siguiendo su arco; justo antes de
		        morder se echa un poco atrás (anticipación);
		muerde  al llegar: cierra de golpe con un golpe de cabeza hacia
		        adelante;
		traga   con la boca cerrada: la cabeza baja y sube (la garganta) y
		        las pectorales se pegan un instante; recién después vuelve a
		        abrir (si el próximo llega antes, abre a medias);
		mastica entre bocados de una racha, con la boca entreabierta;
		pide    cuando dejan de tirarle y el jugador sigue ahí: abre y
		        cierra despacio, mirándolo.
	Cuándo llega el pez lo estima Feeders (los lotes de GiantFed); sin él, el
	ritmo de los últimos peces. Mira (gira el cuerpo, poco) hacia quien le
	tira el pez que viene, o al que atiende.
]]

local UIConfig = require(script.Parent.Parent.Parent.Parent.UIConfig)
local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Tricks = require(script.Parent.Parent.Tricks)
local Estilo = require(script.Parent.Estilo)

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

local FLIGHT = UIConfig.Effects.FeedThrowSeconds -- lo que vuela cada pez
local BITE_GAP = 0.45 -- FeedThrow: como mucho un mordisco cada BITE_SECONDS
local LATE = 0.35 -- s que espera con la boca abierta un pez que no llegó
local RHYTHM_KEEP = 1.5 -- sin Feeders: espera otro pez si el último fue hace menos
local RHYTHM_MAX = 1.2 -- y lo espera a lo sumo a este intervalo
local STREAK_KEEP = 1.3 -- s desde el último pez en que sigue masticando
local SNAP_IN, SNAP_OUT = 0.05, 0.3 -- golpe de cabeza al morder: va y vuelve
local SNAP_HEAD, SNAP_PITCH = 0.2, 0.05 -- rad hacia adelante (cabeza y cuerpo)
local PRE = 0.25 -- s antes del pez en que se echa atrás
local PRE_HEAD = 0.07
local GULP_HEAD, GULP_PITCH, GULP_FINS = 0.09, 0.03, 0.06 -- al tragar (rad)
local JAW_APPROACH, JAW_IDLE, JAW_LEAVE = 0.2, 0.1, 0.05 -- partes de la boca abierta
local CHEW_OPEN, CHEW_CLOSE = 0.6, 0.42 -- masticando: entreabierta y cierra esto
local BEG_OPEN, BEG_SECONDS = 0.85, 2.4 -- pide: abre y cierra en este ciclo
local MOUTH_REACH = 0.95 -- la boca está a este largo del centro (altos del modelo)
local AIM_UP, AIM_DOWN = 0.25, 0.3 -- tope de la cabeza al apuntar al pez (rad)
local THROW_UP = 2 -- FeedThrow suelta el pez 2 studs sobre el jugador
local LOOK_MAX = 0.6 -- rad que gira el cuerpo para mirar

export type Mode = "approach" | "eat" | "wait" | "leave"
export type Expect = { tau: number?, from: Vector3?, a: number } -- a: 0 lejos .. 1 llegando
export type Mouth = {
	jaw: number,
	head: number,
	pitch: number,
	depth: number,
	yaw: number,
	fins: number,
}
export type View = { center: Vector3, yaw: number, height: number }
export type Boca = { bitAt: number, lastFed: number, gap: number, look: Resorte.Resorte }
type Incoming = (after: number) -> (number?, Vector3?)

local Boca = {}

function Boca.new(): Boca
	return { bitAt = -math.huge, lastFed = -math.huge, gap = 0.6, look = Resorte.new() }
end

-- Llegó un pez: muerde.
function Boca.bite(b: Boca, now: number)
	local gap = now - b.lastFed
	if gap < RHYTHM_KEEP then
		b.gap += (gap - b.gap) * 0.4
	end
	b.bitAt, b.lastFed = now, now
end

-- Cuándo llega el próximo pez que va a morder.
function Boca.expect(b: Boca, style: Estilo.Estilo, incoming: Incoming?, now: number): Expect
	local at, from = nil, nil
	if incoming then
		at, from = incoming(math.max(b.bitAt + BITE_GAP, now - LATE))
	elseif now - b.lastFed < RHYTHM_KEEP then
		at = b.lastFed + math.clamp(b.gap, BITE_GAP, RHYTHM_MAX)
	end
	if not at then
		return { a = 0 }
	end
	local tau = at - now
	local a = if tau >= 0 then smooth(1 - tau / style.lead) else smooth(1 + tau / LATE)
	return { tau = tau, from = from, a = a }
end

local function yawOf(v: Vector3): number
	return math.atan2(-v.X, -v.Z)
end

-- Cuánto levantar la cabeza para apuntar al pez que viene en arco hacia la boca.
local function aim(view: View, from: Vector3, tau: number, pitch: number): number
	local look = Vector3.new(-math.sin(view.yaw), 0, -math.cos(view.yaw))
	local reach = view.height * MOUTH_REACH
	local mouth = view.center
		+ look * reach * math.cos(pitch)
		+ Vector3.yAxis * reach * math.sin(pitch)
	local throw = from + Vector3.yAxis * THROW_UP - mouth
	local arc = math.clamp(throw.Magnitude * 0.3, 6, 40) -- la altura del arco de FeedThrow
	local t = math.clamp(1 - tau / FLIGHT, 0, 1)
	local toFish = throw + Vector3.yAxis * 4 * arc * t -- el pez visto desde la boca
	local flat = Vector3.new(toFish.X, 0, toFish.Z).Magnitude
	return math.clamp(math.atan2(toFish.Y, flat) - pitch, -AIM_DOWN, AIM_UP)
end

-- La boca y la cabeza ahora. pitch: cabeceo del cuerpo que pide la postura;
-- lookAt: a quién mira; present: el que atiende sigue en la orilla.
function Boca.step(
	b: Boca,
	style: Estilo.Estilo,
	snap: number,
	dt: number,
	now: number,
	view: View,
	ex: Expect,
	mode: Mode,
	pitch: number,
	lookAt: Vector3?,
	present: boolean
): Mouth
	local since = now - b.bitAt
	local gate = smooth((since - style.bite) / style.swallow) -- cerrada mientras muerde y traga
	local rest = JAW_APPROACH
	if mode == "leave" then
		rest = JAW_LEAVE
	elseif mode == "wait" then
		local beg = smooth(0.5 + 0.9 * math.sin(2 * math.pi * now / BEG_SECONDS))
		rest = if present then BEG_OPEN * beg else JAW_IDLE
	elseif now - b.lastFed < STREAK_KEEP then
		rest = CHEW_OPEN - CHEW_CLOSE * math.max(0, math.sin(2 * math.pi * style.chew * now)) ^ 2
	end
	local a = if mode == "leave" then 0 else ex.a
	local jaw = style.open * (rest + (1 - rest) * a) * gate

	local hit = smooth(since / SNAP_IN) * (1 - smooth((since - SNAP_IN) / SNAP_OUT)) * snap
	local gulp = bell(span(since, style.bite, style.bite + style.swallow))
	local pre = if ex.tau and ex.tau > 0 then smooth(1 - ex.tau / PRE) * a else 0
	local head = PRE_HEAD * pre - SNAP_HEAD * hit - GULP_HEAD * gulp
	if ex.from and ex.tau then
		head += aim(view, ex.from, ex.tau, pitch) * a
	end

	local turn = 0
	local point = ex.from or lookAt
	if point and mode ~= "leave" then
		local flat = Vector3.new(point.X - view.center.X, 0, point.Z - view.center.Z)
		if flat.Magnitude > 1 then
			local off = (yawOf(flat) - view.yaw + math.pi) % (2 * math.pi) - math.pi
			turn = math.clamp(off, -LOOK_MAX, LOOK_MAX)
		end
	end
	return {
		jaw = jaw,
		head = head,
		pitch = -SNAP_PITCH * hit - GULP_PITCH * gulp,
		depth = 0.012 * pre + 0.01 * hit - 0.012 * gulp,
		yaw = Resorte.step(b.look, turn, dt, 1.1, 0.9),
		fins = GULP_FINS * gulp,
	}
end

return table.freeze(Boca)
