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
		ankle         alto del tobillo (la pezuña) y toe / heel, cuánto sale la
		              pezuña adelante y atrás del tobillo: al inclinarse el pie baja
		              el talón o la punta (minotauro_v2_e<n>_geometria.py, Pie)
		shinBack / shinFront  grosor de la pierna atrás y adelante del tobillo: la
		              pierna inclinada baja ese borde (Pierna)
		seatSkirt     grados que tiene que levantarse el faldón de adelante sentado
		              (piernas estiradas adelante: las pezuñas lo empujan más que en
		              skirt); medido en Blender con la postura de Posturas/Sentarse
]]

export type Body = {
	thigh: number,
	shin: number,
	hip: number,
	footSide: number,
	ankle: number,
	toe: number,
	heel: number,
	shinBack: number,
	shinFront: number,
	seatSkirt: number,
	skirt: { { number } },
}

local BODIES: { [number]: Body } = {
	{ -- E1 (becerro)
		thigh = 0.129,
		shin = 0.129,
		hip = 0.3226,
		footSide = 0.0968,
		ankle = 0.0645,
		toe = 0.129,
		heel = 0.0645,
		shinBack = 0.0645,
		shinFront = 0.0645,
		seatSkirt = 71,
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
		ankle = 0.0714,
		toe = 0.1429,
		heel = 0.0714,
		shinBack = 0.0714,
		shinFront = 0.0714,
		seatSkirt = 71,
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
		ankle = 0.0645,
		toe = 0.1935,
		heel = 0.0645,
		shinBack = 0.0645,
		shinFront = 0.0645,
		seatSkirt = 72,
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
		ankle = 0.0645,
		toe = 0.1935,
		heel = 0.0645,
		shinBack = 0.0968,
		shinFront = 0.129,
		seatSkirt = 68,
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
