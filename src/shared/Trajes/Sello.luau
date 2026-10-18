--!strict
--[[
	Trajes/Sello

	El sello de magma del Dios del Volcán: el poder está en el piso y en la
	silueta, no encima del cuerpo (las lenguas de fuego tapaban el traje).
	Charco de lava que brilla, aro de runas que gira, una onda de choque cada
	tanto, brasas ralas que suben más alto que la cabeza, un halo tenue detrás
	del cuerpo y el contorno de lava. Tamaños en altos del traje.
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
	local seal = Instance.new("Attachment")
	seal.Name = "Sello"
	seal.Parent = floor
	Aura.add(fx, seal, { -- charco de lava
		texture = T.Halo,
		colors = { rgb(255, 80, 10), rgb(140, 15, 0) },
		size = { 0.9, 1.0, 0.9 },
		alpha = { 1, 0.72, 0.75, 1 },
		life = { 2.4, 2.4 },
		speed = { 0.001, 0.001 },
		rate = 1.2,
		light = 0.6,
		bright = 1,
		flat = true,
		locked = true,
		z = -1,
	})
	Aura.add(fx, seal, { -- aro de runas que gira
		texture = T.Anillo,
		colors = { rgb(255, 150, 40), rgb(255, 70, 0) },
		size = { 0.8 },
		alpha = { 1, 0.15, 0.15, 1 },
		life = { 3, 3 },
		speed = { 0.001, 0.001 },
		spin = { 18, 18 },
		rate = 0.7,
		light = 1,
		bright = 2,
		flat = true,
		locked = true,
		tilt = 0,
	})
	Aura.add(fx, seal, { -- onda de choque
		texture = T.Anillo,
		colors = { rgb(255, 230, 150), rgb(255, 70, 0) },
		size = { 0.3, 1.6, 2.1 },
		alpha = { 0.1, 0.5, 1 },
		life = { 1.1, 1.1 },
		speed = { 0.001, 0.001 },
		rate = 0.28,
		light = 1,
		bright = 2.5,
		flat = true,
	})
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
