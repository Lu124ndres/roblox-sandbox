--!strict
--[[
	OrcaMotion

	El motor que mueve a la orca en el lago del Cráter del Abismo (solo en el
	cliente). Cómo se mueve depende de su etapa (Etapas: un script por etapa,
	elegido por el modelo), pero todas:
		- nadan dando vueltas al azar y salen a respirar (Path: el mismo
		  recorrido en todos los clientes, sale de la hora del servidor);
		- de vez en cuando hacen un truco de su etapa (Tricks), también
		  sincronizado por la hora del servidor;
		- cuando alguien les da de comer (Feeders) dejan su recorrido, nadan
		  hacia la orilla de quien las alimenta, sacan la cabeza y abren la
		  boca; cada pez que llega las hace morder (bite).
	step devuelve el pivote del modelo cada cuadro y anima sus huesos (Rig;
	altura, cabeceo y boca en Body). OrcaFx lee `state` y sus `events`.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(script.Parent.Parent.Protocol)
local WorldLayout = require(script.Parent.Parent.WorldLayout)
local Etapas = require(script.Parent.Etapas)
local Perfil = require(script.Parent.Etapas.Perfil)
local Body = require(script.Body)
local Feeders = require(script.Feeders)
local Path = require(script.Path)
local Rig = require(script.Rig)
local Schedule = require(script.Schedule)
local Steer = require(script.Steer)
local Tricks = require(script.Tricks)

local L = WorldLayout
local WATER = L.waterLevel
local LAKE = L.craterLakeRadius + 4 -- hasta el pie del acantilado
local BITE_SECONDS = 0.16

export type Event = Schedule.Event
export type State = {
	center: Vector3, -- centro del cuerpo en el mundo
	vy: number, -- studs/s hacia arriba
	speed: number,
	yaw: number,
	height: number,
	feeding: number, -- 0..1
	breath: number, -- ciclo de respirar (0 = en la superficie)
	trick: string?, -- nombre del truco que está haciendo
	hidden: boolean, -- escondida bajo el lago (descanso)
	voice: number, -- tono de sus llamados (etapa)
	events: { Event }, -- lo que pasó este cuadro (OrcaFx los consume)
	rig: Rig.Rig?,
}
export type Info = { height: number, lift: number, spin: number, anger: number, inner: Model? }
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	mouth: () -> Vector3,
	top: () -> Vector3,
	water: () -> Vector3,
	point: (name: string) -> Vector3?,
	bite: () -> (),
	destroy: () -> (),
}

local OrcaMotion = {}

function OrcaMotion.new(lakeCenter: Vector3): Motion
	local origin = Vector3.new(lakeCenter.X, 0, lakeCenter.Z)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(origin)
	local state: State = {
		center = origin + Vector3.new(0, WATER, 0),
		vy = 0,
		speed = 0,
		yaw = 0,
		height = 1,
		feeding = 0,
		breath = 0,
		trick = nil,
		hidden = false,
		voice = 1,
		events = {},
		rig = nil,
	}
	local profile: Perfil.Profile = Etapas.forModel(nil)
	local swim: Steer.Steer? = nil
	local body: Body.Body? = nil
	local rigFor: Model? = nil
	local biteUntil = 0
	local schedule = Schedule.new()

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local height = math.max(info.height, 1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then -- al crecer cambia el modelo: otros huesos y otra etapa
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			profile = Etapas.forModel(if info.inner then info.inner.Name else nil)
		end
		local radius = Path.radius(LAKE, height)
		local cruise = Path.speed(height) * profile.swim.speed * (1 + info.anger * 0.5)
		local sample = Path.sample(now, radius, cruise, profile.breath)
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local direction = if active then feeders.direction() else nil
		local rate = if direction then 1.5 else 0.7
		state.feeding += ((if direction then 1 else 0) - state.feeding) * (1 - math.exp(-dt * rate))

		-- Truco del tramo (sincronizado en todos los clientes) y sus eventos.
		local allowed = active and state.feeding < 0.05 and not state.hidden
		local doing = Schedule.step(schedule, dt, now, profile, sample.depth, allowed, state.events)
		local weight = doing.weight
		local trickPose: Tricks.Pose = doing.pose or {}
		local boost = 1 + ((trickPose.speed or 1) - 1) * weight

		-- En el plano: su recorrido, o la orilla de quien le da de comer.
		if not swim or not body then -- quien entra a mitad de partida la ve ya en su recorrido
			swim = Steer.new(sample.position, sample.velocity)
			body = Body.new(sample.depth * height)
		end
		local steer, shape = swim :: Steer.Steer, body :: Body.Body
		local goal = if direction then direction * radius * 0.92 else sample.position
		local close = if direction
			then math.clamp(1 - (goal - steer.position).Magnitude / height, 0, 1)
			else 0
		Steer.update(
			steer,
			dt,
			goal,
			if direction then Vector3.zero else sample.velocity * boost,
			cruise * boost * (if direction then 2.4 else 1.7),
			if direction and close > 0.3 then direction else nil,
			if radius < 1 then now * 0.1 else nil -- las etapas enormes giran en el centro
		)
		local speed = steer.velocity.Magnitude
		local turn = steer.turn + schedule.yawRate
		Body.step(shape, dt, {
			profile = profile,
			height = height,
			now = now,
			cruiseDepth = sample.depth,
			floor = Path.floor(steer.position.Magnitude, L) + 0.2 * height,
			speed = speed,
			cruise = cruise,
			turn = turn,
			feeding = state.feeding,
			close = close,
			trick = doing.pose,
			weight = weight,
			biting = os.clock() < biteUntil,
			anger = info.anger,
			rig = state.rig, -- y anima los huesos
		})

		state.height, state.speed, state.yaw, state.vy = height, speed, steer.yaw, shape.vy
		state.breath, state.voice = sample.breath, profile.voice
		state.trick = doing.name
		state.hidden = info.lift < -height * 1.5
		state.center = origin + steer.position + Vector3.new(0, WATER + shape.depth + info.lift, 0)
		local center = if state.rig then state.rig.center else 0.45
		return CFrame.new(state.center)
			* CFrame.Angles(0, steer.yaw + schedule.yaw + math.rad(info.spin), 0)
			* CFrame.Angles(shape.pitch, 0, 0)
			* CFrame.Angles(0, 0, shape.roll)
			* CFrame.new(0, -height * center, 0)
	end

	local function point(name: string): Vector3?
		return Rig.point(state.rig, name)
	end

	return {
		state = state,
		step = step,
		point = point,
		mouth = function(): Vector3
			local look = Vector3.new(-math.sin(state.yaw), 0, -math.cos(state.yaw))
			return point("Boca") or state.center + look * state.height * 0.6
		end,
		top = function(): Vector3
			return point("Espiraculo") or state.center + Vector3.new(0, state.height * 0.4, 0)
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

return table.freeze(OrcaMotion)
