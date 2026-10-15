--!strict
--[[
	OrcaMotion/Tricks/Jumps

	Trucos que sacan a la orca del agua o la mandan al fondo:
		breach   salto completo: toma impulso hundiéndose, sale disparada con la
		         nariz arriba, gira `twist` vueltas en el aire y cae de cabeza
		         (con media vuelta cae de costado y se endereza bajo el agua).
		hops     saltitos seguidos como delfín (`count` arcos de `height`).
		dive     zambullida honda: arquea el lomo, saca la cola del agua y baja
		         hasta `depth`; nada allá abajo y sube a respirar.
]]

local Tricks = require(script.Parent)

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

local Jumps = {}

function Jumps.breach(apex: number, twist: number, seconds: number): Tricks.Trick
	-- Cae de costado si la vuelta es incompleta y termina de girar bajo el agua.
	local spun, upright = math.pi * 2 * twist, math.pi * 2 * math.ceil(twist - 1e-6)
	return {
		name = "salto",
		seconds = seconds,
		events = { { at = 0.04, kind = "call" } },
		pose = function(u: number, from: number): Tricks.Pose
			if u < 0.24 then
				local a = u / 0.24
				local low = -0.5
				local depth = if a < 0.6
					then from + (low - from) * smooth(a / 0.6)
					else low + (-0.15 - low) * smooth((a - 0.6) / 0.4)
				local pitch = if a < 0.6
					then -0.35 * math.sin(math.pi * a / 0.6)
					else 0.95 * smooth((a - 0.6) / 0.4)
				return { depth = depth, pitch = pitch, speed = 1.7, effort = 1.8, fins = 0.35 }
			elseif u < 0.82 then
				local b = (u - 0.24) / 0.58
				return {
					depth = -0.15 + (apex + 0.15) * 4 * b * (1 - b),
					pitch = 0.95 - 2 * b,
					roll = spun * smooth(b),
					jaw = 0.55 * bell(b),
					fins = 0.5,
					effort = 0.25,
					speed = 1.3,
					air = true,
				}
			end
			local c = smooth((u - 0.82) / 0.18)
			return {
				depth = -0.15 + (from - 0.35 + 0.15) * c,
				pitch = -1.05 * (1 - c),
				roll = spun + (upright - spun) * c,
				effort = 1.3,
				fins = 0.2,
			}
		end,
	}
end

function Jumps.hops(height: number, count: number, seconds: number): Tricks.Trick
	local events: { Tricks.Event } = {}
	for k = 0, count - 1 do
		table.insert(events, { at = (k + 0.08) / count, kind = "splash" })
	end
	return {
		name = "saltitos",
		seconds = seconds,
		events = events,
		pose = function(u: number, _from: number): Tricks.Pose
			local f = (u * count) % 1
			local arc = math.sin(math.pi * f)
			return {
				depth = -0.28 + (height + 0.28) * arc ^ 1.4,
				pitch = 0.75 * math.cos(math.pi * f),
				air = arc > 0.45,
				effort = 1.5,
				speed = 1.6,
				fins = 0.3,
			}
		end,
	}
end

function Jumps.dive(depth: number, seconds: number): Tricks.Trick
	return {
		name = "zambullida",
		seconds = seconds,
		events = { { at = 0.2, kind = "slap", where = "tail" }, { at = 0.96, kind = "spout" } },
		pose = function(u: number, from: number): Tricks.Pose
			local arch = span(u, 0, 0.18) -- arquea y saca la cola
			local down = span(u, 0.15, 0.4)
			local up = span(u, 0.72, 1)
			local level = from + (-depth - from) * smooth(down)
			level += (from + 0.04 - level) * smooth(up)
			local pitch = -0.95 * smooth(arch) * (1 - smooth(span(u, 0.35, 0.5))) + 0.45 * bell(up)
			return {
				depth = level - 0.08 * bell(arch),
				pitch = pitch,
				tail = 0.9 * bell(span(u, 0.06, 0.32)),
				effort = 1.1,
				speed = 1.2,
				fins = 0.25,
			}
		end,
	}
end

return table.freeze(Jumps)
