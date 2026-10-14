--!strict
--[[
	FishDexCard

	Una tarjeta de la colección (FishDex): el pez en 3D dentro de un
	ViewportFrame (o su silueta si falta descubrirlo), el nombre y la rareza
	con la cantidad pescada. El giro lo hace FishDex, solo con la ventana
	abierta, con el model que devuelve build.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Ui = require(script.Parent.Parent.Ui)

local COLORS = UIConfig.Colors
local SILHOUETTE = Color3.fromRGB(20, 26, 36)

export type Card = { box: Frame, model: Model?, info: TextLabel, known: boolean, order: number }

local FishDexCard = {}

function FishDexCard.infoText(fishId: string, amount: number): string
	local rarity = FishCatalog.rarity(fishId)
	return if amount > 0
		then `{rarity.displayName} · x{NumberFormat.short(amount)}`
		else rarity.displayName
end

function FishDexCard.build(parent: Instance, fishId: string, amount: number, order: number): Card
	local fish = FishCatalog.get(fishId)
	local rarity = FishCatalog.rarity(fishId)
	local known = amount > 0
	local color = if known then UIConfig.RarityColors[rarity.id] else COLORS.TextMuted
	local box = Instance.new("Frame")
	box.LayoutOrder = order
	box.BackgroundColor3 = COLORS.Track
	box.BackgroundTransparency = 0.2
	Ui.corner(box, 10)
	Ui.stroke(box, color, 2, if known then 0 else 0.6)
	box.Parent = parent

	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Size = UDim2.new(1, 0, 0.62, 0)
	view.Ambient = if known then Color3.fromRGB(200, 200, 210) else Color3.new(0, 0, 0)
	view.LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	view.Parent = box
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = FishModel.build(fishId, 1)
	if not known then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = SILHOUETTE
				part.Material = Enum.Material.SmoothPlastic
			elseif part:IsA("ParticleEmitter") or part:IsA("Light") then
				part:Destroy()
			end
		end
	end
	model.Parent = world
	local extent = model:GetExtentsSize().Magnitude
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(extent * 1.5, extent * 0.35, 0), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera

	local name = Ui.label("Nombre", box, UIConfig.Fonts.Title, UIConfig.TextSizes.Small)
	name.Text = if known and fish then fish.displayName else "???"
	name.Position = UDim2.fromScale(0.04, 0.62)
	name.Size = UDim2.fromScale(0.92, 0.18)
	local info = Ui.label("Info", box, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
	info.Text = FishDexCard.infoText(fishId, amount)
	info.TextColor3 = color
	info.Position = UDim2.fromScale(0.04, 0.8)
	info.Size = UDim2.fromScale(0.92, 0.16)
	return {
		box = box,
		model = if known then model else nil,
		info = info,
		known = known,
		order = order,
	}
end

return FishDexCard
