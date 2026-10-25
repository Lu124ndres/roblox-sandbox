--!strict
--[[
	CatchCard

	Tarjeta de la captura del jugador local (a la izquierda bajo el menú; en
	táctil, abajo al centro), de piedra volcánica (Interface/Kit): el pez en
	3D girando (ViewportFrame) en un hueco de la piedra, su rareza en una placa
	de su color, el nombre dorado y una fila con el ícono del pez (Canva) y
	cuántos sacó y la carne con la comida que aporta. Entra con un rebote,
	queda CatchCardSeconds y se va. Una captura nueva reemplaza a la anterior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Device = require(script.Parent.Parent.Interface.Device)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local WIDTH, HEIGHT = 320, 112

local CatchCard = {}

export type Card = { show: (fishId: string, count: number) -> () }

function CatchCard.mount(screen: ScreenGui): Card
	local card = Instance.new("Frame")
	card.Name = "Captura"
	card.Parent = screen
	-- PC: a la izquierda, debajo de la columna del menú (no tapa ¡TIRA! ni Pescar).
	-- Táctil: abajo al centro (a la izquierda está el joystick).
	-- Se calcula al mostrarla (la columna cambia con la misión y la pantalla).
	local function places(): (UDim2, UDim2)
		local margin = UIConfig.Spacing.Margin
		if Device.touch() then
			card.AnchorPoint = Vector2.new(0.5, 1)
			return UDim2.new(0.5, 0, 1, -margin), UDim2.new(0.5, 0, 1, 200)
		end
		card.AnchorPoint = Vector2.zero
		local top = Layout.menuBottom() + margin
		return UDim2.fromOffset(margin, top), UDim2.fromOffset(-WIDTH - 40, top)
	end
	local shown, hidden = places()
	card.Position = hidden
	Layout.scaleWith(card)
	card.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	card.Visible = false
	local skin = Kit.skin(card, "panel")
	skin.SliceScale = 0.32
	Kit.gems(card, 26)

	-- El pez gira dentro de un hueco tallado en la piedra.
	local slot = Instance.new("Frame")
	slot.Name = "Hueco"
	slot.Position = UDim2.fromOffset(12, 12)
	slot.Size = UDim2.fromOffset(88, 88)
	slot.Parent = card
	Kit.skin(slot, "hondo").SliceScale = 0.3
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(4, 4)
	view.Size = UDim2.new(1, -8, 1, -8)
	view.Parent = slot
	local world = Instance.new("WorldModel")
	world.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = view
	view.CurrentCamera = camera

	local left = 110
	-- Placa de piedra del color de la rareza.
	local tag = Instance.new("Frame")
	tag.Name = "Rareza"
	tag.Position = UDim2.fromOffset(left, 10)
	tag.Size = UDim2.fromOffset(124, 26)
	tag.Parent = card
	local tagSkin = Kit.skin(tag, "boton")
	tagSkin.SliceScale = 0.22
	local rarityLabel = Style.text(tag, "Texto", 18, nil, 1.5)
	rarityLabel.Position = UDim2.fromOffset(6, 3)
	rarityLabel.Size = UDim2.new(1, -12, 1, -6)
	local nameLabel = Style.text(card, "Nombre", 28, nil, 2.5)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.fromOffset(left, 38)
	nameLabel.Size = UDim2.new(1, -left - 12, 0, 30)
	Kit.gold(nameLabel)

	-- Fila de abajo: ícono del pez con cuántos sacó y carne con la comida.
	local function stat(name: string, icon: string, x: number, width: number): TextLabel
		local box = Instance.new("Frame")
		box.Name = name
		box.BackgroundTransparency = 1
		box.Position = UDim2.fromOffset(x, 72)
		box.Size = UDim2.fromOffset(width, 30)
		box.Parent = card
		local image = Icons.view(box, icon)
		image.Size = UDim2.fromOffset(30, 30)
		local label = Style.text(box, "Texto", 22, nil, 2)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(34, 2)
		label.Size = UDim2.new(1, -34, 1, -4)
		return label
	end
	local countLabel = stat("Cantidad", "fish", left, 70)
	local foodLabel = stat("Comida", "meat", left + 74, WIDTH - left - 86)
	foodLabel.TextColor3 = COLORS.Feeding

	local current: Model? = nil
	local spin: RBXScriptConnection? = nil
	local token = 0

	local function show(fishId: string, count: number)
		token += 1
		local mine = token
		local fish = FishCatalog.get(fishId)
		local rarity = FishCatalog.rarity(fishId)
		local color = UIConfig.RarityColors[rarity.id] or COLORS.Text
		if current then
			current:Destroy()
		end
		if spin then
			spin:Disconnect()
		end
		local model = FishModel.build(fishId, 1)
		model.Parent = world
		current = model
		local extent = model:GetExtentsSize().Magnitude
		camera.CFrame = CFrame.lookAt(Vector3.new(extent * 1.6, extent * 0.5, 0), Vector3.zero)
		spin = RunService.RenderStepped:Connect(function()
			model:PivotTo(CFrame.Angles(0, os.clock() * 1.6, math.sin(os.clock() * 5) * 0.12))
		end)

		rarityLabel.Text = rarity.displayName
		Kit.tint(tagSkin, color)
		nameLabel.Text = if fish then fish.displayName else fishId
		countLabel.Text = `x{count}`
		foodLabel.Text = if fish then `+{fish.food * count} comida` else ""

		shown, hidden = places()
		card.Visible = true
		card.Position = hidden
		TweenService:Create(card, UIConfig.Tweens.Pop, { Position = shown }):Play()
		task.delay(UIConfig.Effects.CatchCardSeconds, function()
			if token ~= mine then
				return
			end
			local out = TweenService:Create(card, UIConfig.Tweens.Fade, { Position = hidden })
			out:Play()
			out.Completed:Wait()
			if token == mine then
				card.Visible = false
			end
		end)
	end

	return { show = show }
end

return CatchCard
