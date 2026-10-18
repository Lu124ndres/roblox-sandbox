--!strict
--[[
	Zorro/Comer/Capas

	Cómo se reproduce una reacción (Clip) en el tiempo:
		start   la arranca ahora, con el tiempo y el salto de la etapa
		play    la avanza: suma su pose con un peso y dispara sus eventos
		retire / fades   apaga las que se van, cada una desde el peso que tenía (dos
		        reemplazos seguidos no cortan de golpe la primera)
		stageFor  la etapa más cercana al alto actual
	Peso por etapa: PACE estira los tiempos (la E4 tarda 40 % más: más pesada,
	anticipación más larga) y LIFT baja los saltos (la E4 salta menos en
	proporción). Qué reacción hace cada etapa lo decide Comer/Elegir.
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local GiantStages = require(script.Parent.Parent.Parent.GiantStages)

local PACE = { 1, 1.12, 1.25, 1.4 }
local LIFT = { 0.22, 0.21, 0.19, 0.17 }

export type Clip = Clip.Clip
export type Out = { kind: string, power: number, side: number }
export type Playing = {
	clip: Clip.Clip,
	start: number,
	seconds: number,
	ctx: Clip.Ctx,
	lastU: number,
	weight: number, -- cuánto pesa su pose (un bocado durante una grande, menos)
}
-- Una que se va (la reemplazó otra): se apaga desde el peso que tenía (from).
export type Fade = { p: Playing, at: number, from: number }

local NONE: { Out } = {} -- las que se van no disparan eventos

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
		ctx = {
			side = side,
			lift = LIFT[stage],
			radius = radius,
			rarity = rarity,
			stage = stage,
		},
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

-- p deja su lugar (entraba desde fadeStart) y se apaga desde el peso que tenía.
-- Devuelve desde cuándo entra la que la reemplaza (-inf: entra entera, no hay
-- ninguna apagándose).
function Capas.retire(
	list: { Fade },
	p: Playing?,
	now: number,
	fadeStart: number,
	seconds: number
): number
	if p then
		table.insert(list, { p = p, at = now, from = Curvas.smooth((now - fadeStart) / seconds) })
	end
	return if #list > 0 then now else -math.huge
end

function Capas.fades(list: { Fade }, now: number, pose: Pose.Pose, seconds: number)
	for i = #list, 1, -1 do
		local f = list[i]
		local w = f.from * (1 - Curvas.smooth((now - f.at) / seconds))
		if w <= 0 or not Capas.play(NONE, f.p, now, pose, w * f.p.weight, false) then
			table.remove(list, i)
		end
	end
end

return table.freeze(Capas)
