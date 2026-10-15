--!strict
--[[
	OrcaMotion/Tricks/Surface

	Trucos en la superficie:
		tailSlap  coletazo: mete la cabeza, levanta la cola fuera del agua y la
		          azota `count` veces (como las orcas de verdad).
		finSlap   se acuesta de costado y golpea el agua con la aleta pectoral.
		roll      vuelta completa sobre su eje mientras nada, aletas abiertas.
		spin      da vueltas cerradas persiguiéndose la cola (juguetona).
]]

local Tricks = require(script.Parent)

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

local Surface = {}

-- Fuerza de cada azote dentro de su tramo f (0..1): sube lento, cae de golpe.
local function lash(f: number): number
	if f < 0.62 then
		return smooth(f / 0.62)
	end
	return 1 - 1.3 * smooth((f - 0.62) / 0.16) + 0.3 * smooth((f - 0.78) / 0.22)
end

function Surface.tailSlap(count: number, seconds: number): Tricks.Trick
	local events: { Tricks.Event } = {}
	for k = 0, count - 1 do
		local at = 0.2 + 0.65 * (k + 0.74) / count
		table.insert(events, { at = at, kind = "slap", where = "tail" })
	end
	return {
		name = "coletazo",
		seconds = seconds,
		events = events,
		pose = function(u: number, _from: number): Tricks.Pose
			local hold = smooth(span(u, 0, 0.2)) * (1 - smooth(span(u, 0.85, 1)))
			local f = (span(u, 0.2, 0.85) * count) % 1
			local tail = if u > 0.2 and u < 0.85 then lash(f) else 0.4 * hold
			return {
				depth = -0.3,
				pitch = -0.7 * hold,
				tail = (0.35 + 0.75 * tail) * hold,
				effort = 0.3,
				speed = 0.25,
				fins = -0.3,
			}
		end,
	}
end

function Surface.finSlap(count: number, seconds: number): Tricks.Trick
	local events: { Tricks.Event } = {}
	for k = 0, count - 1 do
		table.insert(events, { at = 0.2 + 0.65 * (k + 0.75) / count, kind = "slap", where = "fin" })
	end
	return {
		name = "aletazo",
		seconds = seconds,
		events = events,
		pose = function(u: number, _from: number): Tricks.Pose
			local side = smooth(span(u, 0, 0.18)) * (1 - smooth(span(u, 0.85, 1)))
			local f = (span(u, 0.2, 0.85) * count) % 1
			local slap = if u > 0.2 and u < 0.85 then lash(f) else 0
			return {
				depth = -0.12,
				roll = 1.35 * side,
				fins = -0.9 * slap + 0.5 * (1 - slap) * side,
				effort = 0.5,
				speed = 0.5,
			}
		end,
	}
end

function Surface.roll(turns: number, seconds: number): Tricks.Trick
	return {
		name = "giro",
		seconds = seconds,
		events = { { at = 0.5, kind = "splash" } },
		pose = function(u: number, _from: number): Tricks.Pose
			return {
				depth = -0.12,
				roll = math.pi * 2 * turns * smooth(span(u, 0.1, 0.9)),
				fins = -0.45 * bell(u),
				effort = 1.3,
				speed = 1.35,
			}
		end,
	}
end

function Surface.spin(turns: number, seconds: number): Tricks.Trick
	return {
		name = "persigueCola",
		seconds = seconds,
		events = { { at = 0.3, kind = "splash" }, { at = 0.7, kind = "splash" } },
		pose = function(u: number, _from: number): Tricks.Pose
			local s = smooth(span(u, 0.05, 0.95))
			return {
				depth = -0.1,
				yaw = math.pi * 2 * turns * s,
				roll = 0.55 * bell(u),
				effort = 1.6,
				speed = 0.5,
				fins = -0.3,
			}
		end,
	}
end

return table.freeze(Surface)
