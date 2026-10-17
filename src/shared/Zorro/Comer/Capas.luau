--!strict
--[[
	Zorro/Comer/Capas

	Cómo se reproduce una reacción (Clip) en el tiempo:
		start   la arranca ahora, con el tiempo y el salto de la etapa
		play    la avanza: suma su pose con un peso y dispara sus eventos
		stageFor  la etapa más cercana al alto actual
	Peso por etapa: PACE estira los tiempos (la E4 tarda 40 % más: más pesada,
	anticipación más larga) y LIFT baja los saltos (la E4 salta menos en
	proporción). El modelo es el mismo en las cuatro etapas: cambia el peso.
]]

local Clip = require(script.Parent.Clip)
local Pose = require(script.Parent.Parent.Pose)
local GiantStages = require(script.Parent.Parent.Parent.GiantStages)

local PACE = { 1, 1.12, 1.25, 1.4 }
local LIFT = { 0.22, 0.21, 0.19, 0.17 }

export type Out = { kind: string, power: number, side: number }
export type Playing = {
	clip: Clip.Clip,
	start: number,
	seconds: number,
	ctx: Clip.Ctx,
	lastU: number,
	weight: number, -- cuánto pesa su pose (un bocado durante una grande, menos)
}

local Capas = {}

Capas.PACE = PACE

-- Etapa más cercana al alto actual (al crecer, el alto pasa de una a otra).
function Capas.stageFor(height: number): number
	local best, distance = 1, math.huge
	for stage = 1, GiantStages.count do
		local d = math.abs(math.log(height / GiantStages.heightFor(stage)))
		if d < distance then
			best, distance = stage, d
		end
	end
	return math.clamp(best, 1, #PACE)
end

function Capas.start(
	clip: Clip.Clip,
	now: number,
	stage: number,
	side: number,
	radius: number,
	rarity: number
): Playing
	return {
		clip = clip,
		start = now,
		seconds = clip.seconds * PACE[stage],
		ctx = { side = side, lift = LIFT[stage], radius = radius, rarity = rarity },
		lastU = 0,
		weight = 1,
	}
end

-- Avanza p, suma su pose con peso k y, si fire, pone sus eventos en queue.
-- Devuelve false cuando ya terminó.
function Capas.play(
	queue: { Out },
	p: Playing,
	now: number,
	pose: Pose.Pose,
	k: number,
	fire: boolean
): boolean
	local u = math.min(1, (now - p.start) / p.seconds)
	if fire then
		for _, e in p.clip.events do
			local rare = e.rare
			if e.at > p.lastU and e.at <= u and (rare == nil or p.ctx.rarity >= rare) then
				table.insert(queue, { kind = e.kind, power = p.ctx.rarity, side = p.ctx.side })
			end
		end
		p.lastU = u
	end
	if u >= 1 then
		return false
	end
	Pose.add(pose, p.clip.pose(u, p.ctx), k)
	return true
end

return table.freeze(Capas)
