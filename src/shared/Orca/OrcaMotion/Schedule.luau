--!strict
--[[
	OrcaMotion/Schedule

	Qué truco está haciendo la orca ahora (Path.trick, igual en todos los
	clientes), su pose y cuánto manda (entra y sale suave). Dispara los
	eventos del truco (sonidos y efectos de OrcaFx) una sola vez, cuando el
	avance pasa por su momento, y lleva el desvío de rumbo de los trucos que
	giran (persigue su cola, mira a los lados) para doblar la cola en el giro.
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Path = require(script.Parent.Path)
local Tricks = require(script.Parent.Tricks)

local BLEND = 0.12 -- parte del truco que se usa para entrar y salir de él

-- spot: un punto del mundo (de dónde vino el pez); size: fuerza (rareza del pez).
export type Event = { kind: string, where: string?, spot: Vector3?, size: number? }
export type Schedule = {
	slot: number,
	progress: number,
	yaw: number, -- desvío del rumbo (rad)
	yawRate: number, -- rad/s (suavizado)
}
export type Now = {
	name: string?,
	pose: Tricks.Pose?,
	weight: number, -- 0..1
}

local Schedule = {}

function Schedule.new(): Schedule
	return { slot = -1, progress = 0, yaw = 0, yawRate = 0 }
end

-- allowed: puede hacer trucos (no está comiendo ni escondida).
function Schedule.step(
	schedule: Schedule,
	dt: number,
	now: number,
	profile: Perfil.Profile,
	from: number,
	allowed: boolean,
	events: { Event }
): Now
	local index, u, slot = 0, 0, -1
	if allowed then
		index, u, slot = Path.trick(now, profile.trickEvery, profile.trickChance, profile.tricks)
	end
	local trick = if index > 0 then profile.tricks[index].trick else nil
	local pose: Tricks.Pose? = nil
	local weight = 0
	if trick then
		if slot ~= schedule.slot then
			schedule.slot, schedule.progress = slot, 0
		end
		for _, event in trick.events do
			if event.at > schedule.progress and event.at <= u then
				table.insert(events, { kind = event.kind, where = event.where })
			end
		end
		schedule.progress = u
		pose = trick.pose(u, from)
		weight = Tricks.smooth(u / BLEND) * Tricks.smooth((1 - u) / BLEND)
	end
	-- Las vueltas completas terminan donde empezaron: el desvío vuelve a 0 sin saltos.
	local yaw = if pose and pose.yaw then pose.yaw else 0
	schedule.yawRate += ((yaw - schedule.yaw) / dt - schedule.yawRate) * (1 - math.exp(-dt * 6))
	schedule.yaw = yaw
	return { name = if trick then trick.name else nil, pose = pose, weight = weight }
end

return table.freeze(Schedule)
