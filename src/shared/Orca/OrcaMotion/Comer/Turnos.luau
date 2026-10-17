--!strict
--[[
	OrcaMotion/Comer/Turnos

	Qué le toca hacer a la orca mientras come (Comer lo pregunta cada cuadro):
		- festejo de combo cuando la racha llega a un número (Festejos.due),
		  cada vez más grande dentro de la misma racha (canto, coletazo a la
		  orilla, tirabuzón...); entre uno y otro espera PARTY_GAP s y el que
		  llega mientras tanto queda pendiente;
		- reacción grande con un pez raro (rareza >= RARE_FROM), si no está
		  festejando; espera a lo sumo RARE_KEEP s (y BIG_GAP s después de
		  cualquier reacción grande);
		- gesto de gusto cada `gap` s de la etapa, al azar por peso y sin
		  repetir el anterior; un pez poco común adelanta el chorro y el
		  jugador local recibe un saludo dedicado (cada WAVE_EVERY s a lo sumo);
		- tragar cuando paran los peces o cada GULP_EVERY peces;
		- hacia dónde mirar: al jugador local que le da de comer.
	Todo con os.clock (es local de cada cliente).
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Tricks = require(script.Parent.Parent.Tricks)
local Festejos = require(script.Parent.Festejos)

local PARTY_GAP = 5 -- s entre festejos
local BIG_GAP = 1.2 -- s entre reacciones grandes (se ven los bocados y gestos)
local PARTY_KEEP = 8 -- s que espera un festejo pendiente
local RARE_FROM = 3 -- índice de rareza (Raro) desde el que salta
local RARE_KEEP = 6
local GESTURE_WINDOW = 1.2 -- s desde el último pez en que todavía hace gestos
local GULP_AFTER = 0.5 -- s sin peces: traga
local GULP_EVERY = 12
local LOOK_SECONDS = 2.5
local LOOK_MAX = 0.6 -- rad que se desvía para mirar
local WAVE_EVERY = 6

export type Info = { from: Vector3, rarity: number, isLocal: boolean, streak: number }
export type Turnos = {
	lastFed: number,
	rate: number, -- peces por segundo (promedio)
	from: Vector3?, -- de dónde vino el último
	lastGesture: string?,
	nextGestureAt: number,
	boost: string?, -- gesto adelantado
	gulps: number,
	rare: { power: number, at: number }?,
	party: number?, -- cuándo le tocó el festejo pendiente
	parties: number, -- festejos de esta racha
	partyReadyAt: number,
	bigReadyAt: number,
	lookFrom: Vector3?,
	lookUntil: number,
	waveAt: number,
	wantWave: boolean,
}

local Turnos = {}

function Turnos.new(): Turnos
	return {
		lastFed = -math.huge,
		rate = 0,
		nextGestureAt = 0,
		gulps = 0,
		parties = 0,
		partyReadyAt = 0,
		bigReadyAt = 0,
		lookUntil = 0,
		waveAt = -math.huge,
		wantWave = false,
	}
end

-- Llegó un pez. Devuelve la fuerza del pez raro (0 si es común).
function Turnos.fed(t: Turnos, info: Info, now: number): number
	local gap = now - t.lastFed
	t.rate = if gap > 2 then 0 else t.rate + (1 / math.max(gap, 0.05) - t.rate) * 0.3
	t.lastFed, t.from = now, info.from
	t.gulps += 1
	if info.streak <= 1 then -- racha nueva: vuelve a empezar por el festejo chico
		t.parties = 0
	end
	if Festejos.due(info.streak) then
		t.party = now
	end
	local power = math.max(0, info.rarity - RARE_FROM + 1)
	if power > 0 and (not t.rare or power >= t.rare.power) then
		t.rare = { power = power, at = now }
	elseif info.rarity == RARE_FROM - 1 then
		t.boost = "chorro"
	end
	if info.isLocal then
		t.lookFrom, t.lookUntil = info.from, now + LOOK_SECONDS
		t.wantWave = t.wantWave or now - t.waveAt > WAVE_EVERY
	end
	return power
end

-- La reacción grande que toca ahora (o nil) y si es un festejo de combo.
function Turnos.nextBig(t: Turnos, meal: Perfil.Meal, now: number): (Tricks.Trick?, boolean)
	if t.party and now - t.party > PARTY_KEEP then
		t.party = nil
	end
	if t.rare and now - t.rare.at > RARE_KEEP then
		t.rare = nil
	end
	if now < t.bigReadyAt then
		return nil, false
	elseif t.party and now >= t.partyReadyAt then
		t.parties += 1
		local trick = meal.party[math.min(t.parties, #meal.party)]
		t.party, t.rare = nil, nil -- el festejo ya incluye la alegría del pez raro
		return trick, true
	elseif t.rare then
		t.rare = nil
		return meal.rare, false
	end
	return nil, false
end

function Turnos.endBig(t: Turnos, now: number, party: boolean)
	t.bigReadyAt = now + BIG_GAP
	if party then
		t.partyReadyAt = now + PARTY_GAP
	end
end

local function pick(t: Turnos, meal: Perfil.Meal): string?
	local total = 0
	for _, entry in meal.gestures do
		if entry.name ~= t.lastGesture then
			total += entry.weight
		end
	end
	local roll = math.random() * total
	for _, entry in meal.gestures do
		if entry.name ~= t.lastGesture then
			roll -= entry.weight
			if roll <= 0 then
				return entry.name
			end
		end
	end
	return if #meal.gestures > 0 then meal.gestures[1].name else nil
end

-- El gesto que toca ahora (o nil) y si es el saludo para el jugador local.
function Turnos.nextGesture(t: Turnos, meal: Perfil.Meal, now: number): (string?, boolean)
	if now - t.lastFed > GESTURE_WINDOW then
		return nil, false
	end
	if t.wantWave then -- el saludo dedicado no espera el turno
		t.wantWave, t.waveAt = false, now
		t.lastGesture = "saludo"
		return "saludo", true
	end
	if now < t.nextGestureAt then
		return nil, false
	end
	local name = t.boost or pick(t, meal)
	t.boost, t.lastGesture = nil, name
	return name, false
end

function Turnos.endGesture(t: Turnos, meal: Perfil.Meal, now: number)
	t.nextGestureAt = now + meal.gap * meal.tempo * (0.7 + 0.6 * math.random())
end

-- "start" si paró de comer (traga con la cabeza), "sound" si lleva muchos seguidos.
function Turnos.gulp(t: Turnos, now: number): string?
	if t.gulps > 0 and now - t.lastFed > GULP_AFTER then
		t.gulps = 0
		return "start"
	elseif t.gulps >= GULP_EVERY then
		t.gulps = 0
		return "sound"
	end
	return nil
end

local function yawOf(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z)
end

-- Cuánto girar para mirar al jugador local (rad, 0 si no le está dando).
function Turnos.look(t: Turnos, center: Vector3, yaw: number, now: number): number
	local from = t.lookFrom
	if not from or now > t.lookUntil then
		return 0
	end
	local flat = Vector3.new(from.X - center.X, 0, from.Z - center.Z)
	if flat.Magnitude < 1 then
		return 0
	end
	local turn = (yawOf(flat) - yaw + math.pi) % (2 * math.pi) - math.pi
	return math.clamp(turn, -LOOK_MAX, LOOK_MAX)
end

return table.freeze(Turnos)
