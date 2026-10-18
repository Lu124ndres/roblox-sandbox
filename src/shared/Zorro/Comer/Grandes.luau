--!strict
--[[
	Zorro/Comer/Grandes

	Lo que hace con un pez raro (reemplaza al bocado; el mordisco es u = 0):
		pirueta  (raro) se agacha, salta y da una vuelta entera sobre sí en el
		         aire con las colas abiertas por el giro; traga arriba, cae
		         amortiguando y ladra contento
		mortal   (épico o más) se agacha hondo y largo (más del 20 %: se nota que
		         va a hacer algo grande), salta alto, da un salto mortal hacia atrás
		         con las patas recogidas y traga arriba; cae con un gran salpicón y
		         aúlla de alegría con las colas abiertas
	Las hacen la cría, el joven y el adulto; la forma final tiene su majestad
	(Comer/Final). La sorpresa del pez raro la pone Comer/Animo en la cara.
	En el aire las patas se recogen y las orejas van atrás; las colas se quedan
	atrás del movimiento (las arrastra Comer con la velocidad del cuerpo).
	Eventos: crouch, hop, launch, glitter (gotas y burbujas brillantes), gulp,
	hopLand, land, yip, joyHowl, orbs (solo legendario o más).
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

local span, smooth, bell, hold, arc =
	Curvas.span, Curvas.smooth, Curvas.bell, Curvas.hold, Curvas.arc
local TAU = math.pi * 2

-- Patas recogidas y orejas atrás mientras está en el aire.
local function airborne(air: number, tuck: number): Pose.Pose
	return {
		stepFL = (0.6 + 0.4 * tuck) * air,
		stepFR = (0.6 + 0.4 * tuck) * air,
		stepHL = (0.4 + 0.5 * tuck) * air,
		stepHR = (0.4 + 0.5 * tuck) * air,
		earL = -0.45 * air,
		earR = -0.45 * air,
	}
end

local function closedUntil(u: number, open: number): number
	return Curvas.easeOut(span(u, 0, 0.08)) * (1 - smooth(span(u, open, open + 0.08)))
end

local CLIPS: { [string]: Clip.Clip } = {
	pirueta = {
		name = "pirueta",
		seconds = 1.7,
		events = {
			{ at = 0.3, kind = "hop" },
			{ at = 0.46, kind = "glitter" },
			{ at = 0.5, kind = "gulp" },
			{ at = 0.72, kind = "hopLand" },
			{ at = 0.8, kind = "yip" },
		},
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local crouch = bell(span(u, 0.04, 0.32)) + 0.8 * bell(span(u, 0.7, 0.9))
			local t = span(u, 0.3, 0.72)
			local air = arc(t)
			local p: Pose.Pose = {
				take = hold(u, 0, 0.1, 0.88, 1),
				jaw = -0.95 * closedUntil(u, 0.47) + 0.3 * bell(span(u, 0.47, 0.58)) + 0.5 * bell(
					span(u, 0.78, 0.92)
				),
				dy = 1.4 * ctx.lift * air,
				crouch = 0.55 * crouch - 0.3 * air,
				spinY = ctx.side * TAU * smooth(span(u, 0.31, 0.74)),
				lean = -0.12 * bell(span(u, 0.04, 0.32)),
				lookPitch = -0.15 * bell(span(u, 0.04, 0.3))
					+ 0.4 * bell(span(u, 0.42, 0.62))
					+ 0.25 * bell(span(u, 0.76, 0.94)),
				tailFan = 1.1 * air + 0.4 * bell(span(u, 0.72, 1)),
				tailLift = 0.3 * air,
				tailWag = 1 * bell(span(u, 0.72, 1)),
				tailGusto = bell(span(u, 0.7, 1)),
				emoFeliz = hold(u, 0.45, 0.55, 0.9, 1),
			}
			Clip.mix(p, airborne(air, 0.3))
			p.earL = (p.earL or 0) + 0.5 * bell(span(u, 0.74, 1))
			p.earR = (p.earR or 0) + 0.5 * bell(span(u, 0.74, 1))
			return p
		end,
	},
	mortal = {
		name = "mortal",
		seconds = 3.2,
		events = {
			{ at = 0.1, kind = "crouch" },
			{ at = 0.24, kind = "launch" },
			{ at = 0.34, kind = "glitter" },
			{ at = 0.42, kind = "gulp" },
			{ at = 0.48, kind = "glitter" },
			{ at = 0.6, kind = "land" },
			{ at = 0.72, kind = "joyHowl" },
			{ at = 0.74, kind = "orbs", rare = 5 },
		},
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local load = bell(span(u, 0.03, 0.25))
			local t = span(u, 0.24, 0.6)
			local air = arc(t)
			local spin = span(u, 0.27, 0.57)
			local tuck = bell(spin)
			local squash = bell(span(u, 0.59, 0.72))
			local howl = hold(u, 0.7, 0.76, 0.93, 0.99)
			local tremble = math.sin(u * 140) * 0.03 * howl
			local p: Pose.Pose = {
				take = hold(u, 0, 0.08, 0.95, 1),
				jaw = -0.95 * closedUntil(u, 0.42) + 0.3 * bell(span(u, 0.42, 0.52)) + 0.85 * howl,
				dy = 3.2 * ctx.lift * air,
				crouch = 0.85 * load
					+ 0.55 * tuck
					+ 0.75 * squash
					+ 0.2 * howl
					- 0.3 * air * (1 - tuck),
				flip = TAU * smooth(spin),
				lean = 0.1 * load - 0.12 * squash + 0.16 * howl,
				lookPitch = -0.25 * load + 0.3 * tuck + 0.8 * howl + tremble,
				lookYaw = -0.25 * ctx.side * howl,
				tailFan = 1.2 * air + 1 * howl,
				tailLift = -0.2 * load + 0.5 * air + 0.6 * howl,
				tailCalm = -0.4 * howl,
				earL = -0.5 * howl,
				earR = -0.5 * howl,
				tailGusto = howl,
				emoFeliz = hold(u, 0.42, 0.5, 0.93, 1),
				eyesClosed = 0.5 * howl,
			}
			return Clip.mix(p, airborne(air, tuck))
		end,
	},
}

return table.freeze(CLIPS)
