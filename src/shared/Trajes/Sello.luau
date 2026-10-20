--!strict
--[[
	Trajes/Sello

	El sello de magma del Dios del Volcán: el poder está en el piso y en la
	silueta, no encima del cuerpo (las lenguas de fuego tapaban el traje).
	Brasas ralas que suben del piso más alto que la cabeza, un halo tenue
	detrás del cuerpo y el contorno de lava. Sin aros ni charco en el piso
	(pedido del usuario el 2026-10-20: «es solo un círculo»). Tamaños en
	altos del traje.
]]

local Aura = require(script.Parent.Aura)
local Particulas = require(script.Parent.Particulas)
local Tipos = require(script.Parent.Tipos)

local T = Particulas.Textures
local rgb = Color3.fromRGB
local LAVA = rgb(255, 120, 30)

local Sello = {}

function Sello.build(fx: Tipos.Fx)
	local floor = fx.aura(Vector3.new(0.7, 0.02, 0.7), 0.01)
	Aura.add(fx, floor, { -- brasas ralas que suben del sello
		texture = T.Brasa,
		colors = { rgb(255, 235, 160), LAVA, rgb(200, 40, 0) },
		size = { 0.04, 0.03, 0 },
		alpha = { 0, 0.1, 1 },
		life = { 2.2, 3.2 },
		speed = { 0.25, 0.45 },
		accel = Vector3.new(0, 0.1, 0),
		rate = 14,
		light = 1,
		bright = 2,
		spread = 8,
		drag = 0.3,
		shape = Enum.ParticleEmitterShape.Disc,
		z = 0.5,
	})
	Aura.add(fx, fx.socket("Pecho", Vector3.zero), { -- halo tenue detrás del cuerpo
		texture = T.Halo,
		colors = { rgb(255, 110, 20) },
		size = { 0.9, 1.05, 0.95 },
		alpha = { 1, 0.88, 0.9, 1 },
		life = { 1.6, 2 },
		rate = 1.5,
		light = 1,
		locked = true,
		z = -4,
	})
	fx.highlight(rgb(255, 150, 40), rgb(255, 150, 40), 1)
end

return table.freeze(Sello)
