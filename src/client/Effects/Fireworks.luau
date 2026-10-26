--!strict
--[[
	Fireworks

	Fuegos artificiales del panel de administrador (Notice "fireworks", lo
	escucha Menus/AdminShow): cohetes de neón que suben alrededor del jugador
	y estallan en chispas de colores. Todo es local y se borra solo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Sounds = require(script.Parent.Parent.Audio.Sounds)

local ROCKETS = 10
local SPREAD = 45 -- studs alrededor del jugador
local HEIGHT = NumberRange.new(40, 70)
local RISE_SECONDS = 1.1
local GAP_SECONDS = 0.35
local SPARKS = 90
local CLEANUP_SECONDS = 4
local COLORS = {
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(255, 206, 84),
	Color3.fromRGB(110, 235, 90),
	Color3.fromRGB(80, 190, 255),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(255, 140, 220),
}
local RISE = TweenInfo.new(RISE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Fireworks = {}

local rng = Random.new()

local function burst(folder: Folder, at: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = at
	anchor.Parent = folder
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparks.LightEmission = 1
	sparks.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new(0, 1)
	sparks.Lifetime = NumberRange.new(1.2, 2)
	sparks.Speed = NumberRange.new(28, 45)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, -18, 0)
	sparks.Drag = 1.5
	sparks.Rate = 0
	sparks.Parent = anchor
	sparks:Emit(SPARKS)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 40
	light.Brightness = 4
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(1), { Brightness = 0 }):Play()
end

local function rocket(folder: Folder, center: Vector3)
	local offset = Vector3.new(rng:NextNumber(-SPREAD, SPREAD), 0, rng:NextNumber(-SPREAD, SPREAD))
	local start = center + offset
	local finish = start + Vector3.new(0, rng:NextNumber(HEIGHT.Min, HEIGHT.Max), 0)
	local color = COLORS[rng:NextInteger(1, #COLORS)]
	local body = Instance.new("Part")
	body.Anchored = true
	body.CanCollide, body.CanQuery, body.CanTouch = false, false, false
	body.Material = Enum.Material.Neon
	body.Color = color
	body.Size = Vector3.new(0.6, 2, 0.6)
	body.Position = start
	body.Parent = folder
	TweenService:Create(body, RISE, { Position = finish }):Play()
	task.delay(RISE_SECONDS, function()
		body:Destroy()
		burst(folder, finish, color)
		Sounds.play("EvolveShine")
	end)
end

function Fireworks.play()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "FuegosArtificiales"
	folder.Parent = Workspace
	local center = root.Position
	task.spawn(function()
		for _ = 1, ROCKETS do
			rocket(folder, center)
			task.wait(GAP_SECONDS)
		end
		task.wait(RISE_SECONDS + CLEANUP_SECONDS)
		folder:Destroy()
	end)
end

return Fireworks
