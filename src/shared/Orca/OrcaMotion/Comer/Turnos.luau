--!strict
--[[
	OrcaMotion/Comer/Turnos

	Qué le toca hacer a la orca mientras come (Comer lo pregunta cada cuadro):
		- festejo de combo cuando la racha llega a un número (Festejos.due),
		  cada vez más grande (canto, coletazo a la orilla, tirabuzón...); el
		  que llega antes de PARTY_GAP s queda pendiente;
		- con un pez raro (rareza >= RARE_FROM): primero la sorpresa y después
		  una de tres reacciones (salto chico al lado, giro de costado o
		  aletazo con la pectoral); los más raros, siempre el salto;
		- gesto de gusto cada `gap` s de la etapa, por peso y sin repetir el
		  anterior, solo cuando no viene otro pez (no se distrae al comer); un
		  pez poco común adelanta el chorro y el jugador local recibe un
		  saludo dedicado (cada WAVE_EVERY s a lo sumo);
		- tragar fuerte cuando paran los peces o cada GULP_EVERY peces.
	El azar sale de Azar con la cuenta de peces (todos eligen lo mismo); los
	tiempos, de os.clock.
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Tricks = require(script.Parent.Parent.Tricks)
local Azar = require(script.Parent.Azar)
local Festejos = require(script.Parent.Festejos)

local PARTY_GAP = 5 -- s entre festejos
local BIG_GAP = 1.2 -- s entre reacciones grandes (se ven los bocados y gestos)
local PARTY_KEEP = 8 -- s que espera un festejo pendiente
local RARE_FROM = 3 -- índice de rareza (Raro) desde el que reacciona
local RARE_KEEP = 6
local SURPRISE_SECONDS = 0.5 -- la sorpresa va antes de la reacción
local GESTURE_WINDOW = 3 -- s desde el último pez en que todavía hace gestos
local GULP_AFTER = 0.6 -- s sin peces: traga fuerte
local GULP_EVERY = 12
local LOOK_SECONDS = 2.5 -- s que mira al jugador local después de su pez
local WAVE_EVERY = 6
-- Reacción a un pez raro (los Épicos o más raros, siempre el salto): salto chico al
-- lado, giro de costado (panza) o aletazo con la pectoral.
local RARE_CHOICES = {
	{ name = "salto", weight = 2 },
	{ name = "panza", weight = 1 },
	{ name = "aletazo", weight = 1 },
}

export type Info = { from: Vector3, rarity: number, isLocal: boolean, streak: number }
export type Turnos = {
	count: number, -- peces que comió (la semilla del azar)
	lastFed: number,
	streak: number,
	from: Vector3?, -- de dónde vino el último
	lastGesture: string?,
	nextGestureAt: number,
	boost: string?, -- gesto adelantado
	urgent: boolean, -- el adelantado no espera turno (reacción a un pez raro)
	gulps: number,
	rare: { power: number, at: number }?,
	party: number?, -- cuándo le tocó el festejo pendiente
	parties: number, -- festejos de esta racha
	partyReadyAt: number,
	bigReadyAt: number,
	lookFrom: Vector3?, -- el jugador local, mientras le da
	lookUntil: number,
	waveAt: number,
	wantWave: boolean,
}

local Turnos = {}

function Turnos.new(): Turnos
	return {
		count = 0,
		lastFed = -math.huge,
		streak = 0,
		nextGestureAt = 0,
		urgent = false,
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
	t.lastFed, t.from, t.streak = now, info.from, info.streak
	t.count += 1
	t.gulps += 1
	if info.streak <= 1 then -- racha nueva: vuelve a empezar por el festejo chico
		t.parties = 0
	end
	if Festejos.due(info.streak) then
		t.party = now
	end
	local power = math.max(0, info.rarity - RARE_FROM + 1)
	if power > 0 then
		local choice = Azar.pick(t.count, RARE_CHOICES, function(c)
			return c.weight
		end)
		if power >= 2 or not choice or choice.name == "salto" then
			if not t.rare or power >= t.rare.power then
				t.rare = { power = power, at = now }
			end
		else
			t.boost, t.urgent = choice.name, true
		end
		t.bigReadyAt = math.max(t.bigReadyAt, now + SURPRISE_SECONDS)
	elseif info.rarity == RARE_FROM - 1 and not t.boost then
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

-- El gesto que toca ahora (o nil). `free`: no viene otro pez ni está tragando
-- (los de gusto y el saludo esperan a eso; las reacciones a un pez raro, no).
function Turnos.nextGesture(t: Turnos, meal: Perfil.Meal, now: number, free: boolean): string?
	if t.urgent and t.boost and now >= t.bigReadyAt then
		local name = t.boost
		t.boost, t.urgent, t.lastGesture = nil, false, name
		return name
	elseif not free or now - t.lastFed > GESTURE_WINDOW then
		return nil
	elseif t.wantWave then -- el saludo dedicado no espera el turno
		t.wantWave, t.waveAt, t.lastGesture = false, now, "saludo"
		return "saludo"
	elseif now < t.nextGestureAt then
		return nil
	end
	local entry = Azar.pick(t.count + 0.5, meal.gestures, function(g: Perfil.Gesture)
		return if g.name == t.lastGesture then 0 else g.weight
	end)
	local name = t.boost or (if entry then entry.name else nil)
	t.boost, t.lastGesture = nil, name
	return name
end

function Turnos.endGesture(t: Turnos, meal: Perfil.Meal, now: number)
	t.nextGestureAt = now + meal.gap * meal.tempo * (0.7 + 0.6 * Azar.hash(t.count + 0.25))
end

-- "start" si paró de comer (traga fuerte), "sound" si lleva muchos seguidos.
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

-- El jugador local, si le está dando de comer (para que lo mire a él).
function Turnos.localFeeder(t: Turnos, now: number): Vector3?
	return if now <= t.lookUntil then t.lookFrom else nil
end

return table.freeze(Turnos)
