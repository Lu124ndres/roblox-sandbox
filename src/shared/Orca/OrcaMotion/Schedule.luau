--!strict
--[[
	OrcaMotion/Schedule

	Qué truco está haciendo la orca ahora (Tricks/Agenda, igual en todos los
	clientes), su pose y cuánto manda (entra y sale suave). Dispara los
	eventos del truco (sonidos y efectos de OrcaFx) una sola vez, cuando el
	avance pasa por su momento, y lleva el desvío de rumbo de los trucos que
	giran (mirar a los lados, girar hacia la rampa) para doblar la cola en el giro.
		- `aim` (opcional): hacia dónde queda la rampa. `aim.at(t)` es cuánto
		  tendría que girar a la hora t, según su recorrido, para mirarla; con
		  eso los trucos de lucirse eligen cuándo empezar. `aim.now` es cuánto
		  tiene que girar ahora (rad, + = a la izquierda): las poses con `face`
		  giran el cuerpo hacia ella (o le muestran el costado, con `flank`).
		- `sounding` (opcional): el avance (0..1) de la inmersión larga del
		  recorrido; mientras dure, hace la zambullida de su etapa
		  (profile.sounding). Si ya está en otro truco, lo termina primero.
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Agenda = require(script.Parent.Tricks.Agenda)
local Tricks = require(script.Parent.Tricks)

local BLEND_SECONDS = 1.2 -- entra y sale del truco en este tiempo
local BLEND_MAX = 0.2 -- y nunca en más de esta parte del truco
local SOUND = -1 -- clave del truco de la inmersión larga
local LATE = 0.03 -- un truco que ya pasó de esta parte no se empieza

-- spot: un punto del mundo (de dónde vino el pez); size: fuerza (rareza del pez).
export type Event = { kind: string, where: string?, spot: Vector3?, size: number? }
export type Aim = {
	at: (t: number) -> number, -- cuánto giraría a la hora t para mirar la rampa (rad, + = izq.)
	now: number, -- y ahora, desde su rumbo actual
	floor: ((t: number) -> number)?, -- fondo bajo su recorrido a la hora t (altos, < 0)
}
export type Schedule = {
	key: number?, -- tramo del truco en curso (SOUND = la inmersión larga)
	progress: number,
	yaw: number, -- desvío del rumbo (rad)
	yawRate: number, -- rad/s (suavizado)
	aim0: number?, -- giro hacia la rampa al empezar (para no saltar de lado en ±pi)
	plans: { [number]: Agenda.Plan | false }, -- planes de los tramos ya mirados
	planned: Perfil.Profile?, -- la etapa de esos planes (al crecer se rehacen)
}
export type Now = {
	name: string?,
	pose: Tricks.Pose?,
	weight: number, -- 0..1
}

local Schedule = {}

function Schedule.new(): Schedule
	return { key = nil, progress = 0, yaw = 0, yawRate = 0, aim0 = nil, plans = {}, planned = nil }
end

-- El plan del tramo, calculado una sola vez (así no cambia a mitad del truco).
local function planFor(
	schedule: Schedule,
	slot: number,
	profile: Perfil.Profile,
	aim: Aim?
): Agenda.Plan?
	local cached = schedule.plans[slot]
	if cached == nil then
		cached = Agenda.plan(
			slot,
			profile,
			if aim then aim.at else nil,
			if aim then aim.floor else nil
		) or false
		schedule.plans[slot] = cached
		schedule.plans[slot - 3] = nil
	end
	return if cached then cached else nil
end

-- El truco de los tramos que esté corriendo a la hora `now`.
local function current(
	schedule: Schedule,
	now: number,
	profile: Perfil.Profile,
	aim: Aim?
): (Tricks.Trick?, number, number, number)
	if schedule.planned ~= profile then
		table.clear(schedule.plans)
		schedule.planned = profile
	end
	local slot = math.floor(now / profile.trickEvery)
	local before = planFor(schedule, slot - 1, profile, aim)
	local plan = planFor(schedule, slot, profile, aim)
	if before and now < before.start + before.seconds then
		plan = before -- uno largo que todavía no termina
	elseif plan and before and plan.start < before.start + before.seconds then
		plan = nil -- se pisaría con el anterior
	end
	if not plan then
		return nil, 0, 0, 0
	end
	local u = (now - plan.start) / plan.seconds
	if u < 0 or u >= 1 then
		return nil, 0, 0, 0
	end
	return profile.tricks[plan.index].trick, u, plan.slot, plan.seed
end

-- Cuánto gira hacia la rampa (o para mostrarle el costado), sin saltar en ±pi.
local function facing(schedule: Schedule, pose: Tricks.Pose, aim: Aim?): number
	if not aim or not pose.face then
		return 0
	end
	local want = aim.now
	if pose.flank then -- el costado que quede más cerca
		local left, right = Tricks.wrap(want - math.pi / 2), Tricks.wrap(want + math.pi / 2)
		want = if math.abs(left) < math.abs(right) then left else right
	end
	local start = schedule.aim0 or want
	schedule.aim0 = start
	return (start + Tricks.wrap(want - start)) * pose.face
end

-- allowed: puede hacer trucos (no está comiendo ni escondida).
function Schedule.step(
	schedule: Schedule,
	dt: number,
	now: number,
	profile: Perfil.Profile,
	from: number,
	allowed: boolean,
	events: { Event },
	aim: Aim?,
	sounding: number?
): Now
	local trick: Tricks.Trick? = nil
	local u, seed = 0, 0.5
	local key: number? = nil
	if allowed then
		local slotTrick, slotU, slot, slotSeed = current(schedule, now, profile, aim)
		local running = slotTrick ~= nil and schedule.key == slot
		-- Uno nuevo solo si recién empieza: nunca aparece a la mitad (al dejar de comer,
		-- al volver de la inmersión larga ni al entrar a la partida).
		local fresh = slotTrick ~= nil and slotU < LATE and schedule.key ~= SOUND
		if sounding and profile.sounding and not running then
			trick, u, key = profile.sounding, sounding, SOUND
		elseif running or fresh then
			trick, u, key, seed = slotTrick, slotU, slot, slotSeed
		end
	end
	local pose: Tricks.Pose? = nil
	local weight = 0
	if trick then
		if key ~= schedule.key then
			schedule.key, schedule.progress, schedule.aim0 = key, u, nil
		end
		for _, event in trick.events do
			if event.at > schedule.progress and event.at <= u then
				table.insert(events, { kind = event.kind, where = event.where, size = event.size })
			end
		end
		schedule.progress = u
		pose = trick.pose(u, from, seed)
		local blend = math.min(BLEND_MAX, BLEND_SECONDS / trick.seconds)
		weight = Tricks.smooth(u / blend) * Tricks.smooth((1 - u) / blend)
	else
		schedule.key = nil
	end
	-- Las vueltas completas terminan donde empezaron: el desvío vuelve a 0 sin saltos.
	local yaw = if pose then (pose.yaw or 0) + facing(schedule, pose, aim) else 0
	schedule.yawRate += ((yaw - schedule.yaw) / dt - schedule.yawRate) * (1 - math.exp(-dt * 6))
	schedule.yaw = yaw
	return { name = if trick then trick.name else nil, pose = pose, weight = weight }
end

return table.freeze(Schedule)
