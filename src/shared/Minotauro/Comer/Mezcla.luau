--!strict
--[[
	Minotauro/Comer/Mezcla

	Las reacciones que están sonando a la vez (Minotauro/Comer decide cuál empieza):
		start(list, ...)   empieza una (dura seconds de la reacción por el pace de la
		                   etapa) y suelta las demás: se desvanecen en FADE segundos
		                   (por pace) sin cortar de golpe y ya no suenan
		lead(list, now)    la prioridad de la que manda y si ya deja empezar otra
		mix(list, ...)     suma sus poses (reflejadas si van hacia su derecha) y da el
		                   takes más alto; sus eventos van a `out` al pasar el avance
		                   por ellos (glow con la rareza: "glow3" .. "glow6"); devuelve
		                   la lista sin las que terminaron
	takes entra y sale con la reacción (hold): la pose de comer vuelve suave.
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local FADE = 0.3 -- s: lo que tarda en soltar una reacción cuando empieza otra
local OVERLAP = 0.75 -- avance desde el que una reacción deja empezar la siguiente

export type Playing = {
	move: Tipos.Move,
	start: number,
	seconds: number,
	side: number,
	last: number,
	fadeAt: number?,
	glow: number,
}

local Mezcla = {}

function Mezcla.start(
	list: { Playing },
	move: Tipos.Move,
	side: number,
	now: number,
	pace: number,
	glow: number?
)
	for _, p in list do
		p.fadeAt = p.fadeAt or now
	end
	table.insert(list, {
		move = move,
		start = now,
		seconds = move.seconds * pace,
		side = side,
		last = -1,
		fadeAt = nil,
		glow = glow or 0,
	})
end

-- La prioridad de la reacción que manda (la última que empezó; 0 si no hay) y si ya
-- deja empezar otra: pasó OVERLAP y todos sus eventos (no se corta un eructo).
function Mezcla.lead(list: { Playing }, now: number): (number, boolean)
	local lead = list[#list]
	if not lead or lead.fadeAt then
		return 0, true
	end
	local free = OVERLAP
	for _, event in lead.move.events do
		free = math.max(free, event.at + 0.02)
	end
	return lead.move.prio, (now - lead.start) / lead.seconds >= free
end

function Mezcla.mix(
	list: { Playing },
	now: number,
	pace: number,
	ctx: Tipos.Ctx,
	out: { { kind: string } }
): ({ Playing }, Pose.Pose, number)
	local pose: Pose.Pose, takes = {}, 0
	local keep: { Playing } = {}
	for _, p in list do
		local u = math.min(1, (now - p.start) / p.seconds)
		local k = if p.fadeAt then 1 - C.smooth((now - p.fadeAt) / (FADE * pace)) else 1
		if not p.fadeAt then
			for _, event in p.move.events do
				if event.at > p.last and event.at <= u then
					local glow = if event.kind == "glow" then tostring(p.glow) else ""
					table.insert(out, { kind = event.kind .. glow })
				end
			end
		end
		p.last = u
		local part = p.move.pose(u, ctx)
		Pose.add(pose, if p.side < 0 then Tipos.mirror(part) else part, k)
		takes = math.max(takes, p.move.takes * C.hold(u, 0, 0.12, 0.85, 1) * k)
		if u < 1 and k > 0 then
			table.insert(keep, p)
		end
	end
	return keep, pose, takes
end

return table.freeze(Mezcla)
