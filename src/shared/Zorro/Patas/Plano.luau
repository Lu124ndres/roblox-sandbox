--!strict
--[[
	Zorro/Patas/Plano

	Las patas se cuentan en el plano del cuerpo: Vector2(adelante, arriba), en fracciones
	del alto, con el piso en arriba = 0 (el pivote del modelo está en la base). Un ángulo
	+ gira de adelante hacia arriba, como el cabeceo de Rig.turn: un hueso girado `a`
	lleva sus hijos girados `a` alrededor de su articulación.
		geometry(rig)       articulaciones de reposo (Cadera, Columna, Pecho y cada pata),
		                    medidas una vez por rig en rig.rest
		rotate(p, c, a)     el punto p girado `a` alrededor de c
		twoBone(...)        IK de dos huesos: ángulo de cada uno en el plano
		cycle(p, stride)    el paso: por pata, cuánto va adelante (alto) y cuánto se levanta;
		                    stride es la zancada de Zorro/Habitos (la misma de walkPhase)
	Los giros de lado (sway, spine) no entran: las patas quedan en su plano.
]]

local Ajustes = require(script.Parent.Ajustes)
local Rig = require(script.Parent.Parent.Rig)

export type Geometry = { [string]: Vector2 }
export type Leg = { forward: number, lift: number }

local Plano = {}

local cache: { [Rig.Rig]: Geometry } = setmetatable({}, { __mode = "k" }) :: any

local NAMES = {
	"Cadera",
	"Columna",
	"Pecho",
	"HombroIzq",
	"BrazoIzq",
	"AntebrazoIzq",
	"ManoIzq",
	"MusloIzq",
	"PiernaIzq",
	"TobilloIzq",
	"PieIzq",
	"HombroDer",
	"BrazoDer",
	"AntebrazoDer",
	"ManoDer",
	"MusloDer",
	"PiernaDer",
	"TobilloDer",
	"PieDer",
}

-- El alto del modelo cuando se enlazó: BaseHeight (lo pone GiantTemplates) por su escala,
-- o el alto que pide el juego si no lo tiene.
local function bindHeight(rig: Rig.Rig, fallback: number): number
	local base = rig.model:GetAttribute("BaseHeight")
	if type(base) == "number" and base > 0 then
		return base * rig.model:GetScale()
	end
	return math.max(fallback, 1e-3)
end

function Plano.geometry(rig: Rig.Rig, height: number): Geometry?
	local known = cache[rig]
	if known then
		return known
	end
	local h = bindHeight(rig, height)
	local geo: Geometry = {}
	for _, name in NAMES do
		local rest = rig.rest[name]
		if not rest then
			return nil
		end
		local p = rest.Position
		geo[name] = Vector2.new(p:Dot(rig.frame.forward), p:Dot(rig.frame.up)) / h
	end
	cache[rig] = geo
	return geo
end

function Plano.rotate(p: Vector2, center: Vector2, angle: number): Vector2
	local d = p - center
	local c, s = math.cos(angle), math.sin(angle)
	return center + Vector2.new(d.X * c - d.Y * s, d.X * s + d.Y * c)
end

function Plano.angle(v: Vector2): number
	return math.atan2(v.Y, v.X)
end

function Plano.wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- Ángulos (en el plano) del primer y del segundo hueso para llevar la punta de a a
-- target. side -1: la junta queda atrás de la línea cuando esta baja (codo, talón).
function Plano.twoBone(
	a: Vector2,
	target: Vector2,
	l1: number,
	l2: number,
	side: number
): (number, number)
	local d = target - a
	local length = math.max(d.Magnitude, 1e-9)
	local dist = math.clamp(length, math.abs(l1 - l2) + 1e-6, (l1 + l2) * 0.9999)
	local cosA = math.clamp((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist), -1, 1)
	local first = Plano.angle(d) + side * math.acos(cosA)
	local knee = a + Vector2.new(math.cos(first), math.sin(first)) * l1
	return first, Plano.angle(a + d / length * dist - knee)
end

-- Una pata en su ciclo (s 0..1, 0 = apoya): apoyada va de adelante hacia atrás a la
-- velocidad del cuerpo; en el aire vuelve adelante y sube más ya bajo el cuerpo.
local function step(s: number, stride: number): (number, number)
	local amp = Ajustes.DUTY * stride / 2
	if s < Ajustes.DUTY then
		return amp * (1 - 2 * s / Ajustes.DUTY), 0
	end
	local q = (s - Ajustes.DUTY) / (1 - Ajustes.DUTY)
	return -amp + 2 * amp * q * q * (3 - 2 * q), math.sin(math.pi * q ^ 1.35)
end

-- Por pata (FIzq, FDer, HIzq, HDer): adelante (fracción del alto) y alto 0..1, ya por walk.
function Plano.cycle(p: { [string]: number }, stride: number): { [string]: Leg }
	local walk = math.clamp(p.walk or 0, 0, 1)
	local phase = (p.walkPhase or 0) / (2 * math.pi)
	local legs: { [string]: Leg } = {}
	for name, offset in Ajustes.GAIT do
		local forward, lift = step((phase - offset) % 1, stride)
		legs[name] = { forward = forward * walk, lift = lift * walk }
	end
	return legs
end

return table.freeze(Plano)
