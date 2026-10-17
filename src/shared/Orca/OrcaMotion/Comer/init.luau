--!strict
--[[
	OrcaMotion/Comer

	La animación especial de la orca al comer. Cada cliente la arma con los
	peces que le llegan (FedInfo); todos reciben los GiantFed casi a la vez,
	así que la ven parecida (no tiene que ser idéntica):
		- con cada pez, un bocado hacia arriba (Gestos.bocado): si llegan muy
		  seguidos no empieza otro hasta que el anterior pasó su golpe, alterna
		  el lado y pierde fuerza con el ritmo (con ganas, no frenética);
		  cuando paran los peces, o cada tanto, traga;
		- entre peces, un gesto de gusto de su etapa (Turnos elige cuál);
		- con un pez raro o un combo, una reacción grande (Festejos), y al
		  llegar el pez raro un destello al instante;
		- si lo dio el jugador de este cliente, lo mira y le dedica un saludo.
	Los gestos se suman a la pose de comer a través de resortes (el rebote
	de la etapa: la bebé rebota, la anciana casi no); las reacciones grandes
	reemplazan la pose como un truco y entran y salen suaves (BLEND). Sus
	momentos van a state.events como eventos de OrcaFx (Comida).
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Resorte = require(script.Parent.Parent.Parent.Resorte)
local Schedule = require(script.Parent.Schedule)
local Tricks = require(script.Parent.Tricks)
local Gestos = require(script.Gestos)
local Grande = require(script.Grande)
local Turnos = require(script.Turnos)

local LUNGE_AGAIN = 0.45 -- avance del bocado desde el que otro pez empieza uno nuevo
local CHANNELS =
	{ "depth", "pitch", "roll", "yaw", "head", "jaw", "fins", "tail", "waveIzq", "waveDer" }
local QUICK = { jaw = 2, waveIzq = 2, waveDer = 2 } -- canales con resorte más rápido (el saludo se ve)

export type Add = Gestos.Add
export type Info = Turnos.Info
export type Out = { pose: Tricks.Pose?, weight: number, yaw: number, add: Add }
-- Lo que ve de la orca (OrcaMotion.State): centro, rumbo y alto del modelo.
export type View = { center: Vector3, yaw: number, height: number }

type Running = { gesture: Gestos.Gesture, t: number, seconds: number, side: number }
export type Comer = {
	turnos: Turnos.Turnos,
	springs: { [string]: Resorte.Resorte },
	lunge: Running?,
	gesture: Running?,
	big: Grande.Big?,
	side: number,
}

local Comer = {}
Comer.zero = table.freeze(Gestos.zero()) -- sin gestos

function Comer.new(): Comer
	return { turnos = Turnos.new(), springs = {}, side = 1 }
end

local function run(name: string, side: number, tempo: number): Running
	local gesture = Gestos.byName[name]
	return { gesture = gesture, t = 0, seconds = gesture.seconds * tempo, side = side }
end

-- Llegó un pez a la boca.
function Comer.fed(comer: Comer, info: Info, profile: Perfil.Profile, events: { Schedule.Event })
	local power = Turnos.fed(comer.turnos, info, os.clock())
	table.insert(events, { kind = "snap", size = info.rarity })
	if power > 0 then
		table.insert(events, { kind = "shine", size = power })
	end
	local lunge = comer.lunge
	if not lunge or lunge.t / lunge.seconds >= LUNGE_AGAIN then
		comer.side = -comer.side -- alterna el lado del bocado
		comer.lunge = run("bocado", comer.side, profile.meal.tempo)
	end
end

-- Elige el gesto que toca (o traga cuando paran los peces).
local function choose(
	comer: Comer,
	meal: Perfil.Meal,
	view: View,
	now: number,
	events: { Schedule.Event }
)
	local turnos = comer.turnos
	if not comer.big and not comer.gesture then
		local name, dedicated = Turnos.nextGesture(turnos, meal, now)
		if name then
			-- El saludo dedicado levanta la aleta del lado del jugador local.
			local look = Turnos.look(turnos, view.center, view.yaw, now)
			comer.side = if dedicated and look ~= 0 then -math.sign(look) else -comer.side
			comer.gesture = run(name, comer.side, meal.tempo)
		end
	end
	local gulp = Turnos.gulp(turnos, now)
	if gulp == "start" and not comer.gesture and not comer.big then
		comer.gesture = run("tragar", comer.side, meal.tempo)
	elseif gulp then
		table.insert(events, { kind = "gulp" })
	end
end

-- Suma la pose de un gesto en `raw`; false si ya terminó.
local function addFrom(
	r: Running?,
	scale: number,
	roll: number,
	dt: number,
	raw: { [string]: number },
	events: { Schedule.Event },
	spot: Vector3?
): boolean
	if not r then
		return true
	end
	local before = r.t / r.seconds
	r.t += dt
	local u = r.t / r.seconds
	Grande.fire(r.gesture.events, before, u, events, spot)
	if u >= 1 then
		return false
	end
	local add: { [string]: number } = r.gesture.pose(u, r.side, roll) :: any
	for _, key in CHANNELS do
		raw[key] += add[key] * scale
	end
	return true
end

function Comer.step(
	comer: Comer,
	dt: number,
	profile: Perfil.Profile,
	view: View,
	events: { Schedule.Event }
): Out
	local now = os.clock()
	local turnos, meal = comer.turnos, profile.meal
	comer.big = Grande.start(comer.big, turnos, meal, view, now)
	local pose, weight = nil, 0
	if comer.big then
		comer.gesture = nil -- los resortes lo apagan suave
		pose, weight = Grande.step(comer.big, turnos, dt, now, events)
		if not pose then
			comer.big = nil
		end
	end
	choose(comer, meal, view, now, events)

	-- Suma de lo que está haciendo, por resortes. El bocado pierde fuerza si los
	-- peces llegan muy seguidos (a ~5 por segundo, dos tercios).
	local raw: { [string]: number } = Gestos.zero() :: any
	local calm = 1 / (1 + 0.15 * math.max(0, turnos.rate - 1.5))
	if not addFrom(comer.lunge, meal.snap * calm, meal.roll, dt, raw, events, turnos.from) then
		comer.lunge = nil
	end
	if not addFrom(comer.gesture, 1, meal.roll, dt, raw, events, turnos.from) then
		comer.gesture = nil
		Turnos.endGesture(turnos, meal, now)
	end
	raw.yaw += Turnos.look(turnos, view.center, view.yaw, now) -- mira al jugador local
	local out = Gestos.zero()
	local add: { [string]: number } = out :: any
	for _, key in CHANNELS do
		local hz = meal.hz * (QUICK[key] or 1)
		add[key] = Resorte.step(
			Resorte.get(comer.springs, key),
			raw[key] * (1 - weight),
			dt,
			hz,
			meal.damping
		)
	end
	return {
		pose = pose,
		weight = weight,
		yaw = if pose and pose.yaw then pose.yaw * weight else 0,
		add = out,
	}
end

return table.freeze(Comer)
