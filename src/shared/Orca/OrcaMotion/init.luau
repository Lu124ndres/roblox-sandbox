--!strict
--[[
	OrcaMotion

	Cómo se mueve la orca en el lago del Cráter del Abismo (solo en el cliente):
		- nada dando vueltas al azar y sale a respirar (Path: el mismo recorrido
		  en todos los clientes, sale de la hora del servidor);
		- de repente salta fuera del agua y da una vuelta en el aire;
		- cuando alguien le da de comer (Feeders) deja su recorrido, nada hacia
		  la orilla de quien la alimenta, saca la cabeza del agua y abre la boca;
		  cada pez que llega la hace morder (bite). Al terminar vuelve a nadar.
	step devuelve el pivote del modelo cada cuadro y anima sus huesos (Rig).
	OrcaFx lee `state` para los sonidos y efectos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(script.Parent.Parent.Protocol)
local WorldLayout = require(script.Parent.Parent.WorldLayout)
local Feeders = require(script.Feeders)
local Path = require(script.Path)
local Rig = require(script.Rig)
local Steer = require(script.Steer)

local WATER = WorldLayout.waterLevel
local LAKE = WorldLayout.craterLakeRadius + 4 -- hasta el pie del acantilado
local CENTER_HEIGHT = 0.39 -- centro del cuerpo (hueso Raiz) sobre la base, en altos del modelo
local FEED_RISE = 0.14 -- al comer el centro sube a este alto sobre el agua
local FEED_PITCH = 0.68 -- y levanta la cabeza (rad)
local BITE_SECONDS = 0.16

export type State = {
	center: Vector3, -- centro del cuerpo en el mundo
	vy: number, -- studs/s hacia arriba
	speed: number,
	yaw: number,
	height: number,
	feeding: number, -- 0..1
	jaw: number, -- 0..1
	breath: number, -- ciclo de respirar (0 = en la superficie)
	breach: number, -- -1 o el avance del salto
	hidden: boolean, -- escondida bajo el lago (descanso)
	rig: Rig.Rig?,
}
export type Info = { height: number, lift: number, spin: number, anger: number, inner: Model? }
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	mouth: () -> Vector3,
	top: () -> Vector3,
	water: () -> Vector3,
	bite: () -> (),
	destroy: () -> (),
}

local OrcaMotion = {}

local function ease(dt: number, rate: number): number
	return 1 - math.exp(-dt * rate)
end

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
		jaw = 0,
		breath = 0,
		breach = -1,
		hidden = false,
		rig = nil,
	}
	local swim: Steer.Steer? = nil
	local depth, pitch, roll, phase, biteUntil = 0, 0, 0, 0, 0
	local rigFor: Model? = nil

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local height = math.max(info.height, 1)
		local now = Workspace:GetServerTimeNow()
		local radius = Path.radius(LAKE, height)
		local cruise = Path.speed(height) * (1 + info.anger * 0.5)
		local sample = Path.sample(now, radius, cruise, height)
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local direction = if active then feeders.direction() else nil
		local target = if direction then 1 else 0
		state.feeding += (target - state.feeding) * ease(dt, if direction then 1.5 else 0.7)

		-- En el plano: sigue su recorrido, o va a la orilla de quien le da de comer.
		if not swim then -- quien entra a mitad de partida la ve ya en su recorrido
			swim = Steer.new(sample.position, sample.velocity)
			depth = sample.depth
		end
		local steer = swim :: Steer.Steer
		local goal = if direction then direction * radius * 0.92 else sample.position
		local close = if direction
			then math.clamp(1 - (goal - steer.position).Magnitude / height, 0, 1)
			else 0
		Steer.update(
			steer,
			dt,
			goal,
			if direction then Vector3.zero else sample.velocity,
			cruise * (if direction then 2.4 else 1.7),
			if direction and close > 0.3 then direction else nil,
			if radius < 1 then now * 0.12 else nil -- las etapas enormes giran en el centro
		)
		local speed = steer.velocity.Magnitude

		-- En altura: respira, salta o saca la cabeza para comer.
		local breach = if active and state.feeding < 0.05 then sample.breach else -1
		local wantDepth, wantPitch, wantRoll
		if breach >= 0 then
			wantDepth, wantPitch, wantRoll = Path.breachPose(breach, height, sample.depth)
		else
			local rise = state.feeding * close
			wantDepth = sample.depth
				+ (height * FEED_RISE - sample.depth) * rise
				+ math.sin(now * 2) * 0.03 * height * rise
			wantPitch = math.atan2(state.vy, math.max(speed, 2)) * 0.8 * (1 - rise)
				+ FEED_PITCH * rise
			wantRoll = math.clamp(steer.turn * 0.5, -0.4, 0.4)
				+ math.sin(now * 23) * info.anger * 0.05
		end
		-- No se mete en el fondo del lago (las etapas enormes flotan más alto).
		local floor = -(36 - 10 * (steer.position.Magnitude / LAKE) ^ 2) + 0.2 * height
		local sharp = if breach >= 0 then 12 else 2.5
		local before = depth
		depth += (math.max(wantDepth, floor) - depth) * ease(dt, sharp)
		state.vy = (depth - before) / dt
		pitch += (wantPitch - pitch) * ease(dt, sharp)
		roll = if breach >= 0 then wantRoll else roll + (wantRoll - roll) * ease(dt, 3)

		-- Boca: abierta al comer (se cierra un instante en cada mordida), entreabierta al saltar.
		local wantJaw = if state.feeding > 0.5
			then 0.8 + 0.2 * math.sin(now * 2.6)
			elseif breach > 0.3 and breach < 0.7 then 0.5
			else 0
		if os.clock() < biteUntil then
			wantJaw = 0
		end
		state.jaw += (wantJaw - state.jaw) * ease(dt, 14)

		-- Huesos (el modelo cambia al crecer: se enlaza de nuevo).
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
		end
		local air = breach > 0.22 and breach < 0.82
		local effort = if air
			then 0.2
			else (0.5 + speed / cruise * 0.7 + info.anger * 0.4) * (1 - 0.5 * close)
		phase += dt * math.pi * 2 * (0.4 + speed / (height * 1.5) * 0.9 + info.anger * 0.6)
		local fins = if air then 0.45 else -0.25 * state.feeding -- pegadas al saltar, abiertas al comer
		if state.rig then
			Rig.apply(state.rig, phase, effort, steer.turn, state.jaw, fins, 0.12 * close)
		end

		state.height, state.speed, state.yaw = height, speed, steer.yaw
		state.breath, state.breach = sample.breath, breach
		state.hidden = info.lift < -height * 1.5
		state.center = origin + steer.position + Vector3.new(0, WATER + depth + info.lift, 0)
		return CFrame.new(state.center)
			* CFrame.Angles(0, steer.yaw + math.rad(info.spin), 0)
			* CFrame.Angles(pitch, 0, 0)
			* CFrame.Angles(0, 0, roll)
			* CFrame.new(0, -height * CENTER_HEIGHT, 0)
	end

	return {
		state = state,
		step = step,
		mouth = function(): Vector3
			local look = Vector3.new(-math.sin(state.yaw), 0, -math.cos(state.yaw))
			return Rig.point(state.rig, "Boca") or state.center + look * state.height * 0.6
		end,
		top = function(): Vector3
			return Rig.point(state.rig, "Espiraculo")
				or state.center + Vector3.new(0, state.height * 0.4, 0)
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
