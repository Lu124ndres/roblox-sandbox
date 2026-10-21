--!strict
--[[
	CatchCard

	Tarjeta de la captura del jugador local (a la izquierda bajo el menú; en
	táctil, abajo al centro): el pez en 3D
	girando (ViewportFrame), su rareza con su color, el nombre con "xN" y la
	comida que aporta. Entra con un rebote, queda CatchCardSeconds y se va.
	Una captura nueva reemplaza a la anterior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Ui = require(script.Parent.Parent.Ui)
local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)

local COLORS = UIConfig.Colors

local CatchCard = {}

export type Card = { show: (fishId: string, count: number) -> () }

function CatchCard.mount(screen: ScreenGui): Card
	local card = Ui.panel("Captura", screen)
	-- PC: a la izquierda, debajo de la columna de estadísticas (no tapa ¡TIRA! ni Pescar).
	-- Táctil: abajo al centro, encima de «Siguiente meta» (a la izquierda está el joystick).
	-- Se calcula al mostrarla (la columna cambia con la misión y la pantalla).
	local function places(): (UDim2, UDim2)
		local margin = UIConfig.Spacing.Margin
		if Device.touch() then
			card.AnchorPoint = Vector2.new(0.5, 1)
			local bottom = screen.AbsoluteSize.Y
			local goal = screen:FindFirstChild("SiguienteMeta")
			if goal and goal:IsA("GuiObject") and goal.Visible then
				bottom = goal.AbsolutePosition.Y - screen.AbsolutePosition.Y
			end
			local up = screen.AbsoluteSize.Y - bottom + margin
			return UDim2.new(0.5, 0, 1, -up), UDim2.new(0.5, 0, 1, 200)
		end
		card.AnchorPoint = Vector2.zero
		local top = Layout.leftBottom() + margin
		return UDim2.fromOffset(margin, top), UDim2.fromOffset(-340, top)
	end
	local shown, hidden = places()
	card.Position = hidden
	Layout.scaleWith(card)
	card.Size = UDim2.fromOffset(300, 96)
	card.Visible = false
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Thickness = 3
	stroke.Transparency = 0

	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(6, 6)
	view.Size = UDim2.fromOffset(84, 84)
	view.Parent = card
	local world = Instance.new("WorldModel")
	world.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = view
	view.CurrentCamera = camera

	local function line(
		name: string,
		y: number,
		height: number,
		font: Font,
		size: number
	): TextLabel
		local label = Ui.label(name, card, font, size)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(98, y)
		label.Size = UDim2.new(1, -106, 0, height)
		return label
	end
	local rarityLabel = line("Rareza", 8, 24, UIConfig.Fonts.Title, UIConfig.TextSizes.Body)
	local nameLabel = line("Nombre", 34, 30, UIConfig.Fonts.Title, UIConfig.TextSizes.Title)
	local foodLabel = line("Comida", 66, 22, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
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
		rarityLabel.TextColor3 = color
		stroke.Color = color
		nameLabel.Text = if fish
			then (if count > 1 then `{fish.displayName} x{count}` else fish.displayName)
			else fishId
		foodLabel.Text = if fish then `+{fish.food * count} comida para el gigante` else ""

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
