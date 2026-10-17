--!strict
--[[
	Dragon/Alas

	Las alas, cuadro a cuadro, desde la pose de planeo del modelo:
		aleteo   bajada rápida y subida lenta; el codo y la mano siguen con
		         retraso (el ala hace látigo) y en la subida se pliegan un poco
		         hacia atrás; al planear quedan extendidas (amp casi 0)
		fold     plegadas hacia atrás para la picada
		tuck     plegadas sobre el lomo, posado: el hombro sube y va atrás, el
		         antebrazo se cierra hacia adelante y la mano hacia atrás, como
		         un murciélago
		spread   arriba y abiertas (+) o abajo de golpe (-): estirarse, frenar al
		         aterrizar, el aletazo del despegue, el estallido de la evolución
		cup      adelante, ahuecadas (frenar al aterrizar)
		wrap     envueltas alrededor del cuerpo, hacia adelante y abajo (evolución)
		wingL/R  sube una sola; tuckL/R la despliega (-) o pliega (+) sola
	En la curva el ala de adentro baja un poco (timón).
]]

local Rig = require(script.Parent.Rig)

export type Flight = {
	phase: number, -- fase del aleteo (rad)
	amp: number, -- amplitud actual del aleteo (rad)
	fold: number, -- 0..1 plegadas (picada)
	turn: number, -- rad/s del giro
}

local Alas = {}

-- Bajada rápida, subida lenta: la fase se deforma antes del seno.
function Alas.stroke(phase: number): number
	return math.sin(phase + 0.38 * math.sin(phase))
end

function Alas.apply(rig: Rig.Rig, f: Flight, p: { [string]: number })
	local function v(key: string): number
		return p[key] or 0
	end
	local phase, amp, fold = f.phase, f.amp, f.fold
	local down = Alas.stroke(phase) -- +1 abajo del todo, -1 arriba
	local upstroke = math.max(0, -math.cos(phase)) -- subiendo
	local turn = math.clamp(f.turn, -1.5, 1.5)
	local cup, wrap = v("cup"), v("wrap")
	for _, s in { "Izq", "Der" } do
		local side = rig.side[`Ala{s}1`]
		if side == 0 then
			side = if s == "Der" then 1 else -1
		end
		local up = v("spread") + v(if s == "Izq" then "wingL" else "wingR")
		local tuck = math.clamp(v("tuck") + v(if s == "Izq" then "tuckL" else "tuckR"), 0, 1)
		local base = (rig.neutral[s] + amp * down - fold * 0.25) * (1 - tuck)
		local steer = side * turn * 0.06
		-- Hombro: + alabeo baja el ala, - giro la lleva atrás.
		local sweep1 = fold * 0.5 + tuck * 1.15 - cup * 0.9 - wrap * 0.7
		local drop1 = base + steer - tuck * 0.45 - up + wrap * 0.35
		Rig.turn(rig, `Ala{s}1`, 0, -side * sweep1, side * drop1)
		-- Codo: con retraso; posado se cierra hacia adelante.
		local lag2 = (amp * 0.42 * Alas.stroke(phase - 0.75) + 0.22 * amp * upstroke + fold * 0.9)
			* (1 - tuck)
		local sweep2 = 0.3 * amp * upstroke + fold * 0.6 - tuck * 2.3 + wrap * 0.4
		Rig.turn(
			rig,
			`Ala{s}2`,
			0,
			-side * sweep2,
			side * (lag2 + tuck * 0.35 + wrap * 0.9 - up * 0.3)
		)
		-- Mano: más retraso; posado se cierra hacia atrás junto al cuerpo.
		local lag3 = (amp * 0.34 * Alas.stroke(phase - 1.4) + 0.15 * amp * upstroke + fold * 0.7)
			* (1 - tuck)
		local sweep3 = fold * 0.5 + tuck * 2.4 + wrap * 0.6
		Rig.turn(
			rig,
			`Ala{s}3`,
			0,
			-side * sweep3,
			side * (lag3 + tuck * 0.2 + wrap * 0.8 - up * 0.2)
		)
	end
end

return table.freeze(Alas)
