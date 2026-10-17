--!strict
--[[
	Minotauro (MinotauroMotion)

	El minotauro en el fondo del cráter (solo en el cliente):
		- respira, se mece, mueve la cola y las orejas y mira alrededor (Pose);
		- cuando nadie le da de comer sigue su rutina (Rutina, Conducta): pasea
		  entre lugares del cráter (Caminar, con el paso de su etapa), se sienta
		  (y sentado se rasca, bosteza, mira o dormita), olfatea el suelo, se
		  estira, mira al cielo o a alguien y hace sus trucos (Posturas, Trucos).
		  Todo sale de la hora del servidor: todos los clientes lo ven igual;
		- darle de comer manda: deja lo que hacía (sentado, se para), CAMINA hasta
		  esa orilla, se inclina, estira los brazos y mastica; cada pez (fed) lo
		  muerde y le saca una reacción (Comer); después vuelve a su rutina;
		- al evolucionar (EstadoGigante.EvolucionHasta) junta fuerza, explota
		  hacia arriba y ruge (Evolucion);
		- apoya siempre el pie más bajo en el suelo (Cuerpo) y orejas, cola,
		  mandíbula y faldón siguen al cuerpo con retraso (Resortes).
	El ritmo, la voz, la fuerza, la rutina y el paso salen de la etapa (Etapas,
	por el nombre del modelo). Solo anima huesos si el modelo los tiene; si no,
	solo gira y camina. step devuelve el pivote (base, -Z al frente).
	state.events (MinoStand los vuelve sonido y efectos): step, stomp, roar, land,
	flex, happy, sit, standup, snort, yawn, sniff, evolve (el destello va
	Evolucion.BURST después) y los de Comer.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Caminar = require(script.Caminar)
local Comer = require(script.Comer)
local Conducta = require(script.Conducta)
local Cuerpo = require(script.Cuerpo)
local Etapas = require(script.Etapas)
local Evolucion = require(script.Evolucion)
local Pose = require(script.Pose)
local Posturas = require(script.Posturas)
local Resortes = require(script.Resortes)
local Rig = require(script.Rig)
local Rutina = require(script.Rutina)

local BITE_SECONDS = 0.16
local ANGRY = Config.Giants.anger.angryThreshold

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
	fed: (info: Comer.Fed) -> (),
	destroy: () -> (),
}

local Minotauro = {}

function Minotauro.new(center: Vector3): Motion
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(Vector3.new(center.X, 0, center.Z))
	local state: State =
		{ events = {}, rig = nil, profile = Etapas.forModel(nil), height = 10, center = center }
	local rigFor: Model? = nil
	local yaw, stepPhase, feeding = 0, 0, 0
	local walk = Caminar.new()
	local springs = Resortes.new()
	local conducta = Conducta.new()
	local evolving = Evolucion.watch(stateFolder)
	local biteUntil, ready, first, comer = 0, false, true, Comer.new()

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			state.profile = Etapas.forModel(if info.inner then info.inner.Name else nil)
		end
		local profile = state.profile
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local evolveT = evolving(now, state.events)
		local direction = if active and not evolveT then feeders.direction() else nil
		local free = active and not direction and not evolveT and info.anger < ANGRY
		local plan = Rutina.plan(now, profile, info.height)
		if first then -- recién lo ve: donde los demás ya lo ven
			first = false
			walk.offset = plan.from:Lerp(plan.spot, if plan.walking then plan.progress else 1)
			yaw = plan.facing
		end
		local routine, busy = Conducta.step(conducta, plan, dt, free, ready, state.events)

		-- Camina: a su lugar de la rutina, a la orilla de quien le da de comer o al centro.
		local goal = plan.spot
		if busy or evolveT or info.anger >= ANGRY then
			goal = walk.offset -- se queda donde está
		elseif direction then
			goal = Caminar.standFor(direction, info.height)
		elseif not active then
			goal = Vector3.zero
		end
		local gait = if free then profile.rutina.gait else 1
		local anchor = if free then plan.from else nil
		local moving, heading, stepped = Caminar.update(walk, dt, goal, info.height, gait, anchor)
		if stepped then
			table.insert(state.events, { kind = "step" })
		end
		local eats = if direction and not busy then 1 else 0
		feeding += (eats - feeding) * (1 - math.exp(-dt * 2.5))
		local w = feeding * feeding * (3 - 2 * feeding) * (1 - moving) -- come cuando llega

		-- Hacia dónde mira: adonde camina, quien le da de comer o lo que pide la rutina.
		local target = yaw
		local playing = conducta.playing
		if heading and moving > 0.15 then
			target = Caminar.angleTowards(heading)
		elseif direction then
			target = Caminar.angleTowards(direction)
		elseif playing and playing.looks then
			local toward = Posturas.lookAt(conducta.key, center + walk.offset)
			target = if toward then Caminar.angleTowards(toward) else yaw
		elseif free and not busy then
			target = plan.facing
		end
		local turn, turning = Caminar.turn(yaw, target, profile.turnSpeed, dt)
		yaw += turn
		stepPhase += dt * 7 * (if turning > 0.05 then 1 else 0)
		ready = moving < 0.05 and turning < 0.15 and (goal - walk.offset).Magnitude < 1

		local weight = if evolveT then 0 else (1 - 0.6 * moving) * (1 - info.anger)
		local pivot = CFrame.new(state.center) * CFrame.Angles(0, yaw, 0)
		local react, takes = Comer.step(comer, profile, pivot, info.height, weight, state.events)
		local pose = Pose.idle(now, profile)
		Pose.add(pose, Pose.feeding(w * (1 - takes), now, os.clock() < biteUntil))
		Pose.add(pose, react)
		Pose.add(pose, Pose.steps(stepPhase, turning * (1 - moving)))
		Pose.add(pose, Pose.walk(walk.phase, moving, profile.paso))
		local mad = info.anger
		Pose.add(pose, { lean = -0.12 * mad, earL = -0.5 * mad, earR = -0.5 * mad })
		if routine then
			Pose.add(pose, routine)
		end
		if evolveT then
			Pose.add(pose, Evolucion.pose(evolveT))
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
		fed = function(fed: Comer.Fed)
			biteUntil = os.clock() + BITE_SECONDS
			Comer.fed(comer, fed)
		end,
		destroy = feeders.destroy,
	}
end

return table.freeze(Minotauro)
