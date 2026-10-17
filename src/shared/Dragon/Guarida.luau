--!strict
--[[
	Dragon/Guarida

	Dónde está cada cosa de la guarida volcánica del dragón (el cráter lleno de
	lava, ver Ambient/CraterLava). Es un contrato entre dos partes que se hacen por
	separado: el hábitat (cliente, Ambient) levanta las rocas y el nido en estos
	lugares, y el dragón (Dragon/...) se posa en ellos. Si se mueve algo, se mueve
	aquí y los dos lo siguen.
		perches  rocas de obsidiana donde se posa: ángulo alrededor del cráter
		         (rad, 0 = +X), distancia al centro, alto de la cima sobre la lava
		         y radio de la cima (studs; cabe la forma final, de ~100 de largo)
		nest     el nido con huevos, sobre la roca central
		lava     altura de la superficie de la lava (Y, studs)
	Posiciones con point(): Vector3 de la cima (donde apoyan las patas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

export type Perch = { angle: number, radius: number, top: number, size: number }

local LAVA = -25 -- la de CraterLava (LEVEL)

local Guarida = {}

Guarida.lava = LAVA
Guarida.perches = table.freeze({
	{ angle = 0, radius = 0, top = 22, size = 34 }, -- la roca central, con el nido
	{ angle = math.rad(35), radius = 128, top = 14, size = 26 },
	{ angle = math.rad(155), radius = 132, top = 18, size = 26 },
	{ angle = math.rad(265), radius = 124, top = 10, size = 24 },
} :: { Perch })
Guarida.nest = table.freeze({ perch = 1, offset = Vector3.new(0, 0, 12) }) -- sobre la central, atrás

function Guarida.point(perch: Perch): Vector3
	local c = WorldZones.craterCenter
	return Vector3.new(
		c.X + math.cos(perch.angle) * perch.radius,
		LAVA + perch.top,
		c.Z + math.sin(perch.angle) * perch.radius
	)
end

return table.freeze(Guarida)
