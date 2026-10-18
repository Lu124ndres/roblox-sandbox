--!strict
--[[
	Zorro (ZorroMotion)

	El zorro de agua en su lago de hielo (solo en el cliente). Cada cuadro:
		1. Rutina dice dónde está, hacia dónde mira, si camina y qué conducta hace
		   (igual en todos los clientes: sale de la hora del servidor); Rumbo lo
		   sigue o, si algo lo saca de la rutina, camina por su cuenta (Cuadro.meta):
		   comer manda (deja lo que hace, gira o va hacia esa orilla y después vuelve),
		   con el lago vacío va al centro y al evolucionar se queda de frente;
		2. Rutina/Capas arma la pose (reposo, comer, evolución, conducta, paso y
		   enojo) y hace 3. Mirada.add, 4. Pose.apply y 5. Colas.step.
	step devuelve el pivote (base, -Z al frente). state.events: lo que ZorroStand
	convierte en sonido y efectos; state.stepped: cuántas patas acaban de pisar;
	state.trail: 0..1, deja estela de agua (corre). info.detail: cámara cerca;
	info.ice: el hábitat es de hielo (va en los eventos).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Protocol = require(script.Parent.Protocol)
local WorldLayout = require(script.Parent.WorldLayout)
local Feeders = require(script.Parent.Orca.OrcaMotion.Feeders)
local Colas = require(script.Colas)
local Traduccion = require(script.Colas.Traduccion)
local Comer = require(script.Comer)
local Capas = require(script.Rutina.Capas)
local Cuadro = require(script.Rutina.Cuadro)
local Etapas = require(script.Etapas)
local Evolucion = require(script.Evolucion)
local Habitos = require(script.Habitos)
local Mirada = require(script.Mirada)
local Pivote = require(script.Comer.Pivote)
local Rig = require(script.Rig)
local Rumbo = require(script.Rumbo)
local Rutina = require(script.Rutina)
local Sonidos = require(script.Rutina.Sonidos)

local BITE_SECONDS = 0.16
local WATER = WorldLayout.waterLevel
local ANGRY = Config.Giants.anger.angryThreshold
local CALM = 4 -- 1/s: qué tan rápido se apagan y vuelven las conductas al comer o enojarse

export type Event = Sonidos.Evento
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
	lookAt: Vector3?,
	ice: boolean?,
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

function Zorro.new(center: Vector3): Motion
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local feeders = Feeders.watch(Vector3.new(center.X, 0, center.Z))
	local state: State = {
		events = {},
		rig = nil,
		colas = nil,
		height = 10,
		center = Vector3.new(center.X, WATER, center.Z),
		fan = 0,
		stepped = 0,
		trail = 0,
	}
	local comer, tracking, rumbo = Comer.new(), Traduccion.new(), Rumbo.new()
	local evolving = Evolucion.watch(stateFolder)
	local sonidos, mirada = Sonidos.new(), Mirada.new()
	local rigFor: Model? = nil
	local etapa, stepPhase, feeding, calm, biteUntil = 1, 0, 0, 1, 0

	local function step(dt: number, info: Info): CFrame
		dt = math.clamp(dt, 1 / 240, 0.1)
		local now = Workspace:GetServerTimeNow()
		if info.inner ~= rigFor then
			rigFor = info.inner
			state.rig = if info.inner then Rig.bind(info.inner) else nil
			state.colas = Colas.forModel(state.rig, info.inner)
			etapa = Etapas.forModel(if info.inner then info.inner.Name else nil).etapa
		end
		local phaseName = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		local active = phaseName == nil or phaseName == "feeding"
		local evolveT = evolving(now, state.events)
		local direction = if active and not evolveT then feeders.direction() else nil
		feeding += ((if direction then 1 else 0) - feeding) * (1 - math.exp(-dt * 2))
		local w = feeding * feeding * (3 - 2 * feeding)

		-- 1. Dónde está y qué hace (la rutina, o lo que lo saca de ella).
		local plan = Rutina.plan(now, etapa, info.height, Rutina.conductas())
		local meta = Cuadro.meta(state.center, direction, active, evolveT ~= nil, info.height)
		local paso = Rumbo.step(rumbo, plan, meta, info.height, etapa, dt)
		local quiet = direction == nil and comer.big == nil and info.anger < ANGRY
		calm += ((if quiet then 1 else 0) - calm) * (1 - math.exp(-dt * CALM))
		local weight = paso.weight * calm * (if evolveT then 0 else 1)
		local conducta = plan.conducta
		local act = if conducta and weight > 0.01 then conducta.pose(plan.u, etapa, plan.r) else nil

		-- 2. La pose.
		local radius = Pivote.radius(state.center, info.height)
		local extra, body = Comer.step(comer, os.clock(), info.height, radius)
		stepPhase += dt * 6 * (if paso.turning > 0.05 then 1 else 0)
		local pose = Capas.armar({
			now = now,
			paso = paso,
			act = act,
			weight = weight,
			extra = extra,
			take = body.take,
			look = body.look,
			eating = w,
			biting = os.clock() < biteUntil,
			evolve = if evolveT then Evolucion.pose(evolveT) else nil,
			stepPhase = stepPhase,
			anger = info.anger,
		})

		-- Eventos; la base: la cima del témpano o el agua, más saltos, sentarse...
		local heading = paso.yaw + math.rad(info.spin)
		Pivote.look(pose, body, state.center, state.height, heading + body.spin)
		local pisadas, comidas = Habitos.de(etapa).pisadas, Comer.drain(comer)
		local stepped =
			Sonidos.emit(sonidos, state.events, comidas, plan, paso, weight, pisadas, info.ice)
		state.stepped = if body.stepped then 2 else stepped
		state.trail = body.trail
		state.fan += (math.clamp(pose.tailFan or 0, 0, 1) - state.fan) * (1 - math.exp(-dt * 4))
		state.height = info.height
		local drop = Cuadro.bajada(pose)
		local base = paso.position + Vector3.new(0, info.lift + drop * info.height, 0)
		local placed, pivot = Pivote.build(base, heading, body, info.height)
		state.center = placed

		-- 3-5. Mirada, huesos y colas (con el cuerpo real).
		Capas.aplicar(state.rig, state.colas, tracking, mirada, pose, {
			now = now,
			dt = dt,
			etapa = etapa,
			height = info.height,
			center = placed,
			heading = heading + body.spin,
			lookAt = info.lookAt,
			detail = info.detail ~= false,
		}, paso.giro + body.turn, drop, info.anger)
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
			return Vector3.new(state.center.X, WATER, state.center.Z)
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
