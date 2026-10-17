--!strict
--[[
	DustDevils

	Remolinos de arena chicos que cruzan el desierto del cráter de vez en
	cuando: tres puntos que giran a distintas alturas (más abiertos arriba)
	sueltan polvo que sube, y el remolino avanza con el viento hasta
	deshacerse. Uno a la vez, solo si alguien lo puede ver (el jugador está en
	el cráter) y nunca en modo rápido. Locales.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local SandFx = require(script.Parent.SandFx)
local SandShape = require(script.Parent.SandShape)

local CENTER = WorldZones.craterCenter
local MIN_WAIT, MAX_WAIT = 7, 16
local LIFE_SECONDS = 8
local FADE_SECONDS = 2 -- al final deja de soltar polvo y se deshace
local DRIFT = 7 -- studs/s con el viento
local SPIN = 7 -- rad/s
-- Alto y radio de cada punto que gira.
local RINGS = { { 1, 2 }, { 6, 4.5 }, { 13, 8 } }

local DustDevils = {}

local rng = Random.new()

local function emitterAt(parent: Attachment, size: number): ParticleEmitter
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = Assets.Particles.Mist
	dust.Color = ColorSequence.new(SandFx.DUST)
	dust.Size = NumberSequence.new(size, size * 2.5)
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Lifetime = NumberRange.new(1, 1.6)
	dust.Speed = NumberRange.new(3, 6)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.SpreadAngle = Vector2.new(15, 15)
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-120, 120)
	dust.Rate = 18 * ClientSettings.fxScale()
	dust.Parent = parent
	return dust
end

-- Un remolino: nace en un punto de la arena, avanza y se deshace solo.
local function spawnDevil()
	local angle, radius = rng:NextNumber(0, math.pi * 2), rng:NextNumber(30, 150)
	local start = CENTER + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
	local points: { Attachment } = {}
	local emitters: { ParticleEmitter } = {}
	for _, ring in RINGS do
		local point = Instance.new("Attachment")
		point.Parent = Workspace.Terrain
		table.insert(points, point)
		table.insert(emitters, emitterAt(point, 1.5 + ring[2] * 0.4))
	end
	local function ground(at: Vector3): Vector3
		return Vector3.new(at.X, SandShape.top(at.X, at.Z), at.Z)
	end
	SandFx.puff(ground(start), 1.5)
	Sounds.play("Whoosh", ground(start), 0.45)
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		local base = ground(start + SandShape.WIND * DRIFT * elapsed)
		for i, ring in RINGS do
			local a = elapsed * SPIN + i * 2.1
			points[i].WorldPosition = base
				+ Vector3.new(math.cos(a) * ring[2], ring[1], math.sin(a) * ring[2])
		end
		if elapsed > LIFE_SECONDS - FADE_SECONDS then
			for _, dust in emitters do
				dust.Enabled = false
			end
		end
		if elapsed > LIFE_SECONDS then
			connection:Disconnect()
			for _, point in points do
				point:Destroy()
			end
		end
	end)
end

-- Mientras active() sea true, cada tanto pasa un remolino.
function DustDevils.start(active: () -> boolean)
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(MIN_WAIT, MAX_WAIT))
			local character = Players.LocalPlayer.Character
			local near = character and WorldZones.craterBlend(character:GetPivot().Position) > 0.5
			if active() and near and ClientSettings.fxScale() > 0 then
				spawnDevil()
			end
		end
	end)
end

return table.freeze(DustDevils)
