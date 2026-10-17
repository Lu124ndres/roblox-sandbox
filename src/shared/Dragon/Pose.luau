--!strict
--[[
	Dragon/Pose

	La pose del dragón como una tabla de números que se suman (la rutina, los
	trucos, comer y evolucionar ponen cada uno lo suyo) y su paso a los huesos
	(Bone.Transform) desde la pose de vuelo del modelo:
		alas        aleteo, picada, plegadas, abiertas... (Dragon/Alas)
		patas       recogidas, colgando o de pie (Dragon/Patas)
		pitch/roll  todo el cuerpo (los lee Dragon/init); dy: sube (fracción del largo)
		chest/hip   el pecho se levanta (+) / la cadera; el pecho se hincha al aletear
		cola        onda lenta que viaja hacia la punta (calm la calma: dormido casi
		            no se mueve); en las curvas y al subir o bajar se dobla con
		            retraso creciente hacia la punta (resortes); tailUp la levanta,
		            tailCurl la enrosca de costado (+ hacia su derecha) y tailDroop
		            la deja caer
		cuello      neck lo levanta (+), look gira cuello y cabeza (+ a su
		            izquierda), head cabecea, tilt ladea; compensa el aletazo para
		            que la cabeza vaya firme y sigue con un poco de rebote
		boca        jaw 0 cerrada .. 1 abierta
		directas    sin resorte, para lo rápido de comer (Dragon/Comer): neckSnap,
		            headSnap y lookSnap se suman a neck, head y look ya suavizados;
		            gulp2 y gulp1 doblan Cuello2 y Cuello1 (el trago que baja) sin
		            mover la cabeza
	El ala parte del planeo: `rig.neutral` (medido del modelo) la baja hasta ahí.
]]

local Resorte = require(script.Parent.Parent.Resorte)
local Alas = require(script.Parent.Alas)
local Etapas = require(script.Parent.Etapas)
local Patas = require(script.Parent.Patas)
local Rig = require(script.Parent.Rig)

export type Pose = { [string]: number }
export type Input = {
	profile: Etapas.Profile,
	now: number,
	phase: number, -- fase del aleteo (rad)
	amp: number, -- 0..: amplitud actual del aleteo (rad)
	fold: number, -- 0..1: alas plegadas (picada)
	turn: number, -- rad/s del giro
	climb: number, -- -1..1: bajando o subiendo
	hover: number, -- 0..1: quieto en el aire (patas colgando)
	pitch: number, -- cabeceo de todo el cuerpo (las patas lo compensan)
}

local Pose = {}

function Pose.add(into: Pose, from: Pose, k: number?)
	local weight = k or 1
	for key, value in from do
		into[key] = (into[key] or 0) + value * weight
	end
end

local function follow(
	rig: Rig.Rig,
	name: string,
	target: number,
	dt: number,
	hz: number,
	damping: number
): number
	return Resorte.step(Resorte.get(rig.springs, name, target), target, dt, hz, damping)
end

function Pose.apply(rig: Rig.Rig, input: Input, p: Pose, dt: number)
	local function v(key: string): number
		return p[key] or 0
	end
	local phase, amp = input.phase, input.amp
	local turn = math.clamp(input.turn, -1.5, 1.5)
	Alas.apply(rig, input, p)

	-- Cuerpo: el pecho se hincha con el aletazo; posado se levanta (chest).
	local hip = -0.04 * input.climb + v("hip")
	local chest = 0.05 * amp * math.sin(phase + math.pi)
		+ follow(rig, "Pecho", v("chest"), dt, 1.6, 0.7)
	Rig.turn(rig, "Cadera", hip, 0, 0)
	Rig.turn(rig, "Pecho", chest - v("hip"), 0, 0)

	-- Cola: onda que viaja hacia la punta; la curva y la subida llegan tarde a la punta.
	local now, calm = input.now, 1 - math.clamp(v("calm"), 0, 1)
	local curl = follow(rig, "Enroscar", v("tailCurl"), dt, 0.8, 0.8)
	local raise = follow(rig, "ColaArriba", v("tailUp"), dt, 1.4, 0.55)
	local droop = v("tailDroop")
	for i = 1, 6 do
		local wave = 0.09 * calm * math.sin(now * 1.6 - i * 0.7) * (0.5 + i * 0.16)
		local bend = follow(rig, `Cola{i}`, turn * 0.07 * i ^ 0.7, dt, 2 - i * 0.22, 0.6)
		local sag = follow(rig, `ColaY{i}`, -input.climb * 0.05 * i / 6, dt, 1.6 - i * 0.15, 0.7)
		-- La cola apunta hacia atrás: cabeceo + baja la punta.
		local pitch = sag + 0.035 * amp * math.sin(phase - i * 0.55) + droop * i / 12
		if i <= 2 then
			pitch -= raise * (if i == 1 then 0.6 else 0.4)
		end
		Rig.turn(rig, `Cola{i}`, pitch, wave + bend + curl * (0.14 + i * 0.02), 0)
	end

	-- Cuello y cabeza: compensan el aletazo y miran.
	local counter = -0.07 * amp * math.sin(phase + 0.6)
	local look = follow(rig, "Mirar", v("look") - turn * 0.12, dt, 1.5, 0.65) + v("lookSnap")
	local neck = follow(rig, "Cuello", v("neck"), dt, 1.4, 0.6) + v("neckSnap")
	local nod = follow(rig, "Cabecear", v("head"), dt, 1.8, 0.7) + v("headSnap")
	local tilt = follow(rig, "Ladear", v("tilt"), dt, 1.6, 0.6)
	local g1, g2 = v("gulp1"), v("gulp2")
	Rig.turn(rig, "Cuello1", neck * 0.55 + nod * 0.15 + counter + g1, look * 0.35, 0)
	Rig.turn(rig, "Cuello2", neck * 0.45 + nod * 0.2 + counter * 0.6 + g2 - g1, look * 0.3, 0)
	Rig.turn(rig, "Cabeza", nod * 0.65 - neck * 0.5 - counter * 0.4 - g2, look * 0.35, tilt)
	Rig.turn(rig, "Mandibula", -0.75 * math.clamp(v("jaw"), 0, 1.3), 0, 0)

	-- Patas: recogidas al volar, colgando al quedarse quieto, de pie posado.
	local hover = follow(rig, "Patas", input.hover, dt, 1.4, 0.45)
	local dangle = 0.06 * math.sin(phase - 1) * (1 - math.clamp(v("legs"), 0, 1))
	local front = input.pitch + hip + chest - v("hip")
	Patas.apply(rig, p, hover, dangle, front, input.pitch + hip)
end

return table.freeze(Pose)
