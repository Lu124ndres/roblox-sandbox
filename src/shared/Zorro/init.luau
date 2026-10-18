--!strict
--[[
	Zorro (ZorroMotion)

	El zorro de agua en el centro del cráter, parado SOBRE el agua (solo en el cliente):
		- respira, pasa el peso, mueve las orejas y mira alrededor (Pose); sus colas
		  las mueve Colas con lo que piden la pose y el cuerpo (Colas/Traduccion);
		- cada tanto se da vuelta con pasos cruzados para mirar a otro lado (todos los
		  clientes lo ven igual: sale de la hora del servidor);
		- cuando alguien le da de comer gira hacia esa orilla, baja el pecho, abre la
		  boca y menea las colas; cada pez que llega (fed) lo atrapa con su
		  animación especial (Comer: bocados, peces raros, combos y el gesto al
		  jugador de este cliente), que puede girarlo, darlo vuelta o hacerlo
		  correr en círculo;
		- entre comidas hace trucos sincronizados (Trucos): aullido, abanico, salto,
		  sacudida, reverencia y fuegos fatuos.
	step devuelve el pivote (base, -Z al frente). state.events: lo que ZorroStand
	convierte en sonido y efectos; state.stepped: cuántas patas acaban de pisar;
	state.trail: 0..1, deja estela de agua (corre). info.detail: cámara cerca.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Colas = require(script.Colas)
local Traduccion = require(script.Colas.Traduccion)
local Comer = require(script.Comer)
local Pivote = require(script.Comer.Pivote)
local Pose = require(script.Pose)
local Rig = require(script.Rig)
local Trucos = require(script.Trucos)

local TURN_SPEED = 0.8 -- rad/s como mucho al darse vuelta
local LOOK_EVERY = 18 -- segundos entre vueltas para mirar a otro lado
local BITE_SECONDS = 0.16
local WATER = WorldLayout.waterLevel

-- power: rareza del pez (eventos de Comer); side: 1 su izquierda, -1 su derecha.
export type Event = { kind: string, power: number?, side: number? }
export type State = {
	events: { Event },
	rig: Rig.Rig?,
	colas: Colas.Colas?,
	height: number,
	center: Vector3,
	fan: number, -- 0..1: colas abiertas (brillan más)
	stepped: number, -- patas que pisaron en este cuadro (ondas en el agua)
	trail: number, -- 0..1: corre y deja estela de agua
}
export type Info = {
	height: number,
	lift: number,
	spin: number,
	anger: number,
	inner: Model?,
	detail: boolean?,
}
export type Motion = {
	state: State,
	step: (dt: number, info: Info) -> CFrame,
	top: () -> Vector3,
	mouth: () -> Vector3,
	water: () -> Vector3,
	point: (name: string) -> Vector3?,
	bite: () -> (),
	fed: (info: Comer.Fed) -> (),
	destroy: () -> (),
}

local Zorro = {}

local function angleTowards(d: Vector3): number
	return math.atan2(-d.X, -d.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

function Zorro.new(center: Vector3): Motion
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(Vector3.new(center.X, 0, center.Z))
	local ground = Vector3.new(center.X, WATER, center.Z)
	local state: State =
		{ events = {}, rig = nil, height = 10, center = ground, fan = 0, stepped = 0, trail = 0 }
	local comer, tracking = Comer.new(), Traduccion.new()
	local rigFor: Model? = nil
	local yaw, stepPhase, feeding, turnRate, biteUntil = 0, 0, 0, 0, 0
	local lastSlot, lastU = -1, 0

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			state.colas = Colas.forModel(state.rig, info.inner)
		end
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local direction = if active then feeders.direction() else nil
		feeding += ((if direction then 1 else 0) - feeding) * (1 - math.exp(-dt * 2))
		local w = feeding * feeding * (3 - 2 * feeding)

		-- Hacia dónde mira: quien le da de comer o, cada tanto, otro lado del lago.
		local target: number
		if direction then
			target = angleTowards(direction)
		else
			local slot = math.floor(now / LOOK_EVERY)
			target = ((slot * 2654435761) % 1000) / 1000 * math.pi * 2
		end
		local delta = (target - yaw + math.pi) % (math.pi * 2) - math.pi
		local turn = math.clamp(delta * 2.5, -TURN_SPEED, TURN_SPEED) * dt
		yaw += turn
		turnRate = turn / dt
		local turning = math.clamp(math.abs(turnRate) / TURN_SPEED * 1.5, 0, 1)
		-- Pasos: cada media vuelta de la fase pisa un par de patas.
		local before = math.floor(stepPhase / math.pi)
		stepPhase += dt * 6 * (if turning > 0.05 then 1 else 0)
		state.stepped = if math.floor(stepPhase / math.pi) ~= before then 2 else 0

		local extra, body =
			Comer.step(comer, os.clock(), info.height, Pivote.radius(center, info.height))
		local pose = Pose.idle(now)
		Pose.add(pose, Pose.feeding(w * (1 - body.take), now, os.clock() < biteUntil))
		Pose.add(pose, Pose.steps(stepPhase, turning))
		local anger = info.anger
		Pose.add(pose, { earL = -0.5 * anger, earR = -0.5 * anger, lean = -0.1 * anger })
		local trick, u, slot = nil, 0, -1
		if active and w < 0.05 and turning < 0.1 and comer.big == nil then
			trick, u, slot = Trucos.current(now)
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
		Pose.add(pose, extra)
		local heading = yaw + math.rad(info.spin)
		Pivote.look(pose, body, state.center, state.height, heading + body.spin)
		for _, event in Comer.drain(comer) do
			table.insert(
				state.events,
				{ kind = event.kind, power = event.power, side = event.side }
			)
		end
		state.stepped = if body.stepped then 2 else state.stepped
		state.trail = body.trail
		state.fan += (math.clamp(pose.tailFan or 0, 0, 1) - state.fan) * (1 - math.exp(-dt * 4))
		state.height = info.height
		local dy = (pose.dy or 0) * info.height - (pose.crouch or 0) * info.height * 0.06
		local base = ground + Vector3.new(0, info.lift + dy, 0)
		local placed, pivot = Pivote.build(base, heading, body, info.height)
		state.center = placed
		local giro, rig, colas = turnRate + body.turn, state.rig, state.colas
		if rig then
			Pose.apply(rig, pose, now, giro, dt)
		end
		if colas then
			local move = Traduccion.body(tracking, pose, giro, placed, info.height, dt)
			local intent = Traduccion.intent(tracking, pose, anger, nil)
			Colas.step(colas, intent, move, now, dt, info.detail ~= false)
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
		top = function(): Vector3
			return point("Cabeza") or state.center + Vector3.new(0, state.height * 0.9, 0)
		end,
		mouth = function(): Vector3
			return point("Boca") or state.center + Vector3.new(0, state.height * 0.7, 0)
		end,
		water = function(): Vector3
			return ground
		end,
		bite = function()
			biteUntil = os.clock() + BITE_SECONDS
		end,
		fed = function(info: Comer.Fed)
			Comer.fed(comer, info, os.clock())
		end,
		destroy = feeders.destroy,
	}
end

return table.freeze(Zorro)
