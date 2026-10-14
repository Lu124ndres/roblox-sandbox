--!strict
--[[
	Flock

	Bandadas de pájaros de primitivas que vuelan en círculos, aletean y
	gritan de vez en cuando: gaviotas blancas sobre la isla y murciélagos
	negros sobre el cráter. Locales y sin colisión.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

export type Options = {
	name: string,
	center: Vector3, -- centro de la órbita (Y = altura media)
	count: number,
	radius: number,
	bodyColor: Color3,
	wingColor: Color3,
	beakColor: Color3,
	size: number, -- 1 = gaviota
	flapSpeed: number, -- radianes por segundo del aleteo
	orbitSeconds: number, -- vuelta completa
	sound: string?, -- clave de Assets.Sounds
}

local EFFECTS = UIConfig.Effects

local Flock = {}

type Bird = {
	body: Part,
	beak: Part,
	wings: { Part },
	radius: number,
	height: number,
	phase: number,
	direction: number,
}

local function part(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.Parent = parent
	return piece
end

local function buildBird(options: Options, parent: Instance): (Part, Part, { Part })
	local s = options.size
	local body = part("Cuerpo", Vector3.one * s, options.bodyColor, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.9, 0.9, 2.2)
	mesh.Parent = body
	local beak = part("Pico", Vector3.new(0.25, 0.25, 0.7) * s, options.beakColor, parent)
	local wings = {}
	for side = -1, 1, 2 do
		table.insert(
			wings,
			part(`Ala{side}`, Vector3.new(2.6, 0.12, 1) * s, options.wingColor, parent)
		)
	end
	return body, beak, wings
end

function Flock.start(options: Options)
	local folder = Instance.new("Folder")
	folder.Name = options.name
	folder.Parent = Workspace
	local rng = Random.new()
	local birds: { Bird } = {}
	for index = 1, options.count do
		local body, beak, wings = buildBird(options, folder)
		table.insert(birds, {
			body = body,
			beak = beak,
			wings = wings,
			radius = options.radius * rng:NextNumber(0.6, 1.2),
			height = options.center.Y + rng:NextNumber(-8, 12),
			phase = index * (math.pi * 2 / options.count),
			direction = if index % 2 == 0 then 1 else -1,
		})
	end

	local s = options.size
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		for _, bird in birds do
			local angle = bird.phase + bird.direction * elapsed * 2 * math.pi / options.orbitSeconds
			local position = options.center
				+ Vector3.new(
					math.cos(angle) * bird.radius,
					bird.height - options.center.Y + math.sin(elapsed + bird.phase) * 2,
					math.sin(angle) * bird.radius
				)
			local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle)) * bird.direction
			local frame = CFrame.lookAt(position, position + tangent)
				* CFrame.Angles(0, 0, math.rad(-12 * bird.direction))
			bird.body.CFrame = frame
			bird.beak.CFrame = frame * CFrame.new(0, 0, -1.3 * s)
			local flap = math.sin(elapsed * options.flapSpeed + bird.phase) * 0.55
			bird.wings[1].CFrame = frame * CFrame.Angles(0, 0, flap) * CFrame.new(-1.4 * s, 0, 0)
			bird.wings[2].CFrame = frame * CFrame.Angles(0, 0, -flap) * CFrame.new(1.4 * s, 0, 0)
		end
	end)

	local sound = options.sound
	if sound then
		task.spawn(function()
			while true do
				task.wait(
					rng:NextNumber(EFFECTS.SeagullCallMinSeconds, EFFECTS.SeagullCallMaxSeconds)
				)
				local bird = birds[rng:NextInteger(1, #birds)]
				if bird then
					Sounds.play(sound, bird.body.Position)
				end
			end
		end)
	end
end

return Flock
