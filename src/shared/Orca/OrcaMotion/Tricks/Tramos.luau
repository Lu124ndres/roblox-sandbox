--!strict
--[[
	OrcaMotion/Tricks/Tramos

	Arma un truco con tramos de tiempo en segundos (tomar impulso, volar, caer,
	hundirse...). Cada tramo da la pose para su tiempo local t; el truco busca
	el tramo de u * seconds. Así la física va en segundos de verdad y los
	momentos (eventos y marcas) se ponen en segundos y salen en avance u.
]]

local Tricks = require(script.Parent)

export type Tramo = {
	seconds: number,
	pose: (t: number, from: number, seed: number) -> Tricks.Pose,
}
-- Un momento del truco en segundos desde que empieza.
export type Moment = { time: number, kind: string, where: string?, size: number? }

local Tramos = {}

function Tramos.total(list: { Tramo }): number
	local total = 0
	for _, tramo in list do
		total += tramo.seconds
	end
	return total
end

-- Segundos desde el comienzo hasta el tramo `index` (1 = 0).
function Tramos.start(list: { Tramo }, index: number): number
	local time = 0
	for k = 1, index - 1 do
		time += list[k].seconds
	end
	return time
end

function Tramos.build(
	name: string,
	list: { Tramo },
	moments: { Moment },
	marks: { [string]: number }, -- en segundos
	extra: { vary: number?, show: number?, deep: number? }?
): Tricks.Trick
	local total = math.max(Tramos.total(list), 1e-3)
	local events: { Tricks.Event } = {}
	for _, moment in moments do
		table.insert(events, {
			at = math.clamp(moment.time / total, 0, 1),
			kind = moment.kind,
			where = moment.where,
			size = moment.size,
		})
	end
	table.sort(events, function(a: Tricks.Event, b: Tricks.Event)
		return a.at < b.at
	end)
	local atMarks: { [string]: number } = {}
	for key, time in marks do
		atMarks[key] = math.clamp(time / total, 0, 1)
	end
	local last = list[#list]
	return {
		name = name,
		seconds = total,
		events = events,
		marks = atMarks,
		vary = if extra then extra.vary else nil,
		show = if extra and extra.show then extra.show / total else nil,
		deep = if extra then extra.deep else nil,
		pose = function(u: number, from: number, seed: number?): Tricks.Pose
			local t = math.clamp(u, 0, 1) * total
			for _, tramo in list do
				if t <= tramo.seconds then
					return tramo.pose(t, from, seed or 0.5)
				end
				t -= tramo.seconds
			end
			return last.pose(last.seconds, from, seed or 0.5)
		end,
	}
end

return table.freeze(Tramos)
