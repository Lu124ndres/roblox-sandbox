--!strict
--[[
	Minotauro/Medidas

	Medidas del cuerpo de cada etapa del modelo de bloques v2, en fracciones del
	alto, para Minotauro/Cuerpo (las usa Etapas en el campo body). Salen de
	tools/blender/minotauro_v2_pisoton.py (renders/minotauro_v2_e<n>/medidas.json):
		thigh / shin  largo del muslo y de la pierna
		hip           alto de la cadera
		footSide      distancia de cada pie al centro
		skirt         muslo -> faldón de adelante, en grados: lo que hay que
		              levantarlo para que el muslo no lo atraviese (ya creciente)
]]

export type Body = {
	thigh: number,
	shin: number,
	hip: number,
	footSide: number,
	skirt: { { number } },
}

local BODIES: { [number]: Body } = {
	{ -- E1 (becerro)
		thigh = 0.129,
		shin = 0.129,
		hip = 0.3226,
		footSide = 0.0968,
		skirt = {
			{ 0, 0 },
			{ 28, 0 },
			{ 30, 1 },
			{ 32, 3 },
			{ 34, 6 },
			{ 36, 8 },
			{ 38, 11 },
			{ 42, 19 },
			{ 44, 25 },
			{ 46, 33 },
			{ 48, 47 },
			{ 50, 67 },
			{ 52, 71 },
			{ 82, 71 },
			{ 84, 72 },
			{ 88, 82 },
			{ 90, 82 },
		},
	},
	{ -- E2 (joven)
		thigh = 0.1429,
		shin = 0.1429,
		hip = 0.3571,
		footSide = 0.1071,
		skirt = {
			{ 0, 0 },
			{ 28, 0 },
			{ 30, 1 },
			{ 32, 3 },
			{ 34, 6 },
			{ 36, 8 },
			{ 38, 11 },
			{ 42, 19 },
			{ 44, 25 },
			{ 46, 33 },
			{ 48, 47 },
			{ 50, 67 },
			{ 52, 71 },
			{ 82, 71 },
			{ 84, 72 },
			{ 88, 82 },
			{ 90, 82 },
		},
	},
	{ -- E3 (adulto)
		thigh = 0.1613,
		shin = 0.1613,
		hip = 0.3871,
		footSide = 0.1129,
		skirt = {
			{ 0, 0 },
			{ 36, 0 },
			{ 38, 1 },
			{ 40, 3 },
			{ 46, 12 },
			{ 48, 16 },
			{ 50, 21 },
			{ 52, 38 },
			{ 54, 54 },
			{ 56, 62 },
			{ 84, 62 },
			{ 86, 74 },
			{ 88, 81 },
			{ 90, 81 },
		},
	},
	{ -- E4 (forma final)
		thigh = 0.1613,
		shin = 0.1613,
		hip = 0.3871,
		footSide = 0.1613,
		skirt = {
			{ 0, 0 },
			{ 54, 0 },
			{ 56, 2 },
			{ 58, 3 },
			{ 60, 5 },
			{ 62, 8 },
			{ 64, 15 },
			{ 66, 18 },
			{ 68, 19 },
			{ 70, 21 },
			{ 74, 23 },
			{ 76, 25 },
			{ 78, 26 },
			{ 82, 30 },
			{ 84, 36 },
			{ 86, 43 },
			{ 88, 55 },
			{ 90, 71 },
		},
	},
}

return table.freeze(BODIES)
