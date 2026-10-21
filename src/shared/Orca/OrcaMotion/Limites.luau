--!strict
--[[
	OrcaMotion/Limites

	Hasta dónde puede girar cada hueso de la orca v2 (las 4 etapas) sin que sus
	bloques se atraviesen ni se abran juntas. Rig limita contra esta tabla todo
	ángulo que escribe, venga del nado, de un truco o de comer.

	Convención (contrato del rig, sección 2), en radianes:
		pitch  + = la punta del hueso sube (en Cola y AletaCola la punta es la
		       de atrás; en Cabeza y Pecho, la nariz). Mandibula: abrir = -.
		yaw    + = la punta va a la izquierda de la orca.
		roll   alrededor del eje largo. Pectorales: + = punta abajo, pegada al
		       cuerpo (el mismo signo en las dos). Dorsal: + = punta a la izquierda.
	Rig pasa estos ángulos a la cuenta de los huesos (en los que apuntan hacia
	atrás, pitch y yaw cambian de signo).

	Medidos en Blender con la cuenta del juego (tools/blender/orca_v2_poses.py,
	etapa 3, renders/orca_v2_e3/poses/poses.json), con ~10 % de margen. Los que
	no llegaron a fallar en la prueba (AletaCola, Aleta2, cerrar la boca) van más
	bajos que lo probado, a lo que se ve natural. Cada rango contiene el 0 (la
	pose de reposo).
]]

export type Rango = { min: number, max: number } -- radianes
export type Hueso = { pitch: Rango?, yaw: Rango?, roll: Rango? }
export type Limites = {
	porHueso: { [string]: Hueso },
	cadenaPitch: number, -- |suma| máxima de pitch de Cola1..Cola5 (arquear el lomo)
	cadenaYaw: number, -- |suma| máxima de yaw de Cola1..Cola5 (curva cerrada)
}

local function r(min: number, max: number): Rango
	return table.freeze({ min = min, max = max })
end

local limites: Limites = {
	porHueso = {
		Pecho = { pitch = r(-0.12, 0.12), yaw = r(-0.1, 0.1) }, -- no medido: no gira contra nadie
		Cabeza = { pitch = r(-0.12, 0.35), yaw = r(-0.21, 0.21) }, -- abajo choca la quijada con la garganta
		Mandibula = { pitch = r(-1.0, 0.2) }, -- 0.2 la cierra con los dientes juntos
		Cola1 = { pitch = r(-0.16, 0.13), yaw = r(-0.43, 0.43) },
		Cola2 = { pitch = r(-0.2, 0.19), yaw = r(-0.46, 0.46) },
		Cola3 = { pitch = r(-0.27, 0.24), yaw = r(-0.51, 0.51) },
		Cola4 = { pitch = r(-0.33, 0.33), yaw = r(-0.58, 0.58) },
		Cola5 = { pitch = r(-0.42, 0.42), yaw = r(-0.45, 0.45) }, -- de lado, los lóbulos tocan la Cola4
		AletaColaIzq = { pitch = r(-0.9, 0.9), roll = r(-0.1, 0.1) },
		AletaColaDer = { pitch = r(-0.9, 0.9), roll = r(-0.1, 0.1) },
		AletaIzq = { roll = r(-0.95, 0.64) },
		AletaDer = { roll = r(-0.95, 0.64) },
		AletaIzq2 = { roll = r(-1.2, 1.2) },
		AletaDer2 = { roll = r(-1.2, 1.2) },
		Dorsal = { roll = r(-0.7, 0.7) },
	},
	cadenaPitch = 1.3, -- 1.45 limpio con el reparto de Rig/Columna (SHARE)
	cadenaYaw = 1.2, -- 2.34 limpio; más allá ya no se ve natural
}

return limites
