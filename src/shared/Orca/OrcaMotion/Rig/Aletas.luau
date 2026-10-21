--!strict
--[[
	OrcaMotion/Rig/Aletas

	Lo que cuelga de la columna en la orca v2: cabeza, mandíbula, pectorales y
	dorsal. Todo con resortes (capa secundaria) y limitado contra Limites.
		- Cabeza: casi quieta; compensa el cabeceo que les tocó a Raiz y Pecho,
		  mira hacia la curva y sube apenas al soplar.
		- Mandíbula: 0 = cerrada en el tope de cerrar, 1.2 = abierta en el tope
		  de abrir (lo que mida el rig es lo que abre).
		- Pectorales: timonean (la de adentro de la curva baja, la de afuera
		  sube), se levantan al picar, se abren un poco al planear y reman
		  apenas, cada una a su ritmo (nada en espejo); el codo llega más tarde.
		- Dorsal: va en la Cola1 y se mece por inercia hacia afuera de la curva y
		  contra el alabeo, con rebote.
]]

local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Limites = require(script.Parent.Parent.Limites)
local Huesos = require(script.Parent.Huesos)
local Tipos = require(script.Parent.Tipos)

type Rig = Tipos.Rig

local HEAD_STEADY = 0.8 -- cuánto deshace la cabeza el cabeceo del tronco
local HEAD_LOOK = 0.14 -- giro de la cabeza por rad/s de curva
local HEAD_BLOW = 0.05 -- rad: la cabeza sube al soplar
local JAW_FULL = 1.2 -- valor de `jaw` que abre la boca hasta el tope
local FIN_STEER = 0.14 -- rad por rad/s: timón de las pectorales
local FIN_PITCH_LAG = 0.12 -- se levantan al picar (siguen tarde al cuerpo)
local FIN_GLIDE = -0.06 -- al planear se abren un poco (estabilizan)
local FIN_FLAP = 0.11 -- remo de las pectorales por unidad de `flap`
-- Cada pectoral con su fase y su fuerza: Izq, Der.
local SIDES = { "Izq", "Der" }
local ROOTS = { "AletaIzq", "AletaDer" }
local ELBOWS = { "AletaIzq2", "AletaDer2" }
local FLAP_PHASE = { -0.8, -0.35 }
local FLAP_GAIN = { 1, 0.86 }
local DORSAL_TURN = 0.06 -- se va hacia afuera de la curva (rad por rad/s)
local DORSAL_ROLL = 0.07 -- y se queda atrás al alabear

local function follow(
	rig: Rig,
	name: string,
	target: number,
	dt: number,
	hz: number,
	damping: number
): number
	return Resorte.step(Resorte.get(rig.springs, name, target), target, dt, hz, damping)
end

local function apply(rig: Rig, pose: Tipos.Pose, dt: number, trunkPitch: number)
	local bend = math.clamp(pose.turn, -1.2, 1.2)
	local blow = pose.blow or 0

	-- Cabeza y boca.
	local look = follow(rig, "Mirada", bend, dt, 1.4, 0.9)
	local bob = 0.01 * pose.effort * math.sin(pose.phase + math.pi + 0.4)
	local headPitch = pose.head - HEAD_STEADY * trunkPitch + bob + HEAD_BLOW * blow
	Huesos.set(rig, "Cabeza", headPitch, look * HEAD_LOOK, 0)
	local jawRange = Limites.porHueso.Mandibula and Limites.porHueso.Mandibula.pitch
	local shut, open = if jawRange then jawRange.max else 0, if jawRange then jawRange.min else -0.5
	local jaw = math.clamp(follow(rig, "Mandibula", pose.jaw, dt, 6, 0.75) / JAW_FULL, 0, 1)
	Huesos.set(rig, "Mandibula", shut + (open - shut) * jaw, 0, 0)

	-- Pectorales (el roll lleva el signo del lado; Rig.bind lo midió).
	local pitchLag = math.clamp(pose.pitchSpeed or 0, -2, 2) * FIN_PITCH_LAG
	local glide = FIN_GLIDE * (pose.glide or 0)
	for i, s in SIDES do
		local axes = rig.axes[ROOTS[i]]
		if axes then
			local side = axes.side
			local flap = pose.flap
				* FIN_FLAP
				* FLAP_GAIN[i]
				* math.sin(pose.phase * 0.5 + FLAP_PHASE[i])
			local steer = -side * bend * FIN_STEER -- adentro de la curva (izquierda al girar +) baja
			local wave = (if side > 0 then pose.waveDer else pose.waveIzq) or 0
			local named = (if s == "Izq" then pose.finIzq else pose.finDer) or 0
			local want = pose.fins + flap + steer + pitchLag + glide + wave + named
			Huesos.set(rig, ROOTS[i], 0, 0, follow(rig, ROOTS[i], want, dt, 2.6, 0.55))
			Huesos.set(rig, ELBOWS[i], 0, 0, follow(rig, ELBOWS[i], want * 0.5, dt, 1.7, 0.45))
		end
	end

	-- Dorsal: inercia contra la curva y el alabeo.
	local sway = -bend * DORSAL_TURN - math.clamp(pose.rollSpeed or 0, -3, 3) * DORSAL_ROLL
	Huesos.set(rig, "Dorsal", 0, 0, follow(rig, "Dorsal", sway, dt, 1.3, 0.3))
end

return apply
