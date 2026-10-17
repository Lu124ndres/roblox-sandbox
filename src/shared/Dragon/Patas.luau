--!strict
--[[
	Dragon/Patas

	Las cuatro patas. Volando van recogidas (las de adelante bajo el pecho, las
	de atrás estiradas hacia atrás) y cuelgan hacia adelante al quedarse quieto
	en el aire (hover), con un balanceo que sigue al aleteo. Posado (legs = 1)
	cada hueso va a un ángulo de costado fijo respecto del suelo (STAND: 0 =
	vertical, + = hacia adelante), medido contra el de reposo del modelo
	(Rig.legRest) y corrigiendo lo que ya giró el cuerpo (tilt): así las patas
	quedan bajo el cuerpo aunque el dragón se incline o el modelo cambie.
		crouch   se agacha (+) o se estira en puntas (-): aplastarse al aterrizar
		         y antes de saltar, estirarse al despegar, echarse a dormir
		reach    estira las patas hacia abajo y adelante para tocar la roca
		liftL/R  levanta una mano (acicalarse)
		bend     dobla solo las de adelante (Dragon/Posado las nivela con esto
		         cuando inclinar el cuerpo no alcanza: la cría tiene brazos largos)
	La altura del cuerpo sobre la roca la pone Dragon/Posado con estas patas.
]]

local Rig = require(script.Parent.Rig)

type Part = { name: string, stand: number, crouch: number, reach: number }

local FRONT: { Part } = {
	{ name = "Brazo", stand = 0.1, crouch = 0.85, reach = 0.25 },
	{ name = "Antebrazo", stand = 0.15, crouch = -1.25, reach = 0.25 },
	{ name = "Mano", stand = 1.45, crouch = 0.2, reach = -0.6 },
}
local BACK: { Part } = {
	{ name = "Muslo", stand = 0.2, crouch = 0.75, reach = 0.15 },
	{ name = "Pierna", stand = -0.35, crouch = -1.0, reach = 0.35 },
	{ name = "Pie", stand = 1.35, crouch = 0.25, reach = -0.7 },
}
-- Volando: giro de cada hueso (relativo), quieto en el aire (hover) y balanceo.
local FLY: { [string]: { hover: number, dangle: number } } = {
	Brazo = { hover = 0.9, dangle = 1 },
	Antebrazo = { hover = -0.4, dangle = 0.5 },
	Mano = { hover = 0, dangle = 0 },
	Muslo = { hover = 1.1, dangle = 0.7 },
	Pierna = { hover = -0.3, dangle = 0 },
	Pie = { hover = 0, dangle = 0 },
}

local Patas = {}

-- hover: 0..1 quieto en el aire; dangle: balanceo (rad); front/back: cuánto giraron
-- (cabeceo, + = nariz arriba) el pecho y la cadera respecto del suelo.
function Patas.apply(
	rig: Rig.Rig,
	p: { [string]: number },
	hover: number,
	dangle: number,
	front: number,
	back: number
)
	local legs = math.clamp(p.legs or 0, 0, 1)
	local crouch, reach = p.crouch or 0, p.reach or 0
	for _, s in { "Izq", "Der" } do
		for _, isFront in { true, false } do
			local parts = if isFront then FRONT else BACK
			local tilt = if isFront then front else back
			local lift = if isFront then p["lift" .. (if s == "Izq" then "L" else "R")] or 0 else 0
			local bent = crouch + (if isFront then p.bend or 0 else 0)
			local before = tilt
			for i, part in parts do
				local name = part.name .. s
				local rest = rig.legRest[name]
				if not rest then
					continue
				end
				local target = part.stand + bent * part.crouch + reach * part.reach
				if lift ~= 0 then -- la mano sube hacia el pecho: brazo adelante, codo doblado
					target += lift * ({ 0.9, 1.9, 0.6 })[i]
				end
				local absolute = target - rest
				local stand = absolute - before
				before = absolute
				local fly = FLY[part.name]
				local flying = fly.hover * hover + fly.dangle * dangle
				Rig.turn(rig, name, flying + (stand - flying) * legs, 0, 0)
			end
		end
	end
end

return table.freeze(Patas)
