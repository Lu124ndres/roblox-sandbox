--!strict
--[[
	OrcaMotion/Comer/Postura

	El cuerpo de la orca mientras pide comida, como una orca de acuario que
	pide pescado junto al borde:
		llega   nada a ras del agua hacia la orilla: aletazos fuertes lejos y
		        planea al acercarse (el recorrido lo hace Steer);
		sale    se para casi vertical (spyhop) con la panza arqueada: la
		        cabeza y el pecho fuera del agua y las pectorales abiertas a
		        ras del agua; se sostiene con aletazos cortos de la cola y
		        sube y baja un poco con cada uno; se inclina hacia quien la
		        alimenta cuando viene un pez;
		se va   se hunde suave hacia atrás (el centro baja antes de que se
		        acueste) y se nivela para volver a nadar.
	La cría da saltitos de impaciencia mientras espera el pez. Cuánto tarda en
	salir y en hundirse, y lo pesada que es, salen de Estilo.
	Da la pose (que manda con el peso de comer) y lo que se suma encima.
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Path = require(script.Parent.Parent.Path)
local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Schedule = require(script.Parent.Parent.Schedule)
local Tricks = require(script.Parent.Parent.Tricks)
local Estilo = require(script.Parent.Estilo)

local smooth = Tricks.smooth

local CLOSE_OUT = 0.6 -- tan cerca de la orilla (Steer: 0..1) sale a pedir
local CLOSE_STAY = 0.35 -- y ya afuera, se queda mientras esté así de cerca
local SLOW_OUT = 1.2 -- y nada más lento que esto (veces el crucero): no se para nadando rápido
local APPROACH_DEPTH = -0.1 -- nada a ras del agua hacia la orilla
local APPROACH_PITCH = 0.04
local LEAVE_DEPTH = -0.2 -- al irse: el centro casi no baja, la cabeza se hunde al acostarse
local EFFORT_FAR, EFFORT_NEAR = 1.5, 0.4 -- aletazos lejos; planea al llegar
local EFFORT_OUT, EFFORT_LEAVE = 0.7, 0.35
local FINS_TUCK, FINS_OUT = 0.15, -0.5 -- pegadas al nadar rápido; abiertas asomada
local ARCH_OUT = -0.1 -- panza un poco arqueada, asomada
local ARCH_RISE = -0.18 -- y más mientras sale, como al salir del agua
local BANK_MAX = 0.45 -- se inclina en las curvas (como en el nado)
local SWAY, SWAY_HZ = 0.05, 0.23 -- se mece de lado, asomada
local SCULL = 0.07 -- se equilibra con las pectorales, una y otra
local KICK_UP = 0.35 -- parte del aletazo en que sube (después se deja caer)
local SETTLE = 0.75 -- resorte crítico: llega al 95 % en SETTLE / hz s

export type Pose = Tricks.Pose & {
	arch: number?, -- curva de la columna (- = panza arqueada)
	beat: number?, -- aletazos por segundo de la cola mientras manda esta pose
}
export type Scene = {
	close: number, -- 0..1: llegó a la orilla
	engaged: boolean, -- alguien le da de comer
	leaving: boolean, -- dejaron de tirarle: se hunde y se va
	expect: number, -- 0..1: viene un pez
	eager: boolean, -- espera el pez sin estar tragando (la cría salta)
}
export type View = { center: Vector3, yaw: number, height: number, speed: number }
export type Postura = {
	out: Resorte.Resorte, -- 0..1: cuánto está asomada
	leave: Resorte.Resorte, -- 0..1: se está yendo
	lastYaw: number?,
	turn: number, -- rad/s del rumbo (suavizado)
	kick: number, -- avance de los aletazos que la sostienen (vueltas)
	hop: number, -- avance de los saltitos de la cría (vueltas)
}
export type Extra = { lift: number, scull: number } -- lo que se suma: altos y aletas

local Postura = {}

function Postura.new(): Postura
	return { out = Resorte.new(), leave = Resorte.new(), turn = 0, kick = 0, hop = 0 }
end

local function wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

local function mix(a: number, b: number, w: number): number
	return a + (b - a) * w
end

-- Sube rápido con el aletazo y se deja caer despacio (f: avance del aletazo).
local function kickLift(f: number): number
	return if f < KICK_UP then smooth(f / KICK_UP) else 1 - smooth((f - KICK_UP) / (1 - KICK_UP))
end

-- Saltitos de impaciencia de la cría; al caer salpica.
local function hops(
	p: Postura,
	style: Estilo.Estilo,
	dt: number,
	on: boolean,
	events: { Schedule.Event }
): number
	if style.hop <= 0 or (not on and p.hop % 1 < 0.02) then
		return 0
	end
	local before = math.floor(p.hop)
	p.hop += dt * style.hopRate
	if math.floor(p.hop) > before then
		table.insert(events, { kind = "splash" })
		if not on then
			p.hop = math.floor(p.hop) -- termina el saltito y se queda quieta
		end
	end
	return style.hop * math.sin(math.pi * (p.hop % 1)) ^ 2
end

function Postura.step(
	p: Postura,
	style: Estilo.Estilo,
	swim: Perfil.Swim,
	dt: number,
	now: number,
	view: View,
	scene: Scene,
	events: { Schedule.Event }
): (Pose, Extra)
	local cruise = math.max(Path.speed(view.height) * swim.speed, 1)
	local up = p.out.x > 0.5 -- ya está afuera
	local near = scene.close > (if up then CLOSE_STAY else CLOSE_OUT)
	local slow = up or view.speed < cruise * SLOW_OUT
	local wantOut = if scene.engaged and not scene.leaving and near and slow then 1 else 0
	local hz = SETTLE / (if wantOut > p.out.x then style.rise else style.sink)
	local o = math.clamp(Resorte.step(p.out, wantOut, dt, hz, 1), 0, 1)
	local lv = Resorte.step(p.leave, if scene.leaving then 1 else 0, dt, SETTLE / style.sink, 1)
	lv = math.clamp(lv, 0, 1)

	-- Se inclina en las curvas al llegar (como en el nado de crucero).
	local rate = if p.lastYaw then wrap(view.yaw - p.lastYaw) / dt else 0
	p.lastYaw = view.yaw
	p.turn += (rate - p.turn) * (1 - math.exp(-dt * 4))
	local bank = math.clamp(p.turn * swim.bank, -BANK_MAX, BANK_MAX)

	-- Los aletazos que la sostienen: la cola a su ritmo y el cuerpo sube con cada uno.
	p.kick += dt * style.kick
	local kick = p.kick % 1
	local pace = view.speed / cruise
	local swimBeat = swim.beat * (0.45 + 0.55 * pace) -- el de Body al nadar

	local base = mix(APPROACH_DEPTH, LEAVE_DEPTH, lv)
	local upright = o ^ (1 - 0.4 * lv) -- al irse se queda derecha más tiempo: se hunde hacia atrás
	local level = APPROACH_PITCH * (1 - lv)
	local reach = style.outPitch - style.lean * scene.expect
	local approach = mix(EFFORT_FAR, EFFORT_NEAR, smooth(scene.close / 0.8))
	local pose: Pose = {
		depth = mix(base, style.outDepth, o),
		pitch = mix(level, reach, upright),
		roll = bank * (1 - o) + SWAY * math.sin(now * 2 * math.pi * SWAY_HZ) * o,
		fins = mix(FINS_TUCK, FINS_OUT, o),
		effort = mix(mix(approach, EFFORT_LEAVE, lv), EFFORT_OUT, o),
		arch = ARCH_OUT * o + ARCH_RISE * 4 * o * (1 - o) * (1 - lv),
		beat = mix(swimBeat, style.kick, o),
	}
	local lift = style.bob * kickLift(kick) * o
	lift += hops(p, style, dt, scene.eager and o > 0.6, events) * o
	return pose, { lift = lift, scull = SCULL * math.sin(2 * math.pi * kick) * o }
end

return table.freeze(Postura)
