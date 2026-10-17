--!strict
--[[
	Dragon/Fuego

	El chorro de fuego que sale de la boca, en capas (todas desde un hueso
	nuevo, Fuego, hijo de Boca, que sigue la animación):
		core    núcleo blanco amarillo, fino y rápido
		flames  la llama naranja que se abre y se oscurece a rojo
		licks   lenguas de fuego (hoja animada FuegoFlip) que se rompen
		heat    resplandor de calor alrededor del chorro
		sparks  chispas que se escapan y caen (no siguen a la boca)
		smoke   humo negro que aparece al final del chorro y sube
		light   una luz que parpadea en la boca y otra donde llega el fuego
	El largo del chorro es el del dragón por fireSize de su etapa. sky (0..1)
	gira el chorro hacia arriba (fuego al cielo). Lo maneja Dragon/Fx.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rgb = Color3.fromRGB
local REACH = 0.85 -- dónde está la luz del final, en largos del chorro

export type Fuego = {
	socket: Bone,
	tail: Bone,
	emitters: { [string]: ParticleEmitter },
	lights: { PointLight },
	length: number,
	on: boolean,
}

local Fuego = {}

local function keys(...: number): NumberSequence
	local list, values = {}, { ... }
	for i, v in values do
		table.insert(list, NumberSequenceKeypoint.new((i - 1) / (#values - 1), v))
	end
	return NumberSequence.new(list)
end

local function colors(...: Color3): ColorSequence
	local list, values = {}, { ... }
	for i, c in values do
		table.insert(list, ColorSequenceKeypoint.new((i - 1) / (#values - 1), c))
	end
	return ColorSequence.new(list)
end

local function emitter(
	parent: Bone,
	texture: string,
	rate: number,
	locked: boolean
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Rate = rate
	e.LockedToPart = locked -- el dragón vuela más rápido que el chorro: que viaje con la boca
	e.EmissionDirection = Enum.NormalId.Front
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Enabled = false
	e.Parent = parent
	return e
end

local function light(parent: Bone): PointLight
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 140, 40)
	l.Shadows = false
	l.Enabled = false
	l.Parent = parent
	return l
end

function Fuego.build(boca: Bone): Fuego
	local socket = Instance.new("Bone")
	socket.Name = "Fuego"
	socket.Parent = boca
	local tail = Instance.new("Bone")
	tail.Name = "FinFuego"
	tail.Parent = socket
	local e: { [string]: ParticleEmitter } = {
		core = emitter(socket, FIRE, 60, true),
		flames = emitter(socket, FIRE, 55, true),
		licks = emitter(socket, Assets.Particles.FuegoFlip, 14, true),
		heat = emitter(socket, Assets.Particles.Halo, 8, true),
		sparks = emitter(socket, Assets.Particles.Spark, 30, false),
		smoke = emitter(socket, Assets.Particles.Mist, 10, false),
	}
	e.core.Color = colors(rgb(255, 255, 235), rgb(255, 230, 140), rgb(255, 150, 40))
	e.core.Transparency = keys(0, 0.2, 1)
	e.core.SpreadAngle = Vector2.new(4, 4)
	e.flames.Color = colors(rgb(255, 220, 120), rgb(255, 130, 30), rgb(170, 30, 8))
	e.flames.Transparency = keys(0.15, 0.35, 1)
	e.flames.SpreadAngle = Vector2.new(10, 10)
	e.licks.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	e.licks.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	e.licks.Color = ColorSequence.new(rgb(255, 170, 60), rgb(220, 60, 15))
	e.licks.SpreadAngle = Vector2.new(14, 14)
	e.heat.Color = ColorSequence.new(rgb(255, 150, 60))
	e.heat.Transparency = keys(0.8, 0.9, 1)
	e.sparks.Color = ColorSequence.new(rgb(255, 230, 150), rgb(255, 100, 20))
	e.sparks.SpreadAngle = Vector2.new(22, 22)
	e.sparks.Drag = 1
	e.smoke.Color = ColorSequence.new(rgb(50, 44, 44), rgb(20, 18, 20))
	e.smoke.LightEmission, e.smoke.LightInfluence = 0, 1
	e.smoke.Transparency = keys(1, 1, 0.55, 0.75, 1)
	e.smoke.SpreadAngle = Vector2.new(14, 14)
	e.smoke.Drag = 0.8
	return {
		socket = socket,
		tail = tail,
		emitters = e,
		lights = { light(socket), light(tail) },
		length = 0,
		on = false,
	}
end

-- Tamaños y velocidades para un chorro de L studs.
function Fuego.resize(f: Fuego, L: number)
	f.length = L
	local e = f.emitters
	e.core.Size = keys(0.03 * L, 0.09 * L, 0.12 * L)
	e.core.Speed = NumberRange.new(1.5 * L, 1.8 * L)
	e.core.Lifetime = NumberRange.new(0.3, 0.45)
	e.flames.Size = keys(0.06 * L, 0.2 * L, 0.32 * L)
	e.flames.Speed = NumberRange.new(1.1 * L, 1.5 * L)
	e.flames.Lifetime = NumberRange.new(0.45, 0.7)
	e.flames.Acceleration = Vector3.new(0, 0.2 * L, 0)
	e.licks.Size = keys(0.1 * L, 0.3 * L)
	e.licks.Speed = NumberRange.new(0.9 * L, 1.3 * L)
	e.licks.Lifetime = NumberRange.new(0.5, 0.8)
	e.heat.Size = keys(0.2 * L, 0.5 * L)
	e.heat.Speed = NumberRange.new(L, 1.2 * L)
	e.heat.Lifetime = NumberRange.new(0.5, 0.7)
	e.sparks.Size = keys(0.025 * L, 0)
	e.sparks.Speed = NumberRange.new(1.2 * L, 1.9 * L)
	e.sparks.Lifetime = NumberRange.new(0.6, 1.1)
	e.sparks.Acceleration = Vector3.new(0, -0.25 * L, 0)
	e.smoke.Size = keys(0.15 * L, 0.45 * L)
	e.smoke.Speed = NumberRange.new(0.8 * L, 1.1 * L)
	e.smoke.Lifetime = NumberRange.new(1.2, 1.8)
	e.smoke.Acceleration = Vector3.new(0, 0.15 * L, 0)
	f.tail.CFrame = CFrame.new(0, 0, -REACH * L) -- adelante del hueso Fuego (su frente es -Z)
	for _, l in f.lights do
		l.Range = math.min(1.2 * L, 60)
	end
end

-- Enciende o apaga y apunta el chorro: adelante de la cabeza, o al cielo con sky.
function Fuego.step(f: Fuego, boca: Bone, cabeza: Bone, on: boolean, sky: number)
	if on ~= f.on then
		f.on = on
		for _, e in f.emitters do
			e.Enabled = on
		end
		for _, l in f.lights do
			l.Enabled = on
		end
		if on then
			f.emitters.core:Emit(6)
		end
	end
	if not on then
		return
	end
	local mouth = boca.TransformedWorldCFrame
	local forward = mouth.Position - cabeza.TransformedWorldCFrame.Position
	forward = if forward.Magnitude > 1e-3 then forward.Unit else mouth.LookVector
	local dir = forward:Lerp(Vector3.yAxis, math.clamp(sky, 0, 1))
	dir = if dir.Magnitude > 1e-3 then dir.Unit else Vector3.yAxis
	local aim = mouth:VectorToObjectSpace(dir)
	local up = if math.abs(aim.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis -- lookAt sin eje paralelo
	f.socket.CFrame = CFrame.lookAt(Vector3.zero, aim, up)
	for i, l in f.lights do
		l.Brightness = (if i == 1 then 4 else 2.5) * (0.8 + 0.4 * math.random())
	end
end

function Fuego.destroy(f: Fuego)
	f.socket:Destroy()
end

return table.freeze(Fuego)
