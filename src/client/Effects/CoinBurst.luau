--!strict
--[[
	CoinBurst

	Monedas que saltan del centro de la pantalla y vuelan al contador de
	monedas del HUD al cobrar por alimentar. Cuantas más monedas, más
	moneditas (hasta MAX_COINS). Cada una que llega hace "tin" (subiendo de
	tono) y el contador rebota.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

local MIN_COINS, MAX_COINS = 4, 16
local COIN_SIZE = 30
local GOLD = UIConfig.Colors.Coins
local GOLD_DARK = Color3.fromRGB(200, 140, 30)

local CoinBurst = {}

local rng = Random.new()

local function coin(screen: ScreenGui): Frame
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

function CoinBurst.burst(screen: ScreenGui, target: GuiObject, amount: number, onArrive: () -> ())
	local count = math.clamp(math.floor(math.sqrt(amount) * 2), MIN_COINS, MAX_COINS)
	local origin = screen.AbsoluteSize * Vector2.new(0.5, 0.62)
	local goal = target.AbsolutePosition
		+ target.AbsoluteSize * Vector2.new(0.15, 0.5)
		- screen.AbsolutePosition
	for index = 1, count do
		local frame = coin(screen)
		frame.Position = UDim2.fromOffset(origin.X, origin.Y)
		local scale = Instance.new("UIScale")
		scale.Scale = 0.2
		scale.Parent = frame
		local spread = Vector2.new(rng:NextNumber(-140, 140), rng:NextNumber(-110, 40))
		local burst = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(
			frame,
			burst,
			{ Position = UDim2.fromOffset(origin.X + spread.X, origin.Y + spread.Y) }
		):Play()
		TweenService:Create(scale, burst, { Scale = 1 }):Play()
		task.delay(0.3 + index * 0.04, function()
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
			if index % 3 == 1 or index == count then
				Sounds.play("CoinPop", nil, 1 + index * 0.03)
			end
			onArrive()
		end)
	end
end

return CoinBurst
