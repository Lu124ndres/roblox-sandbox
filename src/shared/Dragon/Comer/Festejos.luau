--!strict
--[[
	Dragon/Comer/Festejos

	Los festejos de las rachas (FedInfo.streak: peces seguidos). Dragon/Comer
	los lanza a los 5, 15 y 30 peces (y cada 20 más, el grande) con una espera
	entre uno y otro (REST): si llega la cuenta mientras festeja o hace una
	golosina, festeja con el pez siguiente.
		vuelta     5: contragiro y una vuelta de alegría sobre su eje con estela
		           (joy) y un chillido (cheer). El adulto y el anciano no dan
		           vueltas: levantan las alas muy alto, bajan de un aletazo de
		           gloria que los sube y gruñen de gusto
		rugido     15: junta aire con la cabeza abajo y las alas envueltas
		           (anticipación), las abre enormes y ruge al cielo sacudiendo la
		           cabeza (roar) con un anillo de fuego alrededor (fireRing)
		llamarada  30: toma aire, levanta la cabeza y echa fuego al cielo (fireSky,
		           el chorro de Dragon/Fx) con las alas abiertas, anillo de fuego y
		           lluvia de chispas doradas (feast); termina con un aletazo (joy)
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Acto = require(script.Parent.Acto)

type Pose = Acto.Pose
type Ctx = Acto.Ctx

local vuelta: Acto.Act = {
	name = "vuelta",
	seconds = 1.9,
	events = {
		{ at = 0.12, kind = "whoosh" },
		{ at = 0.12, kind = "joy" },
		{ at = 0.5, kind = "cheer" },
	},
	pose = function(u: number, c: Ctx): Pose
		if c.stage <= 2 then
			local counter = C.bell(C.span(u, 0, 0.14))
			local spin = C.span(u, 0.12, 0.7)
			local settle = C.span(u, 0.7, 1)
			local wobble = math.sin(settle * math.pi * 2.5) * (1 - settle) * C.span(u, 0.68, 0.74)
			local p: Pose = {
				fold = 0.15 * counter + 0.35 * C.bell(spin),
				rise = 0.08 * C.bell(C.span(u, 0.05, 0.85)),
				tailUp = 0.2 * counter + 0.3 * C.bell(spin),
				head = 0.15 * C.bell(spin),
			}
			if u < 1 then
				p.roll = -0.25 * counter + math.pi * 2 * C.smooth(spin) + 0.25 * wobble
			end
			return p
		end
		local raise = C.hold(u, 0.05, 0.35, 0.38, 0.5)
		local beat = C.bell(C.span(u, 0.38, 0.6))
		local glory = C.hold(u, 0.4, 0.55, 0.75, 0.98)
		return {
			spread = 0.9 * raise - 0.55 * beat,
			rise = 0.07 * C.bell(C.span(u, 0.4, 1)),
			neck = 0.25 * glory,
			head = 0.2 * glory,
			chest = 0.25 * glory - 0.1 * raise,
			tailUp = 0.35 * glory,
			tailCurl = 0.4 * c.side * glory,
		}
	end,
}

local rugido: Acto.Act = {
	name = "rugido",
	seconds = 2.8,
	events = {
		{ at = 0.3, kind = "roar" },
		{ at = 0.32, kind = "fireRing" },
		{ at = 0.34, kind = "joy" },
	},
	pose = function(u: number, _c: Ctx): Pose
		local gather = C.hold(u, 0.05, 0.24, 0.27, 0.32)
		local roar = C.overshoot(C.span(u, 0.28, 0.38)) * (1 - C.smooth(C.span(u, 0.75, 0.95)))
		local shake = math.sin(u * 50) * C.hold(u, 0.4, 0.45, 0.66, 0.74)
		return {
			wrap = 0.3 * gather,
			spread = 0.9 * roar,
			neckSnap = -0.2 * gather + 0.5 * roar,
			headSnap = -0.3 * gather + 0.4 * roar + 0.06 * shake,
			lookSnap = 0.1 * shake,
			chest = -0.12 * gather + 0.25 * roar,
			jaw = 0.1 * gather + 1.25 * roar,
			tailUp = -0.2 * gather + 0.45 * roar,
			rise = 0.04 * roar,
		}
	end,
}

local llamarada: Acto.Act = {
	name = "llamarada",
	seconds = 3.6,
	events = {
		{ at = 0.05, kind = "cheer" },
		{ at = 0.24, kind = "fireSky" },
		{ at = 0.25, kind = "fireRing" },
		{ at = 0.3, kind = "feast" },
		{ at = 0.84, kind = "joy" },
	},
	pose = function(u: number, _c: Ctx): Pose
		local gather = C.hold(u, 0.04, 0.17, 0.19, 0.24)
		local sky = C.overshoot(C.span(u, 0.2, 0.3)) * (1 - C.smooth(C.span(u, 0.82, 0.97)))
		local beat = C.bell(C.span(u, 0.82, 0.96))
		return {
			wrap = 0.25 * gather,
			spread = 0.7 * sky - 0.45 * beat,
			neckSnap = -0.18 * gather + 0.6 * sky,
			headSnap = -0.25 * gather + 0.75 * sky,
			pitch = -0.05 * gather + 0.2 * sky,
			chest = 0.2 * gather + 0.3 * sky,
			jaw = 1.25 * sky,
			tailUp = 0.5 * sky,
			rise = 0.05 * sky + 0.05 * beat,
		}
	end,
}

local LEVELS = { 5, 15, 30 }
local HUGE_EVERY = 20 -- después de 30, el grande cada tantos peces
local ACTS = { vuelta, rugido, llamarada }

local Festejos = {}

-- El nivel (1..3) que se gana con el pez número `streak` (nil si ese pez no festeja).
function Festejos.level(streak: number): number?
	local at = table.find(LEVELS, streak)
	if at then
		return at
	end
	local last = LEVELS[#LEVELS]
	return if streak > last and (streak - last) % HUGE_EVERY == 0 then #LEVELS else nil
end

function Festejos.act(level: number): Acto.Act
	return ACTS[math.clamp(level, 1, #ACTS)]
end

return table.freeze(Festejos)
