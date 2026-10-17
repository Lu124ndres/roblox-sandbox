--!strict
--[[
	DragonDust

	Lo que levanta el dragón en su guarida volcánica cuando toca o barre el
	suelo: ceniza que sube despacio (está caliente), un faldón de polvo de
	obsidiana que corre pegado a la roca, esquirlas negras que saltan, chispas
	de la piedra al golpear y, sobre la lava, brasas que vuelan. scale 1 = una
	persona (DragonKit.scale: el anciano ~8); todo crece con él.
		land(pos, scale, radio, lava)     se posa en la roca: golpe, anillo, esquirlas
		takeoff(pos, scale, radio, lava)  despega: el aire de las alas barre el suelo
		gust(pos, scale, lava)            un aletazo cerca del suelo o de la lava
	Con efectos reducidos no sale ninguna partícula; el anillo sí (una pieza).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local DragonKit = require(script.Parent.DragonKit)

local rgb = Color3.fromRGB
local ASH = ColorSequence.new(rgb(128, 120, 118), rgb(64, 58, 60))
local OBSIDIAN = ColorSequence.new(rgb(40, 34, 46), rgb(18, 14, 20))
local SPARKS = ColorSequence.new(rgb(255, 230, 150), rgb(255, 110, 30))
local EMBERS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 220, 120)),
	ColorSequenceKeypoint.new(0.5, rgb(255, 120, 30)),
	ColorSequenceKeypoint.new(1, rgb(150, 30, 10)),
})
local AIR = rgb(220, 214, 210) -- el anillo de aire del despegue
local SKIRT_DIRECTIONS = 12

local DragonDust = {}

-- Nube de ceniza que sube despacio y se abre.
local function cloud(parent: Instance, scale: number, count: number)
	local ash = DragonKit.emitter(parent, Assets.Particles.Mist, ASH, false)
	ash.Size = NumberSequence.new(1.5 * scale, 5 * scale)
	ash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	ash.Lifetime = NumberRange.new(1.6, 2.8)
	ash.Speed = NumberRange.new(4 * scale, 9 * scale)
	ash.SpreadAngle = Vector2.new(60, 60)
	ash.Drag = 1.5
	ash.Acceleration = Vector3.new(0, 1.5 * scale, 0)
	DragonKit.burst(ash, count)
end

-- Faldón: el polvo sale en todas direcciones pegado al suelo y se frena
-- (un emisor que se gira entre ráfagas; sale hacia el frente del Attachment).
local function skirt(position: Vector3, scale: number, count: number, speed: number)
	local each = math.floor(DragonKit.amount(count) / SKIRT_DIRECTIONS)
	if each < 1 then
		return
	end
	local attachment = DragonKit.anchor(position, 3.5)
	local dust = DragonKit.emitter(attachment, Assets.Particles.Mist, ASH, false)
	dust.EmissionDirection = Enum.NormalId.Front
	dust.Size = NumberSequence.new(1.2 * scale, 4 * scale)
	dust.Transparency = NumberSequence.new(0.5, 1)
	dust.Lifetime = NumberRange.new(1, 1.8)
	dust.Speed = NumberRange.new(16 * scale * speed, 26 * scale * speed)
	dust.SpreadAngle = Vector2.new(14, 6)
	dust.Drag = 3
	dust.Acceleration = Vector3.new(0, scale, 0)
	for index = 1, SKIRT_DIRECTIONS do
		local yaw = (index + math.random()) / SKIRT_DIRECTIONS * math.pi * 2
		attachment.WorldCFrame = CFrame.new(position)
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(math.rad(8), 0, 0)
		dust:Emit(each)
	end
end

-- Esquirlas de obsidiana que saltan y caen (la gravedad crece con scale).
local function grit(parent: Instance, scale: number, count: number)
	local bits = DragonKit.emitter(parent, Assets.Particles.Sparkle, OBSIDIAN, false)
	bits.Size = NumberSequence.new(0.4 * scale, 0.15 * scale)
	bits.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	bits.Lifetime = NumberRange.new(0.6, 1.1)
	bits.Speed = NumberRange.new(12 * scale, 22 * scale)
	bits.SpreadAngle = Vector2.new(45, 45)
	bits.Acceleration = Vector3.new(0, -45 * scale, 0)
	DragonKit.burst(bits, count)
end

-- Chispas de la piedra al golpear: rápidas, cortas, caen un poco.
local function sparks(parent: Instance, scale: number, count: number)
	local spark = DragonKit.emitter(parent, Assets.Particles.Spark, SPARKS, true)
	spark.Size = NumberSequence.new(0.35 * scale, 0)
	spark.Lifetime = NumberRange.new(0.35, 0.8)
	spark.Speed = NumberRange.new(14 * scale, 28 * scale)
	spark.SpreadAngle = Vector2.new(70, 70)
	spark.Acceleration = Vector3.new(0, -20 * scale, 0)
	spark.Drag = 1
	DragonKit.burst(spark, count)
end

-- Brasas que vuelan de la lava: suben con el aire caliente y se apagan.
local function embers(parent: Instance, scale: number, count: number, speed: number)
	local ember = DragonKit.emitter(parent, Assets.Particles.Brasa, EMBERS, true)
	ember.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3 * scale),
		NumberSequenceKeypoint.new(0.7, 0.22 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	ember.Lifetime = NumberRange.new(1.4, 2.6)
	ember.Speed = NumberRange.new(6 * scale * speed, 14 * scale * speed)
	ember.SpreadAngle = Vector2.new(55, 55)
	ember.Drag = 1.2
	ember.Acceleration = Vector3.new(0, 3 * scale, 0)
	ember.RotSpeed = NumberRange.new(-120, 120)
	DragonKit.burst(ember, count)
end

function DragonDust.land(position: Vector3, scale: number, radius: number, lava: boolean)
	local attachment = DragonKit.anchor(position, 4)
	cloud(attachment, scale, 6 + 2 * scale)
	skirt(position, scale, 24 + 4 * scale, 1)
	grit(attachment, scale, 12 + 3 * scale)
	sparks(attachment, scale, 8 + 2 * scale)
	if lava then
		embers(attachment, scale, 14 + 3 * scale, 1)
	end
	DragonKit.ring(position, radius, 1.3, ASH.Keypoints[1].Value)
end

function DragonDust.takeoff(position: Vector3, scale: number, radius: number, lava: boolean)
	local attachment = DragonKit.anchor(position, 4)
	cloud(attachment, scale, 4 + scale)
	skirt(position, scale, 30 + 4 * scale, 1.3)
	if lava then
		embers(attachment, scale, 20 + 4 * scale, 1.4)
	end
	DragonKit.ring(position, radius * 1.2, 0.9, AIR)
end

function DragonDust.gust(position: Vector3, scale: number, lava: boolean)
	skirt(position, 0.7 * scale, 10 + 2 * scale, 0.8)
	if lava then
		embers(DragonKit.anchor(position, 3), 0.8 * scale, 6 + 2 * scale, 1)
	end
end

return table.freeze(DragonDust)
