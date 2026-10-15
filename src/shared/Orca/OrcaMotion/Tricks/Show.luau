--!strict
--[[
	OrcaMotion/Tricks/Show

	Trucos para lucirse frente a los jugadores:
		spyhop  se para en el agua con la cabeza fuera y mira a un lado y al
		        otro (`looks` miradas), curiosa.
		roar    levanta la cabeza, abre la boca enorme y ruge; el cuerpo tiembla.
		emerge  baja al fondo y sube despacio hasta quedar muy por encima del
		        agua, como una isla, con el agua cayéndole del lomo; luego se
		        vuelve a hundir (la anciana).
]]

local Tricks = require(script.Parent)

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

local Show = {}

function Show.spyhop(height: number, looks: number, seconds: number): Tricks.Trick
	return {
		name = "asomarse",
		seconds = seconds,
		events = { { at = 0.3, kind = "call" }, { at = 0.18, kind = "splash" } },
		pose = function(u: number, from: number): Tricks.Pose
			local up = smooth(span(u, 0.05, 0.3)) * (1 - smooth(span(u, 0.75, 0.97)))
			local look = math.sin(math.pi * 2 * looks * span(u, 0.3, 0.75))
			return {
				depth = from + (height - from) * up,
				pitch = 1.3 * up,
				yaw = 0.55 * look * up,
				head = 0.15 * up,
				jaw = 0.15 * up,
				fins = -0.5 * up,
				effort = 0.5,
				speed = 0.08,
			}
		end,
	}
end

function Show.roar(seconds: number): Tricks.Trick
	return {
		name = "rugido",
		seconds = seconds,
		events = { { at = 0.32, kind = "roar" }, { at = 0.85, kind = "spout" } },
		pose = function(u: number, from: number): Tricks.Pose
			local up = smooth(span(u, 0, 0.25)) * (1 - smooth(span(u, 0.8, 1)))
			local open = smooth(span(u, 0.22, 0.32)) * (1 - smooth(span(u, 0.68, 0.8)))
			local shake = math.sin(u * seconds * 38) * 0.05 * open
			return {
				depth = from + (0.12 - from) * up,
				pitch = 0.55 * up + shake,
				roll = shake,
				head = 0.25 * open,
				jaw = 1.15 * open,
				fins = -0.6 * up,
				effort = 0.4,
				speed = 0.15,
			}
		end,
	}
end

function Show.emerge(height: number, seconds: number): Tricks.Trick
	return {
		name = "emerger",
		seconds = seconds,
		events = {
			{ at = 0.5, kind = "cascade" },
			{ at = 0.62, kind = "spout" },
			{ at = 0.72, kind = "cascade" },
		},
		pose = function(u: number, from: number): Tricks.Pose
			local down = smooth(span(u, 0, 0.25))
			local up = smooth(span(u, 0.3, 0.6))
			local back = smooth(span(u, 0.8, 1))
			local level = from + (-0.9 - from) * down
			level += (height + 0.9) * up
			level += (from - height) * back
			return {
				depth = level,
				pitch = 0.2 * bell(span(u, 0.25, 0.65)) - 0.15 * bell(span(u, 0.8, 1)),
				effort = 0.6,
				speed = 0.3,
				fins = -0.3 * up * (1 - back),
				jaw = 0.2 * up * (1 - back),
			}
		end,
	}
end

return table.freeze(Show)
