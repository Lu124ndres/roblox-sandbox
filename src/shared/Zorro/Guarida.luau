--!strict
--[[
	Zorro/Guarida

	Dónde está cada lugar fijo del hábitat de hielo del zorro de agua (el cráter con
	agua, témpanos y escarcha, ver Ambient/IceLair). Es un contrato entre dos partes
	que se hacen por separado: el hábitat (cliente, Ambient) arma los témpanos y la
	roca en estos lugares y el zorro (Zorro/...) se para, se echa o vigila en ellos.
	Si se mueve algo, se mueve aquí y los dos lo siguen.
		spots   los lugares: témpanos grandes y la roca de vigía
		  name    nombre (para depurar y para la conducta que lo elige)
		  kind    "tempano" (losa de hielo que flota) o "roca" (peñón con nieve)
		  uses    qué hace ahí: "parar", "dormir" o "vigia"
		  angle   ángulo alrededor del cráter (rad, 0 = +X, π/2 = +Z)
		  radius  distancia al centro del cráter (studs)
		  top     alto de la cima sobre el agua (studs; ahí apoya las patas)
		  size    radio de la parte plana que se pisa (studs): cabe la forma final
		          (E4 de pie: ~56 de pata a pata y ~27 de ancho, unos 31 de radio;
		          echada y enroscada, unos 35)
		  turn    giro extra (rad) sobre "de frente a la puerta" (dentro de ±60°)
		water   altura del agua (Y)
	point(spot) da la cima (Vector3); yaw(spot) el rumbo con la convención de Zorro
	(CFrame.Angles(0, yaw, 0) mira a (-sin yaw, 0, -cos yaw)), de frente a la puerta
	del cráter (WorldZones.craterDoor(), donde sale el túnel: por ahí llegan los
	jugadores); cframe(spot) junta las dos cosas. Las cuatro etapas (16.5, 44, 82.5 y
	165 de alto) usan los mismos lugares: la cría se para en el medio y la forma final
	ocupa casi toda la losa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

export type Use = "parar" | "dormir" | "vigia"
export type Spot = {
	name: string,
	kind: "tempano" | "roca",
	uses: { Use },
	angle: number,
	radius: number,
	top: number,
	size: number,
	turn: number,
}

local WATER = WorldLayout.waterLevel
local FLOE_TOP = 1.2 -- lo que asoma un témpano grande sobre el agua

local SPOTS: { Spot } = {
	-- En el centro, donde vive hoy: la losa más grande, para dormir enroscado.
	{
		name = "Centro",
		kind = "tempano",
		uses = { "parar", "dormir" },
		angle = 0,
		radius = 0,
		top = FLOE_TOP,
		size = 36,
		turn = 0,
	},
	-- Del lado de la puerta, a la izquierda de quien llega: cerca del público.
	{
		name = "Puerta",
		kind = "tempano",
		uses = { "parar" },
		angle = math.rad(215),
		radius = 115,
		top = FLOE_TOP,
		size = 30,
		turn = 0,
	},
	-- Del lado de la puerta, a la derecha.
	{
		name = "Orilla",
		kind = "tempano",
		uses = { "parar", "dormir" },
		angle = math.rad(330),
		radius = 110,
		top = FLOE_TOP,
		size = 30,
		turn = 0,
	},
	-- Al fondo, frente a la puerta: de ahí se lo ve entero y de frente.
	{
		name = "Fondo",
		kind = "tempano",
		uses = { "parar", "dormir" },
		angle = math.rad(100),
		radius = 112,
		top = FLOE_TOP,
		size = 32,
		turn = 0,
	},
	-- La roca de vigía: se sienta erguido y mira (centinela) o aúlla.
	{
		name = "Vigia",
		kind = "roca",
		uses = { "vigia", "parar" },
		angle = math.rad(160),
		radius = 128,
		top = 14,
		size = 24,
		turn = 0,
	},
}

local Guarida = {}

Guarida.water = WATER
Guarida.spots = table.freeze(SPOTS)

function Guarida.point(spot: Spot): Vector3
	local c = WorldZones.craterCenter
	return Vector3.new(
		c.X + math.cos(spot.angle) * spot.radius,
		WATER + spot.top,
		c.Z + math.sin(spot.angle) * spot.radius
	)
end

-- La puerta del cráter: donde el túnel sale al paseo (a la altura del agua).
function Guarida.door(): Vector3
	local door = WorldZones.craterDoor()
	return Vector3.new(door.X, WATER, door.Z)
end

function Guarida.yaw(spot: Spot): number
	local d = Guarida.door() - Guarida.point(spot)
	return math.atan2(-d.X, -d.Z) + spot.turn
end

-- En la cima del lugar, de frente a la puerta (-Z al frente, como el pivote del zorro).
function Guarida.cframe(spot: Spot): CFrame
	return CFrame.new(Guarida.point(spot)) * CFrame.Angles(0, Guarida.yaw(spot), 0)
end

-- El lugar con ese nombre (nil si no hay).
function Guarida.find(name: string): Spot?
	for _, spot in Guarida.spots do
		if spot.name == name then
			return spot
		end
	end
	return nil
end

return table.freeze(Guarida)
