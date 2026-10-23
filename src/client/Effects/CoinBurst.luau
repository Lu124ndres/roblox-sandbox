--!strict
--[[
	CoinBurst

	Monedas que vuelan al contador de monedas del HUD al cobrar por alimentar.
	drip: una moneda por pez que llega a la boca (sale de ahí); seguidas, el
	"tin" sube de tono. burst: una ráfaga desde el centro de la pantalla,
	cuantas más monedas más moneditas (hasta MAX_COINS). Cada moneda es el
	ícono v4 de la moneda (Interface/Icons); sin la hoja, un círculo dorado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Icons = require(script.Parent.Parent.Interface.Icons)

local MIN_COINS, MAX_COINS = 4, 16
local DRIP_GAP = 0.06 -- a lo sumo una moneda suelta cada tanto (chorro de peces rápido)
local STREAK_RESET = 0.8 -- sin monedas este rato, el tono vuelve a empezar
local COIN_SIZE = 30
local ICON_SIZE = 40 -- el ícono pintado trae margen transparente
local GOLD = UIConfig.Colors.Coins
local GOLD_DARK = Color3.fromRGB(200, 140, 30)

local CoinBurst = {}

local rng = Random.new()
local lastDrip = 0
local streak = 0

local function coin(screen: ScreenGui): GuiObject
	local icon = Instance.new("ImageLabel")
	if Icons.paint(icon, "coin") then
		icon.Name = "Moneda"
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 20
		icon.Parent = screen
		return icon
	end
	icon:Destroy()
	local frame = Instance.new("Frame")
	frame.Name = "Moneda"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(COIN_SIZE, COIN_SIZE)
	frame.BackgroundColor3 = GOLD
	frame.ZIndex = 20
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD_DARK
	stroke.Thickness = 3
	stroke.Parent = frame
	local shine = Instance.new("Frame")
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.38, 0.35)
	shine.Size = UDim2.fromScale(0.3, 0.3)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.25
	shine.ZIndex = 21
	local shineCorner = corner:Clone()
	shineCorner.Parent = shine
	shine.Parent = frame
	frame.Parent = screen
	return frame
end

local function goalOf(screen: ScreenGui, target: GuiObject): Vector2
	return target.AbsolutePosition
		+ target.AbsoluteSize * Vector2.new(0.15, 0.5)
		- screen.AbsolutePosition
end

-- La moneda salta de origin a origin + spread y, tras delay, vuela al contador.
local function launch(
	screen: ScreenGui,
	target: GuiObject,
	origin: Vector2,
	spread: Vector2,
	delay: number,
	onArrive: () -> ()
)
	local frame = coin(screen)
	frame.Position = UDim2.fromOffset(origin.X, origin.Y)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = frame
	local burst = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService
		:Create(
			frame,
			burst,
			{ Position = UDim2.fromOffset(origin.X + spread.X, origin.Y + spread.Y) }
		)
		:Play()
	TweenService:Create(scale, burst, { Scale = 1 }):Play()
	task.delay(delay, function()
		local goal = goalOf(screen, target) -- el HUD puede moverse mientras salta
		local fly = TweenInfo.new(
			UIConfig.Effects.CoinFlySeconds,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
		local move =
			TweenService:Create(frame, fly, { Position = UDim2.fromOffset(goal.X, goal.Y) })
		TweenService:Create(scale, fly, { Scale = 0.55 }):Play()
		move:Play()
		move.Completed:Wait()
		frame:Destroy()
		onArrive()
	end)
end

-- Una moneda desde origin (en píxeles de la pantalla). Las que llegan muy
-- seguidas se saltean para no tapar la vista.
function CoinBurst.drip(screen: ScreenGui, target: GuiObject, origin: Vector2)
	local now = os.clock()
	if now - lastDrip < DRIP_GAP then
		return
	end
	streak = if now - lastDrip > STREAK_RESET then 1 else streak + 1
	lastDrip = now
	local pitch = 1 + math.min(streak, 20) * 0.025
	local playSound = streak % 2 == 1
	local spread = Vector2.new(rng:NextNumber(-40, 40), rng:NextNumber(-60, -20))
	launch(screen, target, origin, spread, 0.3, function()
		if playSound then
			Sounds.play("CoinPop", nil, pitch)
		end
	end)
end

function CoinBurst.burst(screen: ScreenGui, target: GuiObject, amount: number, onArrive: () -> ())
	local count = math.clamp(math.floor(math.sqrt(amount) * 2), MIN_COINS, MAX_COINS)
	local origin = screen.AbsoluteSize * Vector2.new(0.5, 0.62)
	for index = 1, count do
		local spread = Vector2.new(rng:NextNumber(-140, 140), rng:NextNumber(-110, 40))
		launch(screen, target, origin, spread, 0.3 + index * 0.04, function()
			if index % 3 == 1 or index == count then
				Sounds.play("CoinPop", nil, 1 + index * 0.03)
			end
			onArrive()
		end)
	end
end

return CoinBurst
