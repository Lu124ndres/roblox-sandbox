--!strict
--[[
	Dragon/Conducta

	Lleva, en cada cliente, si el dragón sigue la posada que pide la rutina
	(Dragon/Rutina) y qué pose y qué posición le toca por eso:
		- sigue una posada solo si al empezar la bajada está libre (nadie le da
		  de comer, no evoluciona, no está enojado), o si el cliente recién lo ve
		  (entra a la mitad, como los demás); si no, esa vuelta la vuela entera;
		- si deja de estar libre posado, despega por su cuenta (leave: la misma
		  pose de despegue, con su reloj) y suelta la rutina hasta la vuelta
		  siguiente; si estaba bajando, la suelta en el aire;
		- evolucionar posado no lo hace despegar: se queda de pie (hold) y
		  despega cuando termina, si la rutina ya no lo tiene posado;
		- la postura que corta se desvanece en FADE s (no salta);
		- los eventos de las posturas y del despegue van a `out` cuando el avance
		  pasa por ellos; al entrar a la mitad no se repiten los que ya pasaron.
	step devuelve: pose (se suma a la de vuelo), ground (cuánto pesa estar de pie:
	0 volando, 1 posado), pin (dónde tiene que estar la raíz, con su velocidad y
	cuánto manda pinW sobre el resorte de Rumbo), facing (yaw posado), line (la
	roca: para apoyar las patas y la cola) y jump (el salto al despegar solo).
]]

local C = require(script.Parent.Parent.Minotauro.Trucos.Curvas)
local Pose = require(script.Parent.Pose)
local Estadia = require(script.Parent.Estadia)
local Posturas = require(script.Parent.Posturas)
local Aire = require(script.Parent.Posturas.Aire)
local Rutina = require(script.Parent.Rutina)

local JOIN = 0.05 -- avance de la bajada hasta el que todavía se suma

export type Leave = { line: Rutina.Timeline, t: number }
export type Conducta = {
	following: number,
	skip: number,
	fresh: boolean,
	hold: Rutina.Timeline?,
	leave: Leave?,
	lastT: number,
	player: Estadia.Player,
}
export type Out = {
	pose: Pose.Pose,
	ground: number,
	pin: Vector3?,
	pinVelocity: Vector3,
	pinW: number,
	facing: number?,
	line: Rutina.Timeline?,
	jump: boolean?,
}

local Conducta = {}

function Conducta.new(): Conducta
	return {
		following = 0,
		skip = 0,
		fresh = true,
		hold = nil,
		leave = nil,
		lastT = 0,
		player = Estadia.newPlayer(),
	}
end

local function standing(line: Rutina.Timeline, pose: Pose.Pose, ground: number): Out
	return {
		pose = pose,
		ground = ground,
		pin = line.spot,
		pinVelocity = Vector3.zero,
		pinW = 1,
		facing = line.facing,
		line = line,
	}
end

function Conducta.step(
	k: Conducta,
	plan: Rutina.Plan,
	now: number,
	dt: number,
	free: boolean,
	evolving: boolean,
	out: { { kind: string } }
): Out
	local line = plan.line
	-- ¿Sigue esta posada?
	if plan.key ~= 0 and k.following ~= plan.key and k.skip ~= plan.key then
		local early = plan.mode == "approach" and plan.k < JOIN
		if free and (k.fresh or early) then
			k.following, k.hold, k.leave = plan.key, nil, nil
			k.lastT = if plan.mode == "takeoff" then plan.k else 0
		else
			k.skip = plan.key
		end
	end
	if k.following ~= 0 and (k.following ~= plan.key or not line) then
		k.following = 0
	end
	if k.following ~= 0 and line and not free and not (evolving and plan.mode == "stay") then
		local grounded = plan.mode == "stay" or (plan.mode == "takeoff" and plan.k < line.crouch)
		if evolving and grounded then
			k.hold = line -- se queda de pie mientras evoluciona
		elseif grounded then
			k.leave = { line = line, t = 0 }
		end
		k.skip, k.following = plan.key, 0
	end
	local fresh = k.fresh
	k.fresh = false
	local fadePose = Estadia.fade(k.player, dt)
	local profile = plan.ctx.profile
	-- El despegue: la pose de posado se va (ground) y se suma el salto.
	local function lifting(t: number, crouch: number): (Pose.Pose, number)
		local ground = Aire.ground(t, crouch)
		local pose: Pose.Pose = {}
		Pose.add(pose, Posturas.base(now, 3 * profile.pace), ground)
		Pose.add(pose, Aire.takeoff(t, crouch, profile.bounce))
		Pose.add(pose, fadePose)
		return pose, ground
	end

	-- Despega por su cuenta (lo cortaron posado).
	local leave = k.leave
	if leave then
		local before = leave.t
		leave.t += dt
		local crouch = leave.line.crouch * 0.6
		local o = standing(leave.line, lifting(leave.t, crouch))
		if before < crouch and leave.t >= crouch then
			table.insert(out, { kind = "takeoff" })
			o.jump = true
		end
		o.pinW = if leave.t < crouch then 1 else 0
		if leave.t > crouch + 1.2 then
			k.leave = nil
		end
		return o
	end
	-- De pie sin seguir la rutina (evolucionó posado).
	local hold = k.hold
	if hold then
		if not evolving then
			k.hold, k.leave = nil, { line = hold, t = 0 }
		end
		return standing(hold, Posturas.base(now, 3 * profile.pace), 1)
	end
	if k.following == 0 or not line then
		return { pose = fadePose, ground = 0, pinVelocity = Vector3.zero, pinW = 0 }
	elseif plan.mode == "approach" then
		local pinW = C.smooth(C.span(plan.k, 0, 0.15))
		return {
			pose = Aire.landing(plan.k),
			ground = 0,
			pin = plan.position,
			pinVelocity = plan.velocity,
			pinW = pinW,
			line = line,
		}
	elseif plan.mode == "stay" then
		local pose =
			Estadia.play(k.player, plan.behavior, plan.u, plan.ctx, now, dt, evolving, fresh, out)
		return standing(line, pose, 1)
	end
	-- Despegue de la rutina.
	local t = plan.k
	if k.lastT < line.crouch and t >= line.crouch then
		table.insert(out, { kind = "takeoff" })
	end
	k.lastT = t
	local o = standing(line, lifting(t, line.crouch))
	o.pin, o.pinVelocity = plan.position, plan.velocity
	o.facing = if o.ground > 0.5 then line.facing else nil
	return o
end

return table.freeze(Conducta)
