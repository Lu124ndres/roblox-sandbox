--!strict
--[[
	ReelBar

	La barra del minijuego de recoger (como Fish It), en el centro de la
	pantalla un poco abajo, de piedra volcánica como el resto de la interfaz
	(Interface/Kit): una placa con gemas, la rareza del pez que picó en una
	placa de su color, "¡Toca rápido!" dorado y la barra hundida en la piedra
	(HungerLook.hollow) con marcas cada 25 %, la punta que brilla y la meta
	al final. Cada toque la empuja y destella; si se vacía mucho, el canto
	del hueco late en rojo. Solo dibuja una predicción con los mismos números
	que usa el servidor (ReelFight); quien decide si se atrapó es el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Reel = require(ReplicatedStorage.Shared.Config.Reel)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Ui = require(script.Parent.Parent.Ui)
local HungerLook = require(script.Parent.Parent.Interface.HungerLook)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WIDTH, HEIGHT, BAR_HEIGHT = 390, 100, 30
local PLATE_SLICE = 0.32 -- canto de la placa a este tamaño
local WHITE = Color3.new(1, 1, 1)
local EDGE = Color3.fromRGB(255, 200, 80) -- filo dorado del hueco
local DANGER = Color3.fromRGB(255, 80, 70)

export type Params = { start: number, gain: number, drain: number, timeout: number }
export type Bar = {
	show: (params: Params, rarityId: string) -> (),
	tap: () -> number, -- devuelve cuánto lleva la barra (0..1)
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
	local card = frame("Recoger", screen, WHITE)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.7)
	card.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	card.Visible = false
	Kit.skin(card, "panel").SliceScale = PLATE_SLICE
	Kit.gems(card, 30)
	Layout.scaleWith(card)
	local appear = Instance.new("UIScale")
	appear.Parent = card

	-- Placa de piedra de la rareza (de su color) y la ayuda dorada a la derecha.
	local tag = frame("Rareza", card, WHITE)
	tag.Position = UDim2.fromOffset(18, 12)
	tag.Size = UDim2.fromOffset(156, 34)
	local tagSkin = Kit.skin(tag, "boton")
	tagSkin.SliceScale = 0.26
	local tagText = Style.text(tag, "Texto", 22, WHITE, 2)
	tagText.Size = UDim2.new(1, -14, 1, -8)
	tagText.Position = UDim2.fromOffset(7, 4)
	local hint = Style.text(card, "Ayuda", 24, WHITE, 2)
	hint.AnchorPoint = Vector2.new(1, 0)
	hint.Position = UDim2.new(1, -18, 0, 14)
	hint.Size = UDim2.fromOffset(190, 28)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "¡Toca rápido!"
	Kit.gold(hint)
	local hintGold = hint:FindFirstChildOfClass("UIGradient") :: UIGradient

	-- Hueco tallado en la piedra con marcas cada 25 %, relleno con brillo y la meta al final.
	local track = frame("Pista", card, WHITE)
	track.Position = UDim2.fromOffset(18, 54)
	track.Size = UDim2.new(1, -72, 0, BAR_HEIGHT)
	local groove = HungerLook.hollow(track)
	local trackStroke = Instance.new("UIStroke")
	trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackStroke.Color = EDGE
	trackStroke.Thickness = 2
	trackStroke.Transparency = 0.4
	trackStroke.Parent = groove
	local fill = frame("Relleno", groove, WHITE)
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 6)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(WHITE, Color3.fromRGB(150, 150, 150))
	shine.Parent = fill
	HungerLook.shine(fill)
	local tip = frame("Punta", fill, WHITE)
	tip.AnchorPoint = Vector2.new(1, 0)
	tip.Position = UDim2.fromScale(1, 0)
	tip.Size = UDim2.new(0, 5, 1, 0)
	tip.BackgroundTransparency = 0.2
	for k = 1, 3 do
		local mark = frame(`Marca{k}`, groove, Color3.fromRGB(255, 220, 140))
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromScale(k / 4, 0.5)
		mark.Size = UDim2.new(0, 2, 0.6, 0)
		mark.BackgroundTransparency = 0.6
		mark.ZIndex = 2
	end
	local goal = Icons.view(card, "fish")
	goal.Name = "Meta"
	goal.AnchorPoint = Vector2.new(0.5, 0.5)
	goal.Position = UDim2.new(1, -30, 0, 54 + BAR_HEIGHT / 2)
	goal.Size = UDim2.fromOffset(44, 44)
	goal.ZIndex = 3
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
		trackStroke.Transparency = if danger then 0 else 0.4
		hintGold.Enabled = not danger
		hint.TextColor3 = if danger then UIConfig.Colors.Warning else WHITE
		hint.Text = if danger then "¡Se escapa! ¡Toca!" else "¡Toca rápido!"
	end)

	local function show(next: Params, rarityId: string)
		params = next
		progress, shownAt = next.start, os.clock()
		local color = UIConfig.RarityColors[rarityId] or UIConfig.Colors.Fishing
		Kit.tint(tagSkin, color)
		tagText.Text = TextCase.upper(rarityName(rarityId))
		local tagStroke = tagText:FindFirstChildOfClass("UIStroke")
		if tagStroke then
			tagStroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.65)
		end
		fill.BackgroundColor3 = color:Lerp(WHITE, 0.15)
		card.Visible = true
		appear.Scale = 0.85
		TweenService:Create(appear, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
	end

	local function tap(): number
		local current = params
		if not current then
			return progress
		end
		progress = math.min(1, progress + current.gain)
		pop.Scale = 1.05
		TweenService:Create(pop, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
		tip.BackgroundTransparency = 0
		TweenService:Create(tip, TweenInfo.new(0.25), { BackgroundTransparency = 0.2 }):Play()
		return progress
	end

	local function hide()
		params = nil
		card.Visible = false
	end

	return { show = show, tap = tap, hide = hide }
end

return ReelBar
