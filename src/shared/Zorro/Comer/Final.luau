--!strict
--[[
	Zorro/Comer/Final

	Cómo come la forma final (etapa 4): 165 studs de alto y un abanico de nueve
	colas que llena el lago, así que no salta, no gira sobre sí ni corre (las
	colas pasarían por las paredes del cráter). Atrapa con calma y peso:
		calma     el bocado: baja apenas la cabeza al pez y cierra la boca firme
		          (sin chasquido), mastica dos veces despacio, entrecierra los ojos
		          y traga con el pecho que se hincha
		majestad  pez raro: se agacha hondo y despacio con el pez en la boca, lo
		          traga, se yergue y abre el abanico en cascada, aúlla al cielo y
		          asienta una pata con un golpe de agua
		ola       racha de 15: se echa atrás y levanta las dos delanteras, las baja
		          de golpe (una ola), otra vez con más fuerza, y abre el abanico
		          contento
		gran      racha de 30 (y cada 30 más): la ola y después la majestad
	La de 5 es lucirse (Comer/Festejos), como el adulto.
	Eventos: gulp, crouch, fan, joyHowl, glitter, orbs (legendario o más), land,
	yip y happy.
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

local span, smooth, bell, hold = Curvas.span, Curvas.smooth, Curvas.bell, Curvas.hold

local function calma(u: number, ctx: Clip.Ctx): Pose.Pose
	local meet = bell(span(u, 0, 0.3))
	local chew = math.max(0, Curvas.wave(span(u, 0.24, 0.6), 2))
	local toss = bell(span(u, 0.56, 0.9))
	local savor = hold(u, 0.4, 0.55, 0.85, 1)
	local p: Pose.Pose = {
		take = 0.55 * hold(u, 0, 0.12, 0.8, 1),
		jaw = -0.8 * hold(u, 0, 0.1, 0.5, 0.6) + 0.14 * chew + 0.2 * bell(span(u, 0.6, 0.78)),
		lookPitch = -0.12 * meet + 0.22 * toss,
		lookYaw = 0.08 * ctx.side * bell(span(u, 0, 0.7)),
		tilt = 0.06 * ctx.side * chew,
		lean = -0.04 * meet,
		breathe = 0.03 * toss,
		earL = 0.15 * savor,
		earR = 0.2 * savor,
		eyesClosed = 0.45 * savor,
		emoFeliz = 0.8 * savor,
		tailWag = 0.35 * bell(span(u, 0.3, 1)),
		tailFan = 0.15 * savor,
		tailGusto = 0.6 * savor,
	}
	return Clip.mix(p, Clip.mira(u, 0, 0.45))
end

local function majestad(u: number, ctx: Clip.Ctx): Pose.Pose
	local load = hold(u, 0, 0.16, 0.24, 0.36)
	local rise = hold(u, 0.3, 0.42, 0.84, 0.97)
	local howl = hold(u, 0.48, 0.56, 0.8, 0.88)
	local tremble = math.sin(u * 90) * 0.025 * howl
	local paw = bell(span(u, 0.84, 0.92)) -- levanta una delantera y la asienta
	local p: Pose.Pose = {
		take = hold(u, 0, 0.08, 0.94, 1),
		jaw = -0.8 * hold(u, 0, 0.06, 0.26, 0.32) + 0.25 * bell(span(u, 0.3, 0.38)) + 0.75 * howl,
		crouch = 0.7 * load - 0.15 * rise,
		lean = -0.08 * load + 0.16 * rise,
		lookPitch = -0.3 * load + 0.2 * bell(span(u, 0.28, 0.4)) + 0.75 * howl + tremble,
		lookYaw = -0.15 * ctx.side * howl,
		earL = -0.3 * load + 0.3 * rise - 0.6 * howl,
		earR = -0.3 * load + 0.25 * rise - 0.55 * howl,
		[if ctx.side > 0 then "stepFL" else "stepFR"] = 0.45 * paw,
		eyesClosed = 0.3 * load + 0.4 * howl,
		emoFeliz = hold(u, 0.32, 0.42, 0.9, 1),
		tailLift = -0.2 * load + 0.6 * rise,
		tailFan = -0.15 * load + 1.3 * rise,
		tailAlert = 0.3 * rise,
		tailCalm = -0.4 * howl,
		tailGusto = rise,
		lookHold = hold(u, 0, 0.06, 0.92, 1),
	}
	return p
end

local function ola(u: number, ctx: Clip.Ctx): Pose.Pose
	local s = ctx.side
	-- Dos golpes: las delanteras suben (una antes que la otra) y bajan de golpe.
	local function up(a: number, b: number): number
		return smooth(span(u, a, b)) * (1 - span(u, b, b + 0.05) ^ 2)
	end
	local up1, up2 = up(0.04, 0.18), up(0.32, 0.48)
	local slam = bell(span(u, 0.22, 0.34)) + 1.2 * bell(span(u, 0.53, 0.66))
	local glad = hold(u, 0.6, 0.7, 0.9, 1)
	local rear = 0.7 * up1 + up2
	return {
		take = hold(u, 0, 0.06, 0.92, 1),
		lean = 0.14 * rear - 0.1 * slam,
		crouch = 0.25 * rear + 0.4 * slam,
		stepFL = 0.75 * up(if s > 0 then 0.04 else 0.07, 0.18) + 0.85 * up2,
		stepFR = 0.75 * up(if s > 0 then 0.07 else 0.04, 0.18) + 0.85 * up(0.34, 0.48),
		lookPitch = 0.2 * rear - 0.15 * slam + 0.15 * glad,
		jaw = 0.25 * rear + 0.4 * bell(span(u, 0.68, 0.8)),
		earL = 0.35 * rear - 0.2 * slam + 0.3 * glad,
		earR = 0.3 * rear - 0.25 * slam + 0.35 * glad,
		tilt = 0.12 * s * glad,
		tailLift = 0.35 * rear + 0.4 * glad,
		tailFan = 0.3 * rear + 1.1 * glad,
		tailWag = 0.8 * glad,
		tailGusto = glad + 0.4 * slam,
		emoFeliz = hold(u, 0, 0.08, 0.9, 1),
		emoSorpresa = 0.4 * bell(span(u, 0.22, 0.3)),
		lookHold = hold(u, 0, 0.06, 0.9, 1),
	}
end

local CLIPS: { [string]: Clip.Clip } = {
	calma = {
		name = "calma",
		seconds = 1,
		events = { { at = 0.66, kind = "gulp" } },
		pose = calma,
	},
	majestad = {
		name = "majestad",
		seconds = 2.6,
		events = {
			{ at = 0.05, kind = "crouch" },
			{ at = 0.3, kind = "gulp" },
			{ at = 0.38, kind = "fan" },
			{ at = 0.44, kind = "glitter" },
			{ at = 0.5, kind = "joyHowl" },
			{ at = 0.56, kind = "orbs", rare = 5 },
			{ at = 0.9, kind = "land" },
		},
		pose = majestad,
	},
	ola = {
		name = "ola",
		seconds = 3.2,
		events = {
			{ at = 0.04, kind = "crouch" },
			{ at = 0.23, kind = "land" },
			{ at = 0.54, kind = "land" },
			{ at = 0.62, kind = "fan" },
			{ at = 0.7, kind = "yip" },
			{ at = 0.86, kind = "happy" },
		},
		pose = ola,
	},
}
CLIPS.gran = Clip.seq("gran", CLIPS.ola, CLIPS.majestad)

return table.freeze(CLIPS)
