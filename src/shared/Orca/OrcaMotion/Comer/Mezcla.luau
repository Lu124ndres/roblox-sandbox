--!strict
--[[
	OrcaMotion/Comer/Mezcla

	Cómo se juntan las capas de la comida de la orca:
		- los gestos de gusto (Gestos) corren de a uno, alternando el lado, y
		  se suman por resortes con el rebote de la etapa (la cría rebota, la
		  anciana casi no); crecen con la racha;
		- la reacción grande (Grande) se mezcla sobre la postura con su peso y
		  apaga los gestos suave.
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Schedule = require(script.Parent.Parent.Schedule)
local Tricks = require(script.Parent.Parent.Tricks)
local Gestos = require(script.Parent.Gestos)
local Grande = require(script.Parent.Grande)
local Turnos = require(script.Parent.Turnos)

local CHANNELS =
	{ "depth", "pitch", "roll", "yaw", "head", "jaw", "fins", "tail", "waveIzq", "waveDer" }
local QUICK = { jaw = 2, waveIzq = 2, waveDer = 2 } -- canales con resorte más rápido (el saludo se ve)
-- Lo que la reacción grande pisa de la postura (la boca la mezcla Comer).
local OVER = { "depth", "pitch", "roll", "head", "fins", "tail", "effort", "arch" }
local STREAK_PLUS, STREAK_FULL = 0.5, 30 -- los gestos crecen hasta +50 % a los 30 seguidos

type Running = { gesture: Gestos.Gesture, t: number, seconds: number, side: number }
export type Mezcla = { gesture: Running?, side: number, springs: { [string]: Resorte.Resorte } }

local Mezcla = {}

function Mezcla.new(): Mezcla
	return { side = 1, springs = {} }
end

-- Empieza un gesto (cambia el lado si `flip`).
function Mezcla.start(m: Mezcla, name: string, tempo: number, flip: boolean)
	if flip then
		m.side = -m.side
	end
	local gesture = Gestos.byName[name]
	m.gesture = { gesture = gesture, t = 0, seconds = gesture.seconds * tempo, side = m.side }
end

-- Elige el gesto que toca (o traga fuerte cuando paran los peces). busy: hay
-- una reacción grande; free: no viene otro pez ni está tragando.
function Mezcla.choose(
	m: Mezcla,
	turnos: Turnos.Turnos,
	meal: Perfil.Meal,
	now: number,
	free: boolean,
	busy: boolean,
	events: { Schedule.Event }
)
	if busy then
		m.gesture = nil -- los resortes lo apagan suave
	elseif not m.gesture then
		local name = Turnos.nextGesture(turnos, meal, now, free)
		if name then
			Mezcla.start(m, name, meal.tempo, true)
		end
	end
	local gulp = Turnos.gulp(turnos, now)
	if gulp == "start" and not m.gesture and not busy then
		Mezcla.start(m, "tragar", meal.tempo, false)
	elseif gulp then
		table.insert(events, { kind = "gulp" })
	end
end

-- Avanza el gesto y da la suma por resortes (bw: peso de la reacción grande).
function Mezcla.step(
	m: Mezcla,
	turnos: Turnos.Turnos,
	meal: Perfil.Meal,
	dt: number,
	now: number,
	bw: number,
	events: { Schedule.Event }
): Gestos.Add
	local raw: { [string]: number } = Gestos.zero() :: any
	local r = m.gesture
	if r then
		local before = r.t / r.seconds
		r.t += dt
		local u = r.t / r.seconds
		Grande.fire(r.gesture.events, before, u, events, turnos.from)
		if u >= 1 then
			m.gesture = nil
			Turnos.endGesture(turnos, meal, now)
		else
			local grow = 1 + STREAK_PLUS * math.min(turnos.streak, STREAK_FULL) / STREAK_FULL
			local add: { [string]: number } = r.gesture.pose(u, r.side, meal.roll) :: any
			for _, key in CHANNELS do
				raw[key] += add[key] * grow
			end
		end
	end
	local result = Gestos.zero()
	local out: { [string]: number } = result :: any
	for _, key in CHANNELS do
		local hz = meal.hz * (QUICK[key] or 1)
		local spring = Resorte.get(m.springs, key)
		out[key] = Resorte.step(spring, raw[key] * (1 - bw), dt, hz, meal.damping)
	end
	return result
end

-- Mezcla la reacción grande `big` sobre la postura `pose` con su peso `bw`.
-- carry: parte del cabeceo de la postura que se suma al del truco (Grande.step).
function Mezcla.over(pose: Tricks.Pose, big: Tricks.Pose, bw: number, carry: number)
	local mine: { [string]: any }, theirs: { [string]: any } = pose :: any, big :: any
	local own = pose.pitch or 0
	for _, key in OVER do
		if theirs[key] then
			local want = theirs[key]
			if key == "pitch" then -- suma lo que conserva, sin pararse más que ninguna de las dos
				want = math.min(want + own * carry, math.max(want, own))
			end
			mine[key] = (mine[key] or 0) + (want - (mine[key] or 0)) * bw
		end
	end
	pose.yaw = if big.yaw then big.yaw * bw else nil
	pose.air = big.air
end

return table.freeze(Mezcla)
