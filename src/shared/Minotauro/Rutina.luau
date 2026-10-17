--!strict
--[[
	Minotauro/Rutina

	Qué hace el minotauro cuando nadie le da de comer, igual en todos los
	clientes: todo sale de la hora del servidor (Workspace:GetServerTimeNow) y de
	Minotauro/Azar, sin estado. El tiempo se parte en estadías de rutina.cycle
	segundos (Minotauro/Etapas); en la estadía c:
		1. camina del lugar de la estadía c - 1 al de la c (Caminar, a paso de
		   paseo); lo que tarda sale de Caminar.eta, la misma cuenta del paso;
		2. con rutina.gap segundos quieto entre una y otra, hace hasta rutina.stay
		   posturas de rutina.list (Minotauro/Posturas), cada una elegida con
		   Azar(c, i) y con su duración por el pace de la etapa; si la siguiente no
		   entra antes de que termine la estadía, se queda mirando alrededor.
	Los lugares giran alrededor del cráter (cada uno ~1 rad más allá del anterior,
	con algo de azar en el ángulo y la distancia; a veces vuelve al centro), dentro
	de Caminar.roamRadius: la parte rutina.roam del radio libre, que se achica con
	el alto. Así ningún paseo es más largo que ~1.6 radios y no hace falta saber
	las estadías anteriores. En cada lugar mira hacia donde venía caminando, con
	algo de azar.
	plan devuelve dónde tiene que estar, hacia dónde mirar y qué postura toca
	(behavior, su avance u, cuánto lleva en ella y una clave única por vez).
]]

local Azar = require(script.Parent.Azar)
local Caminar = require(script.Parent.Caminar)
local Etapas = require(script.Parent.Etapas)
local Posturas = require(script.Parent.Posturas)

export type Plan = {
	cycle: number,
	from: Vector3,
	spot: Vector3,
	facing: number,
	walking: boolean,
	progress: number, -- del paseo, 0..1
	behavior: Posturas.Behavior?,
	key: number, -- única por postura y estadía (0 si no hay)
	u: number,
	elapsed: number, -- segundos desde que empezó la postura
	ctx: Posturas.Ctx,
}

local TURN = 1 -- rad que avanza cada lugar alrededor del cráter
local CENTER_CHANCE = 0.12 -- a veces vuelve al centro
local MAX_STAY = 8 -- posturas por estadía (para la clave)

local Rutina = {}

-- El lugar de la estadía c (respecto del centro del cráter).
function Rutina.spot(c: number, rutina: Etapas.Rutina, height: number): Vector3
	if Azar.unit(c, 3) < CENTER_CHANCE then
		return Vector3.zero
	end
	local angle = c * TURN + (Azar.unit(c, 1) - 0.5) * 0.7
	local radius = Caminar.roamRadius(height, rutina.roam) * (0.35 + 0.65 * Azar.unit(c, 2))
	return Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
end

function Rutina.plan(now: number, profile: Etapas.Profile, height: number): Plan
	local rutina = profile.rutina
	local c = math.floor(now / rutina.cycle)
	local t = now - c * rutina.cycle
	local from, spot = Rutina.spot(c - 1, rutina, height), Rutina.spot(c, rutina, height)
	local trip = spot - from
	local walkFor = Caminar.eta(trip.Magnitude, height, rutina.gait)
	local heading = if trip.Magnitude > 1
		then Caminar.angleTowards(trip)
		else Azar.unit(c, 4) * math.pi * 2
	local plan: Plan = {
		cycle = c,
		from = from,
		spot = spot,
		facing = heading + (Azar.unit(c, 5) - 0.5) * 1.2,
		walking = t < walkFor,
		progress = if walkFor > 0 then math.min(t / walkFor, 1) else 1,
		behavior = nil,
		key = 0,
		u = 0,
		elapsed = 0,
		ctx = { profile = profile, seed = 0 },
	}
	if plan.walking then
		return plan
	end
	local cursor = walkFor + rutina.gap
	for i = 1, math.min(rutina.stay, MAX_STAY - 1) do
		local seed = c * MAX_STAY + i
		local behavior = Posturas.pick(rutina.list[Azar.pick(#rutina.list, c, i)], profile, seed)
		if not behavior then
			continue
		end
		local seconds = behavior.seconds * profile.pace
		if t < cursor or cursor + seconds > rutina.cycle then
			break
		end
		if t < cursor + seconds then
			plan.behavior, plan.key = behavior, seed
			plan.elapsed = t - cursor
			plan.u = plan.elapsed / seconds
			plan.ctx.seed = seed
			break
		end
		cursor += seconds + rutina.gap
	end
	return plan
end

return table.freeze(Rutina)
