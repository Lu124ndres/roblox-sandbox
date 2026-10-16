--!strict
--[[
	Trajes/Particulas

	Arma emisores de partículas de los estilos de los trajes con pocas
	líneas: tamaños y velocidades en altos del traje (`h`), colores y
	transparencias como listas de puntos. Texturas: las que trae Roblox y las
	propias del juego (Assets.Particles; las "Flip" son hojas animadas 4x4).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

export type Spec = {
	texture: string,
	colors: { Color3 },
	size: { number }, -- en altos del traje: inicio, (medio,) final
	alpha: { number }?, -- transparencia: inicio, final
	life: { number }, -- segundos: mínimo, máximo
	speed: { number }?, -- en altos/s
	accel: Vector3?, -- en altos/s²
	rate: number,
	light: number?, -- LightEmission
	spin: { number }?, -- RotSpeed mínimo, máximo
	spread: number?, -- grados
	drag: number?,
	shape: Enum.ParticleEmitterShape?, -- desde una pieza (aura)
	surface: boolean?, -- sale de la superficie de la forma
	locked: boolean?,
	z: number?, -- ZOffset
	flip: boolean?, -- hoja 4x4 que se reproduce una vez en la vida de la partícula
	flat: boolean?, -- acostada, de frente a su velocidad (aros en el piso)
	bright: number?, -- Brightness
	tilt: number?, -- giro inicial máximo en grados (sin esto: cualquiera; llamas: poco)
}

local Particulas = {}

Particulas.Textures = {
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Vortex = "rbxasset://textures/particles/forcefield_vortex_main.dds",
	Glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	Fuego = Assets.Particles.FuegoFlip,
	Agua = Assets.Particles.AguaFlip,
	Brasa = Assets.Particles.Brasa,
	Halo = Assets.Particles.Halo,
	Anillo = Assets.Particles.Anillo,
	Chispa = Assets.Particles.Chispa,
	Burbuja = Assets.Particles.Burbuja,
}

local function sequence(values: { number }, scale: number): NumberSequence
	if #values == 1 then
		return NumberSequence.new(values[1] * scale)
	end
	local points = {}
	for index, value in values do
		table.insert(points, NumberSequenceKeypoint.new((index - 1) / (#values - 1), value * scale))
	end
	return NumberSequence.new(points)
end

local function colors(list: { Color3 }): ColorSequence
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local points = {}
	for index, color in list do
		table.insert(points, ColorSequenceKeypoint.new((index - 1) / (#list - 1), color))
	end
	return ColorSequence.new(points)
end

function Particulas.new(spec: Spec, h: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = spec.texture
	e.Color = colors(spec.colors)
	e.Size = sequence(spec.size, h)
	e.Transparency = sequence(spec.alpha or { 0, 1 }, 1)
	e.Lifetime = NumberRange.new(spec.life[1], spec.life[2])
	local speed = spec.speed or { 0, 0 }
	e.Speed = NumberRange.new(speed[1] * h, speed[2] * h)
	e.Acceleration = (spec.accel or Vector3.zero) * h
	e.Rate = spec.rate
	e.LightEmission = spec.light or 0
	e.LightInfluence = if (spec.light or 0) >= 0.3 then 0 else 1
	e.Brightness = spec.bright or 1
	local spin = spec.spin or { 0, 0 }
	e.RotSpeed = NumberRange.new(spin[1], spin[2])
	local tilt = spec.tilt or 180
	e.Rotation = NumberRange.new(-tilt, tilt)
	local spread = spec.spread or 0
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Drag = spec.drag or 0
	e.LockedToPart = spec.locked == true
	e.ZOffset = spec.z or 0
	if spec.flip then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	end
	if spec.flat then
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	end
	if spec.shape then
		e.Shape = spec.shape
		e.ShapeStyle = if spec.surface
			then Enum.ParticleEmitterShapeStyle.Surface
			else Enum.ParticleEmitterShapeStyle.Volume
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	end
	return e
end

return table.freeze(Particulas)
