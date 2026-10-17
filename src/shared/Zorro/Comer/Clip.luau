--!strict
--[[
	Zorro/Comer/Clip

	Qué es una reacción al comer y las piezas que comparten:
		Clip   nombre, duración (en la etapa 1; las otras la estiran con pace),
		       eventos (at 0..1 → kind) y pose(u, ctx): lo que se suma a la pose
		       del zorro (Zorro/Pose) en el avance u. Todas empiezan y terminan en
		       cero: entran y salen sin saltos.
		Ctx    side (1 su izquierda, -1 su derecha: alterna para no repetir), lift
		       (cuánto salta, fracción del alto: la etapa grande salta menos),
		       radius (radio de la carrera, fracción del alto: cabe en el lago) y
		       rarity (del pez que la provocó; un festejo grande usa 6).
	Además de las claves de Zorro/Pose, una reacción puede pedir:
		take        cuánto deja de lado la pose de comer (0..1)
		spinY       giro de todo el cuerpo sobre sí (rad, + a su izquierda)
		flip        vuelta de todo el cuerpo hacia atrás (rad: salto mortal)
		runX, runZ  corrimiento del cuerpo (fracción del alto, en su marco: -Z al
		            frente)
		gait        fase de las patas al correr (rad): cada media vuelta pisa
		trail       0..1: deja estela de agua
	gallop() arma el galope con esa fase; spin y flip terminan en vueltas enteras.
]]

local Pose = require(script.Parent.Parent.Pose)

export type Ctx = { side: number, lift: number, radius: number, rarity: number }
-- rare: el evento solo sale si el pez es al menos así de raro (ctx.rarity).
export type Event = { at: number, kind: string, rare: number? }
export type Clip = {
	name: string,
	seconds: number,
	events: { Event },
	pose: (u: number, ctx: Ctx) -> Pose.Pose,
}

local Clip = {}

-- Galope: las delanteras juntas y después las traseras, el lomo se arquea y estira.
function Clip.gallop(phase: number, amount: number): Pose.Pose
	local front, hind = math.sin(phase), math.sin(phase + math.pi)
	return {
		stepFL = math.max(0, front) * amount,
		stepFR = math.max(0, math.sin(phase - 0.5)) * amount,
		stepHL = math.max(0, hind) * amount,
		stepHR = math.max(0, math.sin(phase + math.pi - 0.5)) * amount,
		lean = -0.07 * front * amount,
		dy = 0.025 * math.abs(front) * amount,
		gait = phase,
	}
end

-- Suma b dentro de a (ponderado) y devuelve a: para armar una pose con partes.
function Clip.mix(a: Pose.Pose, b: Pose.Pose, k: number?): Pose.Pose
	Pose.add(a, b, k)
	return a
end

return table.freeze(Clip)
