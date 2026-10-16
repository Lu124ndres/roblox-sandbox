--!strict
--[[
	SpinStand

	La ruleta grande del mundo, junto a la aparición (como en los
	simuladores): base de piedra, dos postes y la rueda (SpinWheelView en una
	SurfaceGui) que gira despacio. El letrero "Ruleta [E]" (ProximityPrompt)
	abre la ventana (SpinWindow). Es de cada cliente: solo se ve y se toca.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local SpinWheelView = require(script.Parent.Parent.Menus.SpinWheelView)

local ANGLE, RADIUS = 250, 128 -- al costado del camino de la aparición
local SIZE = 16 -- diámetro de la rueda en studs
local IDLE_SPEED = 8 -- grados por segundo

local SpinStand = {}

local function part(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

function SpinStand.start(open: () -> ())
	local a = math.rad(ANGLE)
	local ground =
		Vector3.new(math.cos(a) * RADIUS, WorldLayout.plateauHeight, math.sin(a) * RADIUS)
	-- Mira hacia el centro de la isla (de frente a quien llega a la plaza).
	local base = CFrame.lookAt(ground, Vector3.new(0, ground.Y, 0))
	local model = Instance.new("Model")
	model.Name = "RuletaMundo"
	local stone = Color3.fromRGB(120, 128, 146)
	part(
		model,
		"Base",
		Vector3.new(SIZE + 4, 1.2, 7),
		base * CFrame.new(0, 0.6, 0),
		stone,
		Enum.Material.Slate
	)
	part(
		model,
		"Escalon",
		Vector3.new(SIZE, 0.8, 5),
		base * CFrame.new(0, 1.6, -1.4),
		stone:Lerp(Color3.new(1, 1, 1), 0.2),
		Enum.Material.Slate
	)
	for side = -1, 1, 2 do
		part(
			model,
			`Poste{side}`,
			Vector3.new(1.4, SIZE * 0.75, 1.4),
			base * CFrame.new(side * (SIZE / 2 - 1.5), 1.2 + SIZE * 0.375, 1.2),
			Color3.fromRGB(52, 60, 82),
			Enum.Material.Metal
		)
	end
	local center = base * CFrame.new(0, 2 + SIZE / 2, 0.4)
	local disc = part(
		model,
		"Rueda",
		Vector3.new(0.8, SIZE, SIZE),
		center * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(38, 44, 62),
		Enum.Material.SmoothPlastic
	)
	disc.Shape = Enum.PartType.Cylinder
	local face = part(
		model,
		"Cara",
		Vector3.new(SIZE, SIZE, 0.1),
		center * CFrame.new(0, 0, -0.5),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	face.Transparency = 1
	face.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Adornee = face
	gui.Parent = face
	local wheel = SpinWheelView.build(gui, 1.6)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Girar la ruleta"
	prompt.ObjectText = "Ruleta"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 22
	prompt.RequiresLineOfSight = false
	prompt.Parent = disc
	prompt.Triggered:Connect(open)
	model.Parent = Workspace
	RunService.Heartbeat:Connect(function(dt)
		if (Workspace.CurrentCamera.CFrame.Position - center.Position).Magnitude < 160 then
			wheel.rotor.Rotation = (wheel.rotor.Rotation + IDLE_SPEED * dt) % 360
		end
	end)
end

return SpinStand
