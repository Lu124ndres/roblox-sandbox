--!strict
--[[
	BodyPoses

	Poses del cuerpo entero para BodyPose, en grados (ejes en BodyRig). Lo que
	no aparece vale 0. Están exageradas a propósito: la referencia es cómo lo
	hace la gente de verdad, pero llevado al doble para que se lea desde lejos.

		crouch   agacharse (cadera adelante, rodillas atrás, el cuerpo baja)
		spread   abrir las piernas a los lados
		stagger  un pie adelante: positivo = el izquierdo
		waistX   tronco: positivo = hacia atrás; waistY = girar a la izquierda
		neckX    cabeza: positivo = mirar arriba; neckY = girar a la izquierda
		lShoulderX / rShoulderX  brazo: 90 = al frente, 180 = arriba
		lShoulderZ / rShoulderZ  brazo hacia la derecha del personaje
		lElbow / rElbow          doblar el codo hacia adelante
		breath   respiración (amplitud, 1 = normal)
		reel     la mano izquierda gira el carrete (amplitud)

	El brazo derecho de la caña no está aquí: lo mueve ArmPose. Solo la
	alimentación usa rShoulder y rElbow (no hay caña en la mano).

	Pesca. Lanzado de verdad: el cuerpo carga atrás girando el tronco, el brazo
	libre apunta al blanco, y el latigazo empieza en la cadera y termina en la
	mano (castWhip); al picar se agacha listo, al clavar el anzuelo tira con la
	espalda hacia atrás (hookSet).
	Entrenar: bombear y recoger, como con un pez grande: sube la caña con todo
	el cuerpo hacia atrás (pumpUp) y recoge bajándola (pumpDown).
	Alimentar: como un cuidador de orcas, un brazo lanza por encima del hombro
	mientras el otro ya carga el siguiente, con el pie contrario adelante.
]]

export type Pose = { [string]: number }

local BodyPoses: { [string]: Pose } = {
	rest = {},

	castWindup = {
		crouch = 10,
		spread = 8,
		stagger = 16,
		waistX = 14,
		waistY = -38,
		waistZ = 6,
		neckX = 6,
		neckY = 30,
		lShoulderX = 85,
		lShoulderZ = -20,
		lElbow = 15,
	},
	castWhip = {
		crouch = 16,
		spread = 8,
		stagger = 24,
		waistX = -26,
		waistY = 30,
		waistZ = -4,
		neckX = -12,
		neckY = -18,
		lShoulderX = 15,
		lShoulderZ = -25,
		lElbow = 70,
	},
	hold = {
		crouch = 6,
		spread = 8,
		stagger = 10,
		waistX = -6,
		waistY = 8,
		neckX = -8,
		neckY = -6,
		lShoulderX = 38,
		lShoulderZ = 10,
		lElbow = 65,
		breath = 1,
	},
	biteReady = {
		crouch = 18,
		spread = 12,
		stagger = 12,
		waistX = -18,
		waistY = 4,
		neckX = -18,
		lShoulderX = 60,
		lShoulderZ = 18,
		lElbow = 75,
	},
	hookSet = {
		crouch = 20,
		spread = 12,
		stagger = -12,
		waistX = 34,
		waistY = -10,
		neckX = 24,
		lShoulderX = 125,
		lShoulderZ = 15,
		lElbow = 35,
	},
	catchCheer = {
		crouch = 4,
		spread = 10,
		waistX = 12,
		waistZ = -6,
		neckX = 18,
		lShoulderX = 165,
		lShoulderZ = -28,
		lElbow = 10,
	},
	trophy = {
		spread = 14,
		waistX = 20,
		neckX = 30,
		lShoulderX = 175,
		lShoulderZ = -12,
		breath = 1.6,
	},
	slack = {
		crouch = 8,
		spread = 6,
		waistX = -28,
		waistZ = 5,
		neckX = -32,
		neckY = 10,
		lShoulderX = 4,
		lShoulderZ = 4,
		lElbow = 10,
	},

	pumpUp = {
		crouch = 16,
		spread = 12,
		stagger = -10,
		waistX = 30,
		neckX = 14,
		lShoulderX = 100,
		lShoulderZ = 14,
		lElbow = 30,
	},
	pumpDown = {
		crouch = 10,
		spread = 12,
		stagger = 6,
		waistX = -8,
		neckX = -6,
		lShoulderX = 45,
		lShoulderZ = 16,
		lElbow = 80,
		reel = 1,
	},
	heave = {
		crouch = 24,
		spread = 16,
		stagger = -16,
		waistX = 42,
		neckX = 28,
		lShoulderX = 140,
		lShoulderZ = 10,
		lElbow = 20,
	},

	throwRight = {
		crouch = 12,
		spread = 12,
		stagger = 14,
		waistX = -14,
		waistY = 30,
		neckY = -24,
		rShoulderX = 118,
		rShoulderZ = 6,
		rElbow = 4,
		lShoulderX = 172,
		lShoulderZ = -16,
		lElbow = 85,
	},
	throwLeft = {
		crouch = 12,
		spread = 12,
		stagger = -14,
		waistX = -14,
		waistY = -30,
		neckY = 24,
		lShoulderX = 118,
		lShoulderZ = -6,
		lElbow = 4,
		rShoulderX = 172,
		rShoulderZ = 16,
		rElbow = 85,
	},
}

return table.freeze(BodyPoses)
