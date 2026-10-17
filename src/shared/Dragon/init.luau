--!strict
--[[
	Dragon (DragonMotion)

	El dragón sobre el volcán (solo en el cliente). Sin nadie que le dé de comer
	sigue su rutina, igual en todos los clientes (Rutina, Conducta): vuela sus
	vueltas con trucos (Vuelo, Trucos) y a veces se posa en una roca de la guarida
	(Guarida, Posado) a mirar, estirarse, acicalarse, rugir o echar fuego al
	cielo, brincar o dormir (Posturas). Darle de comer manda (posado, despega):
	va frente a quien lo alimenta y se queda en el aire con la boca abierta; con
	cada pez (fed) hace su animación especial (Comer: lo atrapa, lo traga, festeja
	los peces raros y las rachas). Al evolucionar se envuelve en las alas y en el
	estallido ruge (Evolucion). step devuelve el pivote; el largo es LENGTH x el
	alto de su etapa. state.events (lo que Dragon.Fx vuelve sonido y efectos):
	ver Dragon/Tipos. state.fire dice si sale fuego ahora; state.perched, si está
	de pie.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local GiantStages = require(script.Parent.GiantStages)
local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Acto = require(script.Comer.Acto)
local Apoyo = require(script.Apoyo)
local Comer = require(script.Comer)
local Conducta = require(script.Conducta)
local Cuerpo = require(script.Cuerpo)
local Destino = require(script.Destino)
local Etapas = require(script.Etapas)
local Evolucion = require(script.Evolucion)
local Pose = require(script.Pose)
local Rig = require(script.Rig)
local Rumbo = require(script.Rumbo)
local Rutina = require(script.Rutina)
local Tipos = require(script.Tipos)
local Trucos = require(script.Trucos)
local Vuelo = require(script.Vuelo)

local L_ = WorldLayout
local RIM = L_.craterRimHeight
local BITE_SECONDS = 0.18
local ANGRY = Config.Giants.anger.angryThreshold

export type Event = Tipos.Event
export type State = Tipos.State
export type Info = Tipos.Info
export type Motion = Tipos.Motion
export type Fed = Tipos.Fed

local Dragon = {}

Dragon.LENGTH = 0.6

function Dragon.new(lakeCenter: Vector3): Motion
	local origin = Vector3.new(lakeCenter.X, 0, lakeCenter.Z)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(origin)
	local state: State = Tipos.newState(origin + Vector3.new(0, RIM + 30, 0))
	local profile = Etapas.forModel(nil)
	local rigFor: Model? = nil
	local stage = 1
	local rumbo = Rumbo.new()
	local wings = Cuerpo.new()
	local conducta = Conducta.new()
	local apoyo = Apoyo.new()
	local comer = Comer.new()
	local evolving = Evolucion.watch(stateFolder)
	local tricks: Trucos.Tracker = { slot = -1, u = 0 }
	local biteUntil = 0
	local frozen: Vector3? = nil

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			local name = if info.inner then info.inner.Name else nil
			profile = Etapas.forModel(name)
			stage = (if name then tonumber(string.match(name, "E(%d)$")) else nil) or 1
		end
		local rig = state.rig
		local L = math.max(info.height * Dragon.LENGTH, 1)
		local Lpath = GiantStages.heightFor(stage) * Dragon.LENGTH -- fijo por etapa: la vuelta no salta al crecer
		local route = Vuelo.route(origin, Lpath, profile.speed, RIM, L_.craterLakeRadius)
		local body =
			{ stand = 0.1 * Lpath, ahead = if rig then rig.feet * rig.shin * Rig.scale(rig) else 0 }

		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local evolveT = evolving(now, state.events)
		local direction = if active and not evolveT then feeders.direction() else nil
		local free = active and not direction and not evolveT and info.anger < ANGRY
		state.feeding += ((if direction then 1 else 0) - state.feeding) * (1 - math.exp(
			-dt * (if direction then 1.2 else 0.6)
		))
		local w = state.feeding * state.feeding * (3 - 2 * state.feeding)

		local plan = Rutina.plan(now, profile, route, body)
		local doing = Conducta.step(conducta, plan, now, dt, free, evolveT ~= nil, state.events)
		local p: Pose.Pose = {}
		Pose.add(p, doing.pose)
		-- Trucos: solo volando libre y si la rutina lo deja volando todo el truco.
		if free and w < 0.05 and doing.pinW == 0 and doing.ground == 0 then
			Pose.add(p, Trucos.play(tricks, now, profile, Lpath, function(at: number): boolean
				return Rutina.flying(at, profile, route, body)
			end, state.events) or {})
		end
		if evolveT then
			Pose.add(p, Evolucion.pose(evolveT))
		end
		Pose.add(p, Comer.step(comer, state, profile, stage, rumbo.yaw, evolveT ~= nil))

		frozen = if evolveT then frozen or rumbo.position else nil
		Destino.steer(rumbo, dt, {
			now = now,
			route = route,
			Lpath = Lpath,
			direction = direction,
			feeding = w,
			frozen = frozen,
			pose = p,
			doing = doing,
			profile = profile,
		})
		local ground = Apoyo.ground(apoyo, doing.ground, dt)
		local gliding = math.clamp(-rumbo.climb * 3 - (1 - profile.glide * 2), 0, 1) * (1 - w)
		Cuerpo.update(wings, dt, profile, {
			now = now,
			gliding = gliding,
			feeding = w,
			anger = info.anger,
			flap = p.flap,
			fold = p.fold or 0,
			hover = p.hover or 0,
			jaw = p.jaw or 0,
			ground = ground,
			biting = os.clock() < biteUntil or Comer.biting(comer, os.clock()),
		})
		p.jaw = wings.jaw
		state.fire, state.phase, state.fold = (p.fire or 0) > 0.5, wings.phase, wings.fold

		local placed = Apoyo.place(
			apoyo,
			rig,
			rumbo,
			doing.line,
			p,
			{ now = now, dt = dt, L = L, ground = ground, profile = profile, wings = wings }
		)
		local bob = -math.cos(wings.phase) * L * 0.02 * wings.amp
		state.center = placed.Position
			+ Vector3.new(0, bob + info.lift, 0)
			+ Acto.offset(p, placed, L, ground)
		state.velocity, state.yaw, state.length = rumbo.velocity, rumbo.yaw, L
		state.voice, state.fireSize = profile.voice, profile.fire
		state.hidden = info.lift < -L
		state.perched, state.mode = ground, if evolveT then "evolve" else plan.mode
		local bodyCF = CFrame.new(state.center)
			* CFrame.Angles(0, math.rad(info.spin), 0)
			* placed.Rotation
		local pivot = if rig then bodyCF * Rig.frame(rig):Inverse() else bodyCF
		if rig and doing.line then
			Apoyo.tail(rig, pivot, doing.line)
		end
		return pivot
	end

	local function point(name: string): Vector3?
		return Rig.point(state.rig, name)
	end
	return {
		state = state,
		step = step,
		point = point,
		mouth = function(): Vector3
			return point("Boca") or state.center
		end,
		top = function(): Vector3
			return point("Cabeza") or state.center
		end,
		water = function(): Vector3
			return Vector3.new(state.center.X, L_.waterLevel, state.center.Z)
		end,
		bite = function()
			biteUntil = os.clock() + BITE_SECONDS
		end,
		fed = function(fed: Tipos.Fed)
			Comer.fed(comer, fed)
		end,
		destroy = feeders.destroy,
	}
end

return table.freeze(Dragon)
