--!strict
--[[
	OrcaMotion/Rig/Mezcla

	La capa de acción de los huesos: Body pone la base (comer, soplar, rodar)
	en la pose y aquí se suma lo que piden el truco (con su peso w), la
	reacción grande al comer (bw) y los gestos al comer (add, ya con resortes).
	Es la misma suma para el modelo viejo y el v2; los campos nuevos (arch,
	flukes, bend, fin) en 0 no cambian nada.
]]

local Tricks = require(script.Parent.Parent.Tricks)
local Tipos = require(script.Parent.Tipos)

-- Lo que usa de los gestos al comer (Comer/Gestos.Add).
type Add = { fins: number, head: number, tail: number, waveIzq: number, waveDer: number }

local Mezcla = {}

-- Una pose quieta (Body la reusa cada cuadro).
function Mezcla.newPose(): Tipos.Pose
	return { phase = 0, effort = 0, turn = 0, jaw = 0, fins = 0, flap = 0, head = 0, tail = 0 }
end

-- Lo que pide una pose para una pectoral (+ = abajo).
local function fin(pose: Tricks.Pose, izq: boolean): number
	local f = pose.fin
	return if f then (if izq then f.izq else f.der) or 0 else 0
end

function Mezcla.action(
	pose: Tipos.Pose,
	trick: Tricks.Pose,
	w: number,
	big: Tricks.Pose,
	bw: number,
	add: Add
)
	pose.fins = pose.fins + (trick.fins or 0) * w + (big.fins or 0) * bw + add.fins
	pose.head = pose.head + (trick.head or 0) * w + (big.head or 0) * bw + add.head
	pose.tail = (trick.tail or 0) * w + (big.tail or 0) * bw + add.tail
	pose.waveIzq, pose.waveDer = add.waveIzq, add.waveDer
	pose.arch = (pose.arch or 0) + (trick.arch or 0) * w + (big.arch or 0) * bw
	pose.flukes = (trick.flukes or 0) * w + (big.flukes or 0) * bw
	pose.bend = (trick.bend or 0) * w + (big.bend or 0) * bw
	pose.finIzq = fin(trick, true) * w + fin(big, true) * bw
	pose.finDer = fin(trick, false) * w + fin(big, false) * bw
end

return table.freeze(Mezcla)
