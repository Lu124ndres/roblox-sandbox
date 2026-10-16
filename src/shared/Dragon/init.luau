--!strict
--[[
	Dragon (DragonMotion)

	El motor que hace volar al dragón sobre el volcán (solo en el cliente):
		- vuela en vueltas sobre la lava, sube y baja, se ladea en las curvas
		  y planea al bajar (Vuelo: el mismo recorrido en todos los clientes);
		- cada tanto hace un truco de su etapa (Trucos, sincronizados);
		- cuando alguien le da de comer deja su vuelta, va hasta quedar frente
		  a la orilla de quien lo alimenta, se queda en el aire aleteando con
		  la boca abierta y muerde cada pez que llega (bite);
		- anima sus huesos (Pose) según la etapa (Etapas, por el modelo).
	step devuelve el pivote del modelo. DragonFx lee `state` y sus `events`.
	El largo del dragón es LENGTH x el alto de su etapa (GiantTemplates escala
	así a los modelos con alas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GiantStages = require(script.Parent.GiantStages)
local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Cuerpo = require(script.Cuerpo)
local Etapas = require(script.Etapas)
local Pose = require(script.Pose)
local Rig = require(script.Rig)
local Rumbo = require(script.Rumbo)
local Trucos = require(script.Trucos)
local Vuelo = require(script.Vuelo)

local L_ = WorldLayout
local WATER = L_.waterLevel
local RIM = L_.craterRimHeight
local BITE_SECONDS = 0.18

local Tipos = require(script.Tipos)

export type Event = Tipos.Event
export type State = Tipos.State
export type Info = Tipos.Info
export type Motion = Tipos.Motion

local Dragon = {}

Dragon.LENGTH = 0.6

function Dragon.new(lakeCenter: Vector3): Motion
	local origin = Vector3.new(lakeCenter.X, 0, lakeCenter.Z)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(origin)
	local state: State = {
		center = origin + Vector3.new(0, RIM + 30, 0),
		velocity = Vector3.zero,
		yaw = 0,
		length = 10,
		feeding = 0,
		fire = false,
		phase = 0,
		hidden = false,
		voice = 1,
		fireSize = 1,
		events = {},
		rig = nil,
	}
	local profile = Etapas.forModel(nil)
	local rigFor: Model? = nil
	local stage = 1
	local rumbo = Rumbo.new()
	local wings = Cuerpo.new()
	local lastSlot, lastU = -1, 0
	local biteUntil = 0

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
		local L = math.max(info.height * Dragon.LENGTH, 1)
		local Lpath = GiantStages.heightFor(stage) * Dragon.LENGTH -- fijo por etapa: la vuelta no salta al crecer
		local radius = math.clamp(L_.craterLakeRadius * 0.6 - Lpath * 0.2, 25, 130)
		local speed = (20 + Lpath * 0.3) * profile.speed
		local base = RIM + 16 + Lpath * 0.3
		local sample = Vuelo.sample(now, origin, radius, base, 10 + Lpath * 0.12, speed)

		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local direction = if active then feeders.direction() else nil
		state.feeding += ((if direction then 1 else 0) - state.feeding) * (1 - math.exp(
			-dt * (if direction then 1.2 else 0.6)
		))
		local w = state.feeding * state.feeding * (3 - 2 * state.feeding)

		local trick, u, slot = nil, 0, -1
		if active and w < 0.05 then
			trick, u, slot = Trucos.current(now, profile)
		end
		local t: Trucos.Pose = if trick then trick.pose(u, Lpath) else {}
		if trick then
			if slot ~= lastSlot then
				lastSlot, lastU = slot, 0
			end
			for _, event in trick.events do
				if event.at > lastU and event.at <= u then
					table.insert(state.events, { kind = event.kind })
				end
			end
			lastU = u
		end

		-- Adónde va: su vuelta (con el truco) o frente a quien le da de comer.
		local goal = sample.position + Vector3.new(0, t.dy or 0, 0)
		if direction then
			local standoff = L_.craterCliffRadius - 12 - Lpath * 0.45
			local hoverAt = origin
				+ direction * math.max(standoff, 20)
				+ Vector3.new(0, RIM + 4 + Lpath * 0.22, 0)
			goal = goal:Lerp(hoverAt, w)
		end
		Rumbo.update(rumbo, dt, {
			goal = goal,
			flow = sample.velocity * (t.speed or 1),
			feeding = w,
			face = direction,
			bank = profile.bank,
			pitch = t.pitch or 0,
			roll = t.roll,
		})
		local climb = rumbo.climb
		local gliding = math.clamp(-climb * 3 - (1 - profile.glide * 2), 0, 1) * (1 - w)
		Cuerpo.update(wings, dt, profile, {
			now = now,
			gliding = gliding,
			feeding = w,
			anger = info.anger,
			trick = t,
			biting = os.clock() < biteUntil,
		})
		state.fire, state.phase = t.fire == true, wings.phase

		local rig = state.rig
		if rig then
			Pose.apply(rig, {
				profile = profile,
				now = now,
				phase = wings.phase,
				amp = wings.amp,
				neutral = profile.neutral,
				fold = wings.fold,
				turn = rumbo.yawRate,
				climb = climb,
				jaw = wings.jaw,
				headPitch = (t.head or 0) - 0.15 * w,
				headYaw = 0,
				hover = wings.hover,
			})
		end

		local bob = -math.cos(wings.phase) * L * 0.02 * wings.amp
		state.center = (rumbo.position :: Vector3) + Vector3.new(0, bob + info.lift, 0)
		state.velocity, state.yaw, state.length = rumbo.velocity, rumbo.yaw, L
		state.voice, state.fireSize = profile.voice, profile.fire
		state.hidden = info.lift < -L
		local body = CFrame.new(state.center)
			* CFrame.Angles(0, rumbo.yaw + math.rad(info.spin), 0)
			* CFrame.Angles(rumbo.pitch, 0, 0)
			* CFrame.Angles(0, 0, rumbo.roll)
		return if rig then body * Rig.frame(rig):Inverse() else body
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
			return Vector3.new(state.center.X, WATER, state.center.Z)
		end,
		bite = function()
			biteUntil = os.clock() + BITE_SECONDS
		end,
		destroy = feeders.destroy,
	}
end

return table.freeze(Dragon)
