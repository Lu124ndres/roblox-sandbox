--!strict
--[[
	Dragon/Pose

	Mueve los huesos del dragón cada cuadro (Bone.Transform) desde la pose de
	vuelo del modelo:
		alas    aletazo con bajada rápida y subida lenta; el codo y la mano
		        siguen con retraso (el ala hace látigo) y en la subida se
		        pliegan un poco hacia atrás; al planear quedan extendidas
		cola    onda lenta que viaja hacia la punta; en las curvas y al subir o
		        bajar se dobla con retraso creciente hacia la punta (resortes)
		cuello  compensa el aletazo para que la cabeza vaya firme, y apunta
		        adonde mira con un poco de rebote
		boca    abre y cierra (rugir, fuego, comer, morder)
		patas   recogidas al volar; colgando hacia adelante al quedarse quieto,
		        con un balanceo que tarda en asentarse
	El ala parte del planeo: `rig.neutral` (medido del modelo) la baja hasta ahí.
]]

local Resorte = require(script.Parent.Parent.Resorte)
local Etapas = require(script.Parent.Etapas)
local Rig = require(script.Parent.Rig)

export type Input = {
	profile: Etapas.Profile,
	now: number,
	phase: number, -- fase del aleteo (rad)
	amp: number, -- 0..: amplitud actual del aleteo (rad)
	fold: number, -- 0..1: alas plegadas (picada)
	turn: number, -- rad/s del giro
	climb: number, -- -1..1: bajando o subiendo
	jaw: number, -- 0 cerrada .. 1 abierta
	headPitch: number,
	headYaw: number,
	hover: number, -- 0..1: quieto en el aire
}

local Pose = {}

-- Bajada rápida, subida lenta: la fase se deforma antes del seno.
local function stroke(phase: number): number
	return math.sin(phase + 0.38 * math.sin(phase))
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

function Pose.apply(rig: Rig.Rig, input: Input, dt: number)
	local phase, amp = input.phase, input.amp
	local down = stroke(phase) -- +1 abajo del todo, -1 arriba
	local upstroke = math.max(0, -math.cos(phase)) -- subiendo
	local turn = math.clamp(input.turn, -1.5, 1.5)
	for _, s in { "Izq", "Der" } do
		local side = rig.side[`Ala{s}1`]
		if side == 0 then
			side = if s == "Der" then 1 else -1
		end
		local fold = input.fold
		local base = rig.neutral + amp * down - fold * 0.25
		-- En la curva el ala de adentro baja un poco (timón).
		local steer = side * turn * 0.06
		Rig.turn(rig, `Ala{s}1`, 0, -side * fold * 0.5, side * (base + steer))
		local lag2 = amp * 0.42 * stroke(phase - 0.75) + 0.22 * amp * upstroke + fold * 0.9
		Rig.turn(rig, `Ala{s}2`, 0, -side * (0.3 * amp * upstroke + fold * 0.6), side * lag2)
		local lag3 = amp * 0.34 * stroke(phase - 1.4) + 0.15 * amp * upstroke + fold * 0.7
		Rig.turn(rig, `Ala{s}3`, 0, -side * fold * 0.5, side * lag3)
	end

	-- Cuerpo: el pecho se hincha con el aletazo.
	Rig.turn(rig, "Pecho", 0.05 * amp * math.sin(phase + math.pi), 0, 0)
	Rig.turn(rig, "Cadera", -0.04 * input.climb, 0, 0)

	-- Cola: onda que viaja hacia la punta; la curva y la subida llegan tarde a la punta.
	local now = input.now
	for i = 1, 6 do
		local wave = 0.09 * math.sin(now * 1.6 - i * 0.7) * (0.5 + i * 0.16)
		local bend = follow(rig, `Cola{i}`, turn * 0.07 * i ^ 0.7, dt, 2 - i * 0.22, 0.6)
		local sag = follow(rig, `ColaY{i}`, -input.climb * 0.05 * i / 6, dt, 1.6 - i * 0.15, 0.7)
		local pitch = sag + 0.035 * amp * math.sin(phase - i * 0.55)
		Rig.turn(rig, `Cola{i}`, pitch, wave + bend, 0)
	end

	-- Cuello y cabeza: compensan el aletazo y miran.
	local counter = -0.07 * amp * math.sin(phase + 0.6)
	local look = follow(rig, "Mirar", input.headYaw - turn * 0.12, dt, 1.5, 0.65)
	local nod = follow(rig, "Cabecear", input.headPitch, dt, 1.8, 0.7)
	Rig.turn(rig, "Cuello1", nod * 0.35 + counter, look * 0.35, 0)
	Rig.turn(rig, "Cuello2", nod * 0.3 + counter * 0.6, look * 0.3, 0)
	Rig.turn(rig, "Cabeza", nod * 0.35 - counter * 0.4, look * 0.35, 0)
	Rig.turn(rig, "Mandibula", -0.75 * input.jaw, 0, 0)

	-- Patas: recogidas al volar, colgando hacia adelante al quedarse quieto.
	local hover = follow(rig, "Patas", input.hover, dt, 1.4, 0.45)
	local dangle = 0.06 * math.sin(phase - 1)
	for _, s in { "Izq", "Der" } do
		Rig.turn(rig, `Brazo{s}`, 0.9 * hover + dangle, 0, 0)
		Rig.turn(rig, `Antebrazo{s}`, -0.4 * hover + dangle * 0.5, 0, 0)
		Rig.turn(rig, `Muslo{s}`, 1.1 * hover + dangle * 0.7, 0, 0)
		Rig.turn(rig, `Pierna{s}`, -0.3 * hover, 0, 0)
	end
end

return table.freeze(Pose)
