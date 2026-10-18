--!strict
--[[
	Zorro/Comer/Bocados

	Lo que hace el zorro con cada pez que le llega a la boca (u = 0 es el
	mordisco: la boca abierta esperando el pez es la anticipación). Todas cierran
	la boca de golpe (el cuadro del impacto sin suavizar), bajan un poco la
	cabeza (toma impulso) y la echan arriba para tragar con la boca entreabierta:
	la cabeza traza un arco hacia un lado (ctx.side, alterna). Lo principal pasa
	antes de 0.6: si llega otro pez (cada ~0.45 s) se mezcla sin cortar nada.
		atrapa   el más corto: mordisco, cabeza en arco, traga y menea la cola
		zarpazo  levanta una pata delantera y da un manotazo al agua (juega con el
		         pez), mira la pata y traga
		brinco   el primero después de una pausa: atrapa, se agacha, da un
		         brinquito y traga en el aire; cae amortiguando
		sacude   sacude la cabeza de lado a lado como con una presa y traga
		relamer  cuando dejan de darle: se relame dos veces, ladea la cabeza
		         contento y menea las colas
	Todas miran el bocado (Clip.mira) hasta tragarlo. La cría tiene además
	el brinco torpe (Comer/Cria) y la forma final el bocado en calma (Comer/Final).
	Eventos: gulp (traga), slap (el manotazo, con el lado de la pata), drops
	(gotas que salen de la boca), hop / hopLand (el brinco), lick (se relame).
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

local span, smooth, bell, hold = Curvas.span, Curvas.smooth, Curvas.bell, Curvas.hold
local easeOut = Curvas.easeOut

-- Boca cerrada desde el mordisco hasta `open` (ahí la abre para tragar).
local function closed(u: number, open: number): number
	return easeOut(span(u, 0, 0.08)) * (1 - smooth(span(u, open, open + 0.08)))
end

-- Tragar: baja la cabeza (impulso) y la echa arriba con la boca entreabierta.
local function gulp(u: number, a: number, b: number, side: number): Pose.Pose
	local dip = bell(span(u, a - 0.14, a + 0.02))
	local toss = bell(span(u, a, b))
	return {
		lookPitch = 0.42 * toss - 0.16 * dip,
		jaw = 0.3 * bell(span(u, a + 0.04, a + (b - a) * 0.55)),
		tilt = 0.16 * side * toss,
		earL = 0.25 * toss,
		earR = 0.25 * toss,
	}
end

local CLIPS: { [string]: Clip.Clip } = {
	atrapa = {
		name = "atrapa",
		seconds = 0.75,
		events = { { at = 0.38, kind = "gulp" } },
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local lunge = bell(span(u, 0, 0.24))
			local p: Pose.Pose = {
				take = 0.5 * hold(u, 0, 0.12, 0.7, 1),
				jaw = -0.95 * closed(u, 0.36),
				lookPitch = 0.2 * lunge,
				lookYaw = 0.24 * ctx.side * bell(span(u, 0, 0.62)),
				lean = -0.06 * lunge,
				earL = 0.3 * bell(span(u, 0, 0.9)),
				earR = 0.3 * bell(span(u, 0, 0.9)),
				tailWag = 0.6 * bell(span(u, 0.25, 1)),
				tailLift = 0.2 * bell(span(u, 0.25, 1)),
			}
			return Clip.mix(Clip.mix(p, gulp(u, 0.36, 0.64, ctx.side)), Clip.mira(u, 0, 0.5))
		end,
	},
	zarpazo = {
		name = "zarpazo",
		seconds = 0.9,
		events = { { at = 0.27, kind = "slap" }, { at = 0.58, kind = "gulp" } },
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local up = smooth(span(u, 0, 0.18))
			local down = span(u, 0.18, 0.27) ^ 2 -- acelera hasta el golpe
			local paw = up * (1 - down) + 0.15 * bell(span(u, 0.27, 0.4))
			local look = hold(u, 0.12, 0.26, 0.5, 0.66)
			local p: Pose.Pose = {
				take = 0.6 * hold(u, 0, 0.12, 0.75, 1),
				jaw = -0.95 * closed(u, 0.56),
				[if ctx.side > 0 then "stepFL" else "stepFR"] = 1.15 * paw,
				sway = 0.07 * ctx.side * up * (1 - smooth(span(u, 0.3, 0.5))),
				lookPitch = -0.22 * look,
				lookYaw = 0.2 * ctx.side * look,
				earL = 0.45 * hold(u, 0, 0.15, 0.6, 0.9),
				earR = 0.45 * hold(u, 0, 0.15, 0.6, 0.9),
				tailWag = 0.9 * bell(span(u, 0.1, 1)),
				tailLift = 0.3 * bell(span(u, 0.1, 1)),
			}
			-- Mira la pata que golpea y el pez en el agua hasta tragarlo.
			return Clip.mix(Clip.mix(p, gulp(u, 0.56, 0.84, ctx.side)), Clip.mira(u, 0, 0.7))
		end,
	},
	brinco = {
		name = "brinco",
		seconds = 1.15,
		events = {
			{ at = 0.3, kind = "hop" },
			{ at = 0.47, kind = "gulp" },
			{ at = 0.66, kind = "hopLand" },
		},
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local crouch = bell(span(u, 0.06, 0.32)) + 0.7 * bell(span(u, 0.64, 0.86))
			local t = span(u, 0.3, 0.66)
			local air = Curvas.arc(t)
			local p: Pose.Pose = {
				take = 0.9 * hold(u, 0, 0.15, 0.82, 1),
				jaw = -0.95 * closed(u, 0.45),
				dy = ctx.lift * air,
				crouch = 0.5 * crouch - 0.3 * air,
				lean = -0.1 * crouch + 0.1 * math.sin(math.pi * t - math.pi / 2) * air,
				stepFL = 0.65 * air,
				stepFR = 0.65 * air,
				stepHL = 0.45 * air,
				stepHR = 0.45 * air,
				lookPitch = -0.12 * bell(span(u, 0.06, 0.3)),
				earL = -0.35 * air + 0.45 * bell(span(u, 0.66, 1)),
				earR = -0.35 * air + 0.45 * bell(span(u, 0.66, 1)),
				tailWag = 0.8 * bell(span(u, 0.62, 1)),
			}
			return Clip.mix(Clip.mix(p, gulp(u, 0.45, 0.66, ctx.side)), Clip.mira(u, 0, 0.5))
		end,
	},
	sacude = {
		name = "sacude",
		seconds = 0.95,
		events = { { at = 0.12, kind = "drops" }, { at = 0.62, kind = "gulp" } },
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local t = span(u, 0.04, 0.52)
			local shake = math.sin(2 * math.pi * 2.5 * t) * (1 - t) * smooth(span(u, 0, 0.1))
			local f = hold(u, 0, 0.08, 0.5, 0.6)
			local p: Pose.Pose = {
				take = 0.5 * hold(u, 0, 0.1, 0.75, 1),
				jaw = -0.95 * closed(u, 0.6),
				lookYaw = 0.38 * ctx.side * shake,
				tilt = -0.25 * ctx.side * shake,
				lookPitch = 0.1 * f,
				earL = -0.25 * f,
				earR = -0.25 * f,
				shake = 0.12 * f,
				tailWag = 0.7 * bell(span(u, 0.3, 1)),
			}
			return Clip.mix(Clip.mix(p, gulp(u, 0.6, 0.86, ctx.side)), Clip.mira(u, 0, 0.62))
		end,
	},
	relamer = {
		name = "relamer",
		seconds = 1.4,
		events = { { at = 0.14, kind = "lick" } },
		pose = function(u: number, ctx: Clip.Ctx): Pose.Pose
			local f = hold(u, 0, 0.12, 0.8, 1)
			local licks = math.max(0, Curvas.wave(span(u, 0.1, 0.55), 2))
			return {
				take = 0.6 * f,
				jaw = 0.22 * licks * f,
				lookPitch = 0.14 * f - 0.06 * licks,
				tilt = 0.28 * ctx.side * hold(u, 0.3, 0.5, 0.85, 1),
				earL = 0.4 * f,
				earR = 0.4 * f,
				tailWag = 1 * f,
				tailLift = 0.3 * f,
				tailFan = 0.3 * f,
			}
		end,
	},
}

return table.freeze(CLIPS)
