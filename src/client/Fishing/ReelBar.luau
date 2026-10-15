--!strict
--[[
	ReelBar

	La barra del minijuego de recoger (como Fish It), en el centro de la
	pantalla un poco abajo: una tarjeta oscura con la rareza del pez que picó
	(una etiqueta de su color), "¡Toca rápido!" y la barra con marcas cada
	25 %, la punta que brilla y una meta al final. Cada toque la empuja y
	destella; si se vacía mucho, el borde se pone rojo. Solo dibuja una
	predicción con los mismos números que usa el servidor (ReelFight); quien
	decide si se atrapó es el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Reel = require(ReplicatedStorage.Shared.Config.Reel)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Ui = require(script.Parent.Parent.Ui)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WIDTH, HEIGHT, BAR_HEIGHT = 380, 92, 26
local WHITE = Color3.new(1, 1, 1)
local CARD = Color3.fromRGB(16, 22, 34)
local EDGE = Color3.fromRGB(70, 90, 120)
local DANGER = Color3.fromRGB(255, 80, 70)

export type Params = { start: number, gain: number, drain: number, timeout: number }
export type Bar = {
	show: (params: Params, rarityId: string) -> (),
	tap: () -> (),
	hide: () -> (),
}

local ReelBar = {}

local function rarityName(rarityId: string): string
	for _, rarity in Config.Economy.rarities do
		if rarity.id == rarityId then
			return rarity.displayName
		end
	end
	return ""
end

local function frame(name: string, parent: Instance, color: Color3): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.BorderSizePixel = 0
	item.BackgroundColor3 = color
	item.Parent = parent
	return item
end

function ReelBar.mount(screen: ScreenGui): Bar
	local card = frame("Recoger", screen, CARD)
	card.BackgroundTransparency = 0.12
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.7)
	card.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	card.Visible = false
	Ui.corner(card, 16)
	Ui.stroke(card, EDGE, 2, 0.2)
	Layout.scaleWith(card)
	local appear = Instance.new("UIScale")
	appear.Parent = card

	-- Etiqueta de la rareza (de su color) y la ayuda a la derecha.
	local tag = frame("Rareza", card, WHITE)
	tag.Position = UDim2.fromOffset(14, 10)
	tag.Size = UDim2.fromOffset(150, 30)
	Ui.corner(tag, 10)
	Style.gradient(tag, WHITE)
	local tagText = Style.text(tag, "Texto", 22, WHITE, 2)
	tagText.Size = UDim2.new(1, -12, 1, -4)
	tagText.Position = UDim2.fromOffset(6, 2)
	local hint = Style.text(card, "Ayuda", 22, WHITE, 2)
	hint.AnchorPoint = Vector2.new(1, 0)
	hint.Position = UDim2.new(1, -14, 0, 12)
	hint.Size = UDim2.fromOffset(190, 26)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "¡Toca rápido!"

	-- Pista con marcas cada 25 %, relleno con brillo y la meta al final.
	local track = frame("Pista", card, Color3.fromRGB(8, 12, 20))
	track.Position = UDim2.new(0, 14, 0, 50)
	track.Size = UDim2.new(1, -56, 0, BAR_HEIGHT)
	track.ClipsDescendants = true
	Ui.corner(track, 9)
	local trackStroke = Instance.new("UIStroke")
	trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackStroke.Color = EDGE
	trackStroke.Thickness = 2
	trackStroke.Parent = track
	local fill = frame("Relleno", track, WHITE)
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 9)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 170, 170))
	shine.Parent = fill
	local tip = frame("Punta", fill, WHITE)
	tip.AnchorPoint = Vector2.new(1, 0)
	tip.Position = UDim2.fromScale(1, 0)
	tip.Size = UDim2.new(0, 5, 1, 0)
	tip.BackgroundTransparency = 0.2
	for k = 1, 3 do
		local mark = frame(`Marca{k}`, track, WHITE)
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromScale(k / 4, 0.5)
		mark.Size = UDim2.new(0, 2, 0.5, 0)
		mark.BackgroundTransparency = 0.75
		mark.ZIndex = 2
	end
	local goal = Icons.view(card, "fish")
	goal.Name = "Meta"
	goal.AnchorPoint = Vector2.new(0.5, 0.5)
	goal.Position = UDim2.new(1, -22, 0, 50 + BAR_HEIGHT / 2)
	goal.Size = UDim2.fromOffset(36, 36)
	local pop = Instance.new("UIScale")
	pop.Parent = track

	local params: Params? = nil
	local progress, shownAt = 0, 0

	RunService.RenderStepped:Connect(function(dt: number)
		local current = params
		if not current or not card.Visible then
			return
		end
		if os.clock() - shownAt > Reel.graceSeconds then
			progress = math.max(0, progress - current.drain * dt)
		end
		fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
		tip.Visible = progress > 0.02
		local danger = progress < 0.2
		local blink = 0.5 + 0.5 * math.sin(os.clock() * 14)
		trackStroke.Color = if danger then EDGE:Lerp(DANGER, blink) else EDGE
		hint.TextColor3 = if danger then UIConfig.Colors.Warning else WHITE
		hint.Text = if danger then "¡Se escapa! ¡Toca!" else "¡Toca rápido!"
	end)

	local function show(next: Params, rarityId: string)
		params = next
		progress, shownAt = next.start, os.clock()
		local color = UIConfig.RarityColors[rarityId] or UIConfig.Colors.Fishing
		tag.BackgroundColor3 = color
		tagText.Text = TextCase.upper(rarityName(rarityId))
		local tagStroke = tagText:FindFirstChildOfClass("UIStroke")
		if tagStroke then
			tagStroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.65)
		end
		fill.BackgroundColor3 = color
		card.Visible = true
		appear.Scale = 0.85
		TweenService:Create(appear, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
	end

	local function tap()
		local current = params
		if not current then
			return
		end
		progress = math.min(1, progress + current.gain)
		pop.Scale = 1.05
		TweenService:Create(pop, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
		tip.BackgroundTransparency = 0
		TweenService:Create(tip, TweenInfo.new(0.25), { BackgroundTransparency = 0.2 }):Play()
	end

	local function hide()
		params = nil
		card.Visible = false
	end

	return { show = show, tap = tap, hide = hide }
end

return ReelBar
