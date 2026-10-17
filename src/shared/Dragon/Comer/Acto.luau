--!strict
--[[
	Dragon/Comer/Acto

	Lo común de las reacciones al comer (Bocados, Golosinas, Festejos): un acto
	dura `seconds` por el pace de su etapa (la cría es rápida, la anciana tarda
	más), avisa sus eventos cuando su avance pasa por `at` y da su pose para el
	avance u (0..1) con el contexto (Ctx). Toda pose vuelve a 0 en u = 1. Las
	curvas que comparten:
		strike(u, a, b)  el mordisco: llega de golpe en [0, a] (el cuadro del
		                 impacto casi sin suavizar) y vuelve lento hasta b
		bump(x, c, w)    un bulto en x = c de ancho w (el trago por el cuello)
	offset(p, body, L, ground): cuánto se corre el cuerpo con las claves lunge
	(adelante) y rise (arriba) de la pose, en largos L; nada si está posado.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Etapas = require(script.Parent.Parent.Etapas)

export type Pose = { [string]: number }
export type Ctx = {
	L: number, -- largo del dragón (studs)
	stage: number, -- 1 cría … 4 anciano
	profile: Etapas.Profile, -- pace (lentitud) y bounce (cuánto rebota y juega)
	side: number, -- +1 / -1: hacia qué lado va (alterna; en el saludo, el del jugador)
	amp: number, -- 0..1: más chico con peces muy seguidos
}
export type Act = {
	name: string,
	seconds: number, -- con pace 1; Dragon/Comer lo multiplica por el pace de la etapa
	events: { { at: number, kind: string } },
	pose: (u: number, c: Ctx) -> Pose,
}

local Acto = {}

function Acto.strike(u: number, a: number, b: number): number
	if u <= 0 or u >= b then
		return 0
	elseif u < a then
		local t = 1 - u / a
		return 1 - t * t
	end
	return 1 - C.smooth((u - a) / (b - a))
end

function Acto.bump(x: number, c: number, w: number): number
	local d = (x - c) / w
	return math.exp(-d * d)
end

-- Cuánto se corre el cuerpo (lunge adelante, rise arriba) con la pose p; nada posado.
function Acto.offset(p: Pose, body: CFrame, L: number, ground: number): Vector3
	local look = body.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local ahead = if flat.Magnitude > 1e-3 then flat.Unit * (p.lunge or 0) else Vector3.zero
	return (ahead + Vector3.new(0, p.rise or 0, 0)) * L * (1 - math.clamp(ground, 0, 1))
end

return table.freeze(Acto)
