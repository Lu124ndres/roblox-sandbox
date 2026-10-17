--!strict
--[[
	Dragon/Comer/Capas

	Una capa de Dragon/Comer es una lista de actos sonando (Play), cada uno con
	su reloj (os.clock):
		start(list, act, now, ctx, pace)  empieza un acto (dura act.seconds x pace)
		fade(list, now)                   los que suenan se desvanecen en FADE s
		                                  (el bocado nuevo funde al anterior)
		run(list, now, out, weight, events)  suma sus poses a `out` con peso,
		                                  avisa sus eventos (los que se desvanecen
		                                  ya no avisan) y quita lo que terminó
		busy(lists, now)                  cuánto manda ahora algún acto (0..1)
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Acto = require(script.Parent.Acto)

local FADE = 0.12 -- s

export type Play = {
	act: Acto.Act,
	start: number,
	seconds: number,
	ctx: Acto.Ctx,
	u: number, -- avance del cuadro anterior (para los eventos)
	fadeAt: number?,
}

local Capas = {}

function Capas.start(list: { Play }, act: Acto.Act, now: number, ctx: Acto.Ctx, pace: number)
	table.insert(list, { act = act, start = now, seconds = act.seconds * pace, ctx = ctx, u = -1 })
end

function Capas.fade(list: { Play }, now: number)
	for _, play in list do
		play.fadeAt = play.fadeAt or now
	end
end

function Capas.run(
	list: { Play },
	now: number,
	out: { [string]: number },
	weight: number,
	events: { { kind: string } }
)
	for i = #list, 1, -1 do
		local play = list[i]
		local u = (now - play.start) / play.seconds
		local fade = if play.fadeAt then C.smooth((now - play.fadeAt) / FADE) else 0
		if u >= 1 or fade >= 1 then
			table.remove(list, i)
			continue
		end
		if not play.fadeAt then
			for _, event in play.act.events do
				if event.at > play.u and event.at <= u then
					table.insert(events, { kind = event.kind })
				end
			end
		end
		play.u = u
		local k = weight * (1 - fade)
		for key, value in play.act.pose(u, play.ctx) do
			out[key] = (out[key] or 0) + value * k
		end
	end
end

function Capas.busy(lists: { { Play } }, now: number): number
	local most = 0
	for _, list in lists do
		for _, play in list do
			most = math.max(most, C.hold((now - play.start) / play.seconds, 0.03, 0.12, 0.85, 1))
		end
	end
	return most
end

return table.freeze(Capas)
