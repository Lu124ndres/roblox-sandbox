--!strict
--[[
	Dragon/Rutina

	Qué hace el dragón cuando nadie le da de comer, igual en todos los clientes:
	todo sale de la hora del servidor y de Minotauro/Azar (un hash de la vuelta),
	sin estado. El tiempo se parte en vueltas de rutina.cycle segundos
	(Dragon/Habitos); en la vuelta c, si Azar(c) < perch:
		fly       vuela sus vueltas sobre la lava (Dragon/Vuelo) al menos MIN_FLY s
		approach  baja hasta una roca de Dragon/Guarida (el nido a veces) en un
		          tramo suave que sale tangente a la vuelta y llega mirando hacia
		          afuera del cráter (hacia la gente); dura lo que pida la distancia
		stay      posado: se asienta y hace sus posturas (Dragon/Estadia); si
		          duerme, el final de la estadía es dormir
		takeoff   se agacha (TAKEOFF_CROUCH s por el pace) y salta, y sube en un
		          tramo suave que vuelve a la vuelta justo al terminar la vuelta c
	Si no le toca, vuela toda la vuelta. plan() dice el tramo, dónde tiene que
	estar la raíz (posado: a ras de la cima; Dragon/Posado la sube hasta que las
	patas apoyan), su velocidad, hacia dónde mira posado y qué postura toca.
	body: stand (studs de la raíz sobre la cima, de pie) y ahead (cuánto queda la
	raíz delante del centro de las patas): los mide Dragon/Rig del modelo.
]]

local Azar = require(script.Parent.Parent.Minotauro.Azar)
local Etapas = require(script.Parent.Etapas)
local Guarida = require(script.Parent.Guarida)
local Estadia = require(script.Parent.Estadia)
local Posturas = require(script.Parent.Posturas)
local Vuelo = require(script.Parent.Vuelo)

export type Mode = "fly" | "approach" | "stay" | "takeoff"
export type Body = { stand: number, ahead: number }
export type Timeline = {
	cycle: number,
	perch: number, -- índice en Guarida.perches
	top: Vector3, -- cima donde apoyan las patas
	spot: Vector3, -- dónde va la raíz posada (a ras de la cima)
	facing: number, -- yaw posado (mira hacia afuera)
	approachAt: number,
	landAt: number,
	takeoffAt: number,
	crouch: number,
	endAt: number,
	sleeps: boolean,
	from: Vuelo.Sample,
	to: Vuelo.Sample,
}
export type Plan = {
	key: number, -- vuelta con posada (c + 1; 0 = vuela toda la vuelta)
	mode: Mode,
	line: Timeline?,
	position: Vector3,
	velocity: Vector3,
	k: number, -- avance del tramo approach (0..1) o segundos desde el despegue
	behavior: Posturas.Behavior?,
	u: number,
	ctx: Posturas.Ctx,
}

local MIN_FLY = 6
local APPROACH = { 4, 9 } -- s: lo más corto y lo más largo
local AIR = { 3, 8 }
local TAKEOFF_CROUCH = 0.75

local Rutina = {}

-- La posada de la vuelta c, o nil si esa vuelta vuela entera.
function Rutina.timeline(
	c: number,
	profile: Etapas.Profile,
	route: Vuelo.Route,
	body: Body
): Timeline?
	local r = profile.rutina
	if Azar.unit(c, 1) >= r.perch then
		return nil
	end
	local perches = Guarida.perches
	local index = if Azar.unit(c, 2) < r.nest then 1 else 1 + Azar.pick(#perches - 1, c, 3)
	local perch = perches[index]
	local sleeps = Azar.unit(c, 6) < r.sleep * (if index == 1 then 1 else 0.5)
	local top = Guarida.point(perch)
	if index == Guarida.nest.perch then
		top += Guarida.nest.offset
	end
	local angle = if perch.radius > 0 then perch.angle else Azar.unit(c, 5) * math.pi * 2
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local spot = top + out * body.ahead
	local endAt = (c + 1) * r.cycle
	local to = Vuelo.sample(endAt, route)
	local crouch = TAKEOFF_CROUCH * profile.pace
	local air = math.clamp((to.position - spot).Magnitude / route.speed * 1.25, AIR[1], AIR[2])
	local takeoffAt = endAt - crouch - air
	local stay = r.stay * (0.75 + 0.5 * Azar.unit(c, 4)) * (if sleeps then 1.4 else 1)
	local approachAt = math.max(takeoffAt - stay - APPROACH[2], c * r.cycle + MIN_FLY)
	local from = Vuelo.sample(approachAt, route)
	local seconds =
		math.clamp((from.position - spot).Magnitude / route.speed * 1.3, APPROACH[1], APPROACH[2])
	return {
		cycle = c,
		perch = index,
		top = top,
		spot = spot,
		facing = math.atan2(-out.X, -out.Z),
		approachAt = approachAt,
		landAt = approachAt + seconds,
		takeoffAt = takeoffAt,
		crouch = crouch,
		endAt = endAt,
		sleeps = sleeps,
		from = from,
		to = to,
	}
end

-- Si a esa hora está volando su vuelta (para los trucos).
function Rutina.flying(
	now: number,
	profile: Etapas.Profile,
	route: Vuelo.Route,
	body: Body
): boolean
	local line = Rutina.timeline(math.floor(now / profile.rutina.cycle), profile, route, body)
	return line == nil or now < line.approachAt - 0.5 or now > line.endAt
end

function Rutina.plan(now: number, profile: Etapas.Profile, route: Vuelo.Route, body: Body): Plan
	local c = math.floor(now / profile.rutina.cycle)
	local line = Rutina.timeline(c, profile, route, body)
	local flight = Vuelo.sample(now, route)
	local plan: Plan = {
		key = 0,
		mode = "fly",
		line = nil,
		position = flight.position,
		velocity = flight.velocity,
		k = 0,
		behavior = nil,
		u = 0,
		ctx = { profile = profile, seed = 0, seconds = 1 },
	}
	if not line or now < line.approachAt then
		return plan
	end
	plan.key, plan.line = c + 1, line
	local land = line.spot + Vector3.new(0, body.stand * 0.85, 0)
	if now < line.landAt then
		local out = Vector3.new(-math.sin(line.facing), 0, -math.cos(line.facing))
		local arrive = out * (route.speed * 0.12) - Vector3.new(0, route.speed * 0.08, 0)
		local seconds = line.landAt - line.approachAt
		plan.mode, plan.k = "approach", (now - line.approachAt) / seconds
		local s =
			Vuelo.hermite(line.from.position, line.from.velocity, land, arrive, seconds, plan.k)
		plan.position, plan.velocity = s.position, s.velocity
	elseif now < line.takeoffAt then
		plan.mode, plan.position, plan.velocity = "stay", line.spot, Vector3.zero
		plan.behavior, plan.u, plan.ctx = Estadia.schedule(line, now, profile)
	else
		plan.mode, plan.k = "takeoff", now - line.takeoffAt
		plan.position, plan.velocity = line.spot, Vector3.zero
		local airAt = line.takeoffAt + line.crouch
		if now > airAt then
			local out = Vector3.new(-math.sin(line.facing), 0, -math.cos(line.facing))
			local jump = (out * 0.35 + Vector3.yAxis) * route.speed * 0.9
			local lift = line.spot + Vector3.new(0, body.stand, 0)
			local s = Vuelo.hermite(
				lift,
				jump,
				line.to.position,
				line.to.velocity,
				line.endAt - airAt,
				(now - airAt) / (line.endAt - airAt)
			)
			plan.position, plan.velocity = s.position, s.velocity
		end
	end
	return plan
end

return table.freeze(Rutina)
