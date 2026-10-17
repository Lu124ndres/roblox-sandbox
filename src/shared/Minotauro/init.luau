--!strict
--[[
	Minotauro (MinotauroMotion)

	El minotauro en el centro del cráter (solo en el cliente):
		- respira, se mece, mueve la cola y las orejas y mira alrededor (Pose);
		- cada tanto se da vuelta con pasitos para mirar a otro lado (todos los
		  clientes lo ven igual: sale de la hora del servidor);
		- cuando alguien le da de comer CAMINA hasta esa orilla (Caminar), se
		  inclina, estira los brazos y mastica; cada pez que llega lo muerde (bite);
		  cuando dejan de darle vuelve caminando al centro; cada pisada salpica;
		- entre comidas hace trucos sincronizados (Trucos): pisotón, rugido,
		  músculo, baile, rascarse y salto;
		- apoya siempre el pie más bajo en el suelo (Cuerpo) y orejas, cola,
		  mandíbula y faldón siguen al cuerpo con retraso (Resortes).
	El ritmo, la voz, la fuerza y los trucos salen de la etapa (Etapas, por el
	nombre del modelo). Solo anima huesos si el modelo los tiene; si no, solo
	gira y salta. step devuelve el pivote (base, -Z al frente).
	state.events: lo que MinoStand convierte en sonido y efectos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Caminar = require(script.Caminar)
local Cuerpo = require(script.Cuerpo)
local Etapas = require(script.Etapas)
local Pose = require(script.Pose)
local Resortes = require(script.Resortes)
local Rig = require(script.Rig)
local Trucos = require(script.Trucos)

local LOOK_EVERY = 16 -- segundos entre vueltas para mirar a otro lado
local BITE_SECONDS = 0.16

export type Event = { kind: string }
export type State = {
	events: { Event },
	rig: Rig.Rig?,
	profile: Etapas.Profile,
	height: number,
	center: Vector3,
}
export type Info = { height: number, lift: number, spin: number, anger: number, inner: Model? }
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	top: () -> Vector3,
	mouth: () -> Vector3,
	water: () -> Vector3,
	bite: () -> (),
	destroy: () -> (),
}

local Minotauro = {}

local function angleTowards(d: Vector3): number
	return math.atan2(-d.X, -d.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

function Minotauro.new(center: Vector3): Motion
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(Vector3.new(center.X, 0, center.Z))
	local state: State =
		{ events = {}, rig = nil, profile = Etapas.forModel(nil), height = 10, center = center }
	local rigFor: Model? = nil
	local yaw, stepPhase, feeding = 0, 0, 0
	local walk = Caminar.new()
	local springs = Resortes.new()
	local biteUntil = 0
	local lastSlot, lastU = -1, 0

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			state.profile = Etapas.forModel(if info.inner then info.inner.Name else nil)
		end
		local profile = state.profile
		local turnSpeed = profile.turnSpeed
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local direction = if active then feeders.direction() else nil
		feeding += ((if direction then 1 else 0) - feeding) * (1 - math.exp(-dt * 2.5))
		local w = feeding * feeding * (3 - 2 * feeding)

		-- Camina: hasta la orilla de quien le da de comer, o de vuelta al centro.
		local goal = if direction then Caminar.standFor(direction, info.height) else Vector3.zero
		local moving, heading, stepped = Caminar.update(walk, dt, goal, info.height)
		if stepped then
			table.insert(state.events, { kind = "step" })
		end
		w *= 1 - moving -- come cuando llega, no mientras camina

		-- Hacia dónde mira: adonde camina, quien le da de comer o, cada tanto, otro lado.
		local target: number
		if heading and moving > 0.15 then
			target = angleTowards(heading)
		elseif direction then
			target = angleTowards(direction)
		else
			local slot = math.floor(now / LOOK_EVERY)
			target = ((slot * 2654435761) % 1000) / 1000 * math.pi * 2
		end
		local delta = (target - yaw + math.pi) % (math.pi * 2) - math.pi
		local turn = math.clamp(delta * 3, -turnSpeed, turnSpeed) * dt
		yaw += turn
		local turning = math.clamp(math.abs(turn / dt) / turnSpeed * 1.6, 0, 1)
		stepPhase += dt * 7 * (if turning > 0.05 then 1 else 0)

		local pose = Pose.idle(now, profile)
		Pose.add(pose, Pose.feeding(w, now, os.clock() < biteUntil))
		Pose.add(pose, Pose.steps(stepPhase, turning * (1 - moving)))
		Pose.add(pose, Pose.walk(walk.phase, moving))
		Pose.add(
			pose,
			{ lean = -0.12 * info.anger, earL = -0.5 * info.anger, earR = -0.5 * info.anger }
		)
		local trick, u, slot = nil, 0, -1
		if active and w < 0.05 and turning < 0.1 and moving < 0.05 then
			trick, u, slot = Trucos.current(now, profile)
		end
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
			Pose.add(pose, trick.pose(u))
		end
		local rig = state.rig
		if rig then
			Cuerpo.plant(pose, profile.body)
			Resortes.step(springs, pose, dt, turn / dt, profile)
			Pose.apply(rig, pose)
		end
		state.height = info.height
		local dy = (pose.dy or 0) * info.height
		state.center = center + walk.offset + Vector3.new(0, info.lift + dy, 0)
		return CFrame.new(state.center) * CFrame.Angles(0, yaw + math.rad(info.spin), 0)
	end

	local function point(name: string): Vector3?
		return Rig.point(state.rig, name)
	end
	return {
		state = state,
		step = step,
		top = function(): Vector3
			local head = point("Cabeza")
			return if head
				then head + Vector3.new(0, state.height * 0.22, 0)
				else state.center + Vector3.new(0, state.height * 0.92, 0)
		end,
		mouth = function(): Vector3
			return point("Boca") or state.center + Vector3.new(0, state.height * 0.7, 0)
		end,
		water = function(): Vector3
			return Vector3.new(state.center.X, WorldLayout.waterLevel, state.center.Z)
		end,
		bite = function()
			biteUntil = os.clock() + BITE_SECONDS
		end,
		destroy = feeders.destroy,
	}
end

return table.freeze(Minotauro)
