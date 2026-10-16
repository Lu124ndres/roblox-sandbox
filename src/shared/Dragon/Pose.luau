--!strict
--[[
	Dragon/Pose

	Mueve los huesos del dragón cada cuadro (Bone.Transform) desde la pose de
	vuelo del modelo:
		alas    aletazo con bajada rápida y subida lenta; el codo y la mano
		        siguen con retraso (el ala hace látigo) y en la subida se
		        pliegan un poco hacia atrás; al planear quedan extendidas
		cola    onda lenta que viaja hacia la punta y se dobla en las curvas
		cuello  compensa el aletazo para que la cabeza vaya firme, y apunta
		        adonde mira (quien le da de comer)
		boca    abre y cierra (rugir, fuego, comer, morder)
		patas   recogidas al volar; colgando hacia adelante al quedarse quieto
]]

local Etapas = require(script.Parent.Etapas)
local Rig = require(script.Parent.Rig)

export type Input = {
	profile: Etapas.Profile,
	now: number,
	phase: number, -- fase del aleteo (rad)
	amp: number, -- 0..: amplitud actual del aleteo (rad)
	neutral: number, -- bajada del ala desde la pose del modelo (rad)
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

function Pose.apply(rig: Rig.Rig, input: Input)
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
		local base = input.neutral + amp * down - fold * 0.25
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

	-- Cola: onda que viaja hacia la punta y se dobla hacia dentro en las curvas.
	local now = input.now
	for i = 1, 6 do
		local wave = 0.09 * math.sin(now * 1.6 - i * 0.7) * (0.5 + i * 0.16)
		local yaw = wave + turn * 0.07 * i ^ 0.7
		local pitch = -input.climb * 0.05 * i / 6 + 0.035 * amp * math.sin(phase - i * 0.55)
		Rig.turn(rig, `Cola{i}`, pitch, yaw, 0)
	end

	-- Cuello y cabeza: compensan el aletazo y miran.
	local counter = -0.07 * amp * math.sin(phase + 0.6)
	local look = input.headYaw
	Rig.turn(rig, "Cuello1", input.headPitch * 0.35 + counter, look * 0.35 - turn * 0.05, 0)
	Rig.turn(rig, "Cuello2", input.headPitch * 0.3 + counter * 0.6, look * 0.3, 0)
	Rig.turn(rig, "Cabeza", input.headPitch * 0.35 - counter * 0.4, look * 0.35, 0)
	Rig.turn(rig, "Mandibula", -0.75 * input.jaw, 0, 0)

	-- Patas: recogidas al volar, colgando hacia adelante al quedarse quieto.
	local hover = input.hover
	local dangle = 0.06 * math.sin(phase - 1)
	for _, s in { "Izq", "Der" } do
		Rig.turn(rig, `Brazo{s}`, 0.9 * hover + dangle, 0, 0)
		Rig.turn(rig, `Antebrazo{s}`, -0.4 * hover + dangle * 0.5, 0, 0)
		Rig.turn(rig, `Muslo{s}`, 1.1 * hover + dangle * 0.7, 0, 0)
		Rig.turn(rig, `Pierna{s}`, -0.3 * hover, 0, 0)
	end
end

return table.freeze(Pose)
