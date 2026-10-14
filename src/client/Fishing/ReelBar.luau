--!strict
--[[
	ReelBar

	La barra del minijuego de recoger (como Fish It), en el centro de la
	pantalla un poco abajo: la rareza del pez que picó arriba ("¡ÉPICO!" en
	su color), la barra que sube con cada toque y baja sola, y "¡Toca rápido!".
	Solo dibuja una predicción con los mismos números que usa el servidor
	(ReelFight); quien decide si se atrapó es el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Reel = require(ReplicatedStorage.Shared.Config.Reel)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WIDTH, BAR_HEIGHT = 340, 28

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

function ReelBar.mount(screen: ScreenGui): Bar
	local frame = Instance.new("Frame")
	frame.Name = "Recoger"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.7)
	frame.Size = UDim2.fromOffset(WIDTH, 84)
	frame.Visible = false
	frame.Parent = screen
	Layout.scaleWith(frame)

	local title = Style.text(frame, "Rareza", 30, nil, 3)
	title.Size = UDim2.new(1, 0, 0, 30)
	local track = Instance.new("Frame")
	track.Name = "Pista"
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	track.Position = UDim2.fromOffset(0, 32)
	track.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
	Ui.corner(track, 12)
	Style.border(track, 3)
	track.ClipsDescendants = true
	track.Parent = frame
	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 12)
	Style.gradient(fill, Color3.new(1, 1, 1))
	fill.Parent = track
	local hint = Style.text(frame, "Ayuda", 20, nil, 2)
	hint.Position = UDim2.fromOffset(0, 34 + BAR_HEIGHT)
	hint.Size = UDim2.new(1, 0, 0, 20)
	hint.Text = "¡Toca rápido!"
	local pop = Instance.new("UIScale")
	pop.Parent = track

	local params: Params? = nil
	local progress, shownAt = 0, 0

	RunService.RenderStepped:Connect(function(dt: number)
		local current = params
		if not current or not frame.Visible then
			return
		end
		if os.clock() - shownAt > Reel.graceSeconds then
			progress = math.max(0, progress - current.drain * dt)
		end
		fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
		local danger = progress < 0.2
		hint.TextColor3 = if danger then UIConfig.Colors.Warning else UIConfig.Colors.Text
	end)

	local function show(next: Params, rarityId: string)
		params = next
		progress, shownAt = next.start, os.clock()
		local color = UIConfig.RarityColors[rarityId] or UIConfig.Colors.Fishing
		title.Text = `¡{string.upper(rarityName(rarityId))}!`
		title.TextColor3 = color
		fill.BackgroundColor3 = color
		frame.Visible = true
	end

	local function tap()
		local current = params
		if not current then
			return
		end
		progress = math.min(1, progress + current.gain)
		pop.Scale = 1.06
		TweenService:Create(pop, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
	end

	local function hide()
		params = nil
		frame.Visible = false
	end

	return { show = show, tap = tap, hide = hide }
end

return ReelBar
