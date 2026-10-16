--!strict
--[[
	Trajes/Aura

	El aura de los trajes de pase. Sale de dos piezas invisibles (cuerpo y
	piso, ver Efectos.aura) y de un punto en el pecho:
		lenguas    fuego o agua (hoja animada) por toda la superficie del cuerpo
		pies       más lenguas en un aro a sus pies
		motas      brasas o burbujas que suben y se apagan
		destellos  estrellitas que titilan alrededor
		halo       brillo grande detrás del cuerpo que respira
		onda       aro que se abre en el piso cada tanto
	más el contorno brillante (Highlight sin relleno). Los colores y las
	lenguas los pone cada estilo (Palette); tamaños en altos del traje.
]]

local Particulas = require(script.Parent.Particulas)
local Tipos = require(script.Parent.Tipos)

export type Palette = {
	tongues: Particulas.Spec, -- sin forma: la pone el aura
	feet: Particulas.Spec,
	motes: Particulas.Spec,
	glints: Particulas.Spec,
	glow: Color3, -- halo
	ring: { Color3 }, -- onda del piso
	outline: Color3,
}

local T = Particulas.Textures
local CYL = Enum.ParticleEmitterShape.Cylinder

local Aura = {}

-- Crea el emisor del spec en parent (si hay) respetando los efectos reducidos.
function Aura.add(fx: Tipos.Fx, parent: Instance?, spec: Particulas.Spec): ParticleEmitter?
	if not parent then
		return nil
	end
	local e = Particulas.new(spec, fx.height)
	e.Parent = parent
	fx.emitter(e)
	return e
end

local function shaped(spec: Particulas.Spec, surface: boolean): Particulas.Spec
	local copy = table.clone(spec)
	copy.shape = CYL
	copy.surface = surface
	return copy
end

function Aura.build(fx: Tipos.Fx, palette: Palette)
	local body = fx.aura(Vector3.new(0.55, 0.85, 0.55), 0.47)
	local feet = fx.aura(Vector3.new(0.8, 0.02, 0.8), 0.02)
	Aura.add(fx, body, shaped(palette.tongues, true))
	Aura.add(fx, feet, shaped(palette.feet, true))
	Aura.add(fx, body, shaped(palette.motes, false))
	Aura.add(fx, body, shaped(palette.glints, false))
	Aura.add(fx, fx.socket("Pecho", Vector3.zero), {
		texture = T.Halo,
		colors = { palette.glow },
		size = { 0.95, 1.15, 1 },
		alpha = { 1, 0.8, 0.82, 1 },
		life = { 1.4, 1.8 },
		rate = 2.5,
		light = 1,
		locked = true,
		z = -4,
	})
	local center = Instance.new("Attachment")
	center.Name = "Centro"
	center.Parent = feet
	Aura.add(fx, center, {
		texture = T.Anillo,
		colors = palette.ring,
		size = { 0.12, 0.75, 1 },
		alpha = { 0.15, 0.4, 1 },
		life = { 1.3, 1.3 },
		speed = { 0.001, 0.001 },
		rate = 0.8,
		light = 1,
		bright = 2,
		flat = true,
	})
	fx.highlight(palette.outline, palette.outline, 1)
end

return table.freeze(Aura)
