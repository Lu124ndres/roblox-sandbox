--!strict
--[[
	FishDex

	Colección de peces: las 12 especies en una cuadrícula. Las descubiertas
	se ven en 3D girando, con su rareza y cuántas se han pescado; las que
	faltan, como una silueta oscura con "???". Arriba, el avance (7/12) y el
	premio por completarla. El botón Peces del HUD se marca cuando hay un
	pez nuevo sin mirar. Los datos vienen de los atributos Pez_<id>.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Ui = require(script.Parent.Parent.Ui)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local COLORS = UIConfig.Colors
local FISH = Config.Economy.fish
local PREFIX = Protocol.PlayerAttributes.FishPrefix
local SILHOUETTE = Color3.fromRGB(20, 26, 36)

local FishDex = {}

local function caught(player: Player, fishId: string): number
	local value = player:GetAttribute(`{PREFIX}{fishId}`)
	return if type(value) == "number" then value else 0
end

local function card(parent: Instance, fishId: string, amount: number, order: number)
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
	if known then
		local spin = RunService.RenderStepped:Connect(function()
			model:PivotTo(CFrame.Angles(0, os.clock() * 1.2 + order, 0))
		end)
		box.Destroying:Once(function()
			spin:Disconnect()
		end)
	end

	local name = Ui.label("Nombre", box, UIConfig.Fonts.Title, UIConfig.TextSizes.Small)
	name.Text = if known and fish then fish.displayName else "???"
	name.Position = UDim2.fromScale(0.04, 0.62)
	name.Size = UDim2.fromScale(0.92, 0.18)
	local info = Ui.label("Info", box, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
	info.Text = if known
		then `{rarity.displayName} · x{NumberFormat.short(amount)}`
		else rarity.displayName
	info.TextColor3 = color
	info.Position = UDim2.fromScale(0.04, 0.8)
	info.Size = UDim2.fromScale(0.92, 0.16)
end

-- Punto rojo en el botón Peces cuando aparece una especie nueva sin mirar.
local function watchSpecies(
	player: Player,
	hud: HudButtons.HudButton,
	window: Window.Window,
	render: () -> ()
)
	for _, fish in FISH do
		local before = caught(player, fish.id)
		player:GetAttributeChangedSignal(`{PREFIX}{fish.id}`):Connect(function()
			local now = caught(player, fish.id)
			if before == 0 and now > 0 then
				hud.setAlert(true) -- especie nueva sin mirar
			end
			before = now
			if window.isOpen() then
				render()
			end
		end)
	end
end

function FishDex.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "Coleccion", "Colección de peces", Vector2.new(620, 460))
	local hud = HudButtons.top("Peces", "fish", window.toggle)

	local summary = Ui.label("Avance", window.content, UIConfig.Fonts.Body, UIConfig.TextSizes.Body)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.Size = UDim2.new(1, 0, 0, 26)
	local grid = Instance.new("ScrollingFrame")
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromOffset(0, 32)
	grid.Size = UDim2.new(1, 0, 1, -32)
	grid.ScrollBarThickness = 6
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(132, 150)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local function render()
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local found = 0
		for index, fish in FISH do
			local amount = caught(player, fish.id)
			found += if amount > 0 then 1 else 0
			card(grid, fish.id, amount, index)
		end
		summary.Text =
			`Descubiertos {found}/{#FISH} · completa la colección: +{NumberFormat.short(
				Config.Retention.collectionBonus
			)} monedas`
	end
	window.onOpen(function()
		hud.setAlert(false)
		render()
	end)
	-- Las alertas empiezan cuando los datos ya cargaron (si no, todo parecería
	-- nuevo). En otro hilo: el resto del cliente no espera a los datos.
	task.spawn(function()
		while player:GetAttribute(Protocol.PlayerAttributes.DataLoaded) ~= true do
			player:GetAttributeChangedSignal(Protocol.PlayerAttributes.DataLoaded):Wait()
		end
		watchSpecies(player, hud, window, render)
	end)
end

return FishDex
