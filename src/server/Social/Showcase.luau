--!strict
--[[
	Showcase

	Vitrinas de los trajes de pase en el mapa, a los lados de la aparición:
	un pedestal de mármol y oro con el traje de malla en grande (lo animan
	los clientes: client/Trajes/Vitrinas), un cartel con nombre, precio y
	ventajas, y E para comprarlo. La compra la abre el cliente (Purchases);
	si ya tiene el pase, E aquí se lo pone o se lo quita (vuelve a Marinero,
	atributo TrajeElegido, que lee Outfits).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Proximity = require(script.Parent.Parent.Proximity)
local RateLimit = require(script.Parent.Parent.RateLimit)

local L = WorldLayout
local PASSES = Config.Monetization.passes
local DISPLAY_HEIGHT = 9 -- alto del traje en la vitrina (studs)
local BASE_RADIUS = 5.5
local BASE_HEIGHT = 2.4
local PROMPT_DISTANCE = 14
local MARBLE = Color3.fromRGB(236, 232, 224)
local GOLD = Color3.fromRGB(255, 200, 70)

local Showcase = {}

local limiter = RateLimit.new("Vitrina", 1, 2)

local function cylinder(
	name: string,
	radius: number,
	height: number,
	top: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, radius * 2, radius * 2)
	part.CFrame = CFrame.new(top - Vector3.new(0, height / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return part
end

local function label(parent: Instance, text: string, y: number, height: number, color: Color3)
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Position = UDim2.fromScale(0, y)
	line.Size = UDim2.fromScale(1, height)
	line.Font = Enum.Font.FredokaOne
	line.TextScaled = true
	line.TextWrapped = true
	line.Text = text
	line.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 24, 40)
	stroke.Parent = line
	line.Parent = parent
end

local function sign(parent: BasePart, passKey: string, height: number)
	local pass = PASSES[passKey]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromScale(11, 4.4)
	gui.StudsOffset = Vector3.new(0, height + 2.6, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	label(gui, string.upper(pass.name), 0, 0.36, GOLD)
	label(gui, `R$ {pass.robux}`, 0.36, 0.24, Color3.fromRGB(120, 255, 140))
	label(gui, pass.description, 0.62, 0.38, Color3.new(1, 1, 1))
	gui.Parent = parent
end

-- El traje en grande, parado sobre el pedestal y mirando hacia `look`.
local function display(outfit: string, top: Vector3, look: Vector3): Model?
	local template = ServerStorage:FindFirstChild(Trajes.templateName(outfit))
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	local mesh = Trajes.mesh(model)
	if not mesh then
		model:Destroy()
		return nil
	end
	local _, _, height = Trajes.measure(mesh)
	model:ScaleTo(model:GetScale() * DISPLAY_HEIGHT / height)
	local frame = Trajes.measure(mesh)
	local target = CFrame.lookAt(top, top + look)
	model:PivotTo(target * frame:ToObjectSpace(model:GetPivot()))
	model.WorldPivot = target -- gira sobre sus pies (client/Trajes/Vitrinas)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	model.Name = "Muestra"
	model:SetAttribute("Outfit", outfit)
	return model
end

local function onTriggered(player: Player, passKey: string, outfit: string)
	if not limiter(player) or not Perks.hasPass(player, passKey) then
		return -- sin el pase, el cliente abre la compra
	end
	local character = player.Character
	local current = character and character:FindFirstChild(Trajes.FOLDER)
	local wearing = current and current:GetAttribute("Outfit") == outfit
	player:SetAttribute(Trajes.CHOSEN, if wearing then Trajes.SAILOR else outfit)
end

local function build(folder: Folder, passKey: string, side: number)
	local outfit = PASSES[passKey].outfit :: string
	local angle = math.rad(L.spawnAngle)
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local tangent = Vector3.new(-out.Z, 0, out.X)
	local spawn = out * L.spawnRadius
	local ground = out * L.showcaseRadius
		+ tangent * L.showcaseSide * side
		+ Vector3.new(0, L.plateauHeight, 0)
	local model = Instance.new("Model")
	model.Name = passKey
	model:SetAttribute("Pase", passKey)
	model:SetAttribute("Outfit", outfit)
	local base = cylinder(
		"Pedestal",
		BASE_RADIUS,
		BASE_HEIGHT,
		ground + Vector3.new(0, BASE_HEIGHT, 0),
		MARBLE,
		Enum.Material.Marble
	)
	base.Parent = model
	local rim = cylinder(
		"Borde",
		BASE_RADIUS + 0.3,
		0.5,
		ground + Vector3.new(0, BASE_HEIGHT + 0.1, 0),
		GOLD,
		Enum.Material.Metal
	)
	rim.Parent = model
	local step = cylinder(
		"Escalon",
		BASE_RADIUS + 1.6,
		0.6,
		ground + Vector3.new(0, 0.6, 0),
		MARBLE,
		Enum.Material.Marble
	)
	step.Parent = model
	local top = ground + Vector3.new(0, BASE_HEIGHT + 0.35, 0)
	-- Mira a un punto entre la aparición y el arco: se ve de tres cuartos al aparecer.
	local facing = spawn - out * 14
	local look = Vector3.new(facing.X - ground.X, 0, facing.Z - ground.Z).Unit
	local shown = display(outfit, top, look)
	if shown then
		shown.Parent = model
	end
	sign(base, passKey, DISPLAY_HEIGHT + BASE_HEIGHT / 2)
	local prompt = Proximity.makePrompt(base, "Comprar", PASSES[passKey].name, PROMPT_DISTANCE)
	prompt.Name = "Comprar"
	prompt.Triggered:Connect(function(player: Player)
		onTriggered(player, passKey, outfit)
	end)
	model.Parent = folder
end

function Showcase.init()
	local folder = Instance.new("Folder")
	folder.Name = "Vitrinas"
	local side = -1
	for _, passKey in Config.Monetization.passOrder do
		if PASSES[passKey].outfit then
			build(folder, passKey, side)
			side = -side
		end
	end
	folder.Parent = Workspace
end

return table.freeze(Showcase)
