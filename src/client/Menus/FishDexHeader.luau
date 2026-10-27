--!strict
--[[
	FishDexHeader

	Cabecera de la sección elegida en el Índice de peces (FishDex), sobre la
	cuadrícula: el medallón grande de la sección, su nombre dorado, la barra
	de especies descubiertas y lo que gana:
		Todos      el siguiente premio de monedas de la colección (shared/Collection)
		           y la suerte que ya le dan las secciones completas
		una rareza la suerte por completarla (shared/CollectionLuck), o
		           "¡Completa!" si ya la tiene
	Solo muestra: el premio y la suerte los da el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Collection = require(ReplicatedStorage.Shared.Collection)
local CollectionLuck = require(ReplicatedStorage.Shared.CollectionLuck)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local FishDexTabs = require(script.Parent.FishDexTabs)
local LuckWindow = require(script.Parent.LuckWindow)

local HEIGHT = 96
local ODDS_WIDTH = 190
local COLORS = UIConfig.Colors

export type Header = {
	height: number,
	set: (id: string, found: number, total: number) -> (),
}

local FishDexHeader = {}

local function percent(value: number): string
	return `{math.round(value * 100)}%`
end

function FishDexHeader.mount(parent: Instance, left: number): Header
	local player = Players.LocalPlayer
	local frame = Instance.new("Frame")
	frame.Name = "Cabecera"
	frame.Position = UDim2.fromOffset(left, 0)
	frame.Size = UDim2.new(1, -left, 0, HEIGHT)
	frame.Parent = parent
	Kit.skin(frame, "hondo").SliceScale = 0.4

	local medal = Instance.new("ImageLabel")
	medal.Name = "Medallon"
	medal.BackgroundTransparency = 1
	medal.ScaleType = Enum.ScaleType.Fit
	medal.AnchorPoint = Vector2.new(0, 0.5)
	medal.Position = UDim2.new(0, 10, 0.5, 0)
	medal.Size = UDim2.fromOffset(74, 74)
	medal.ZIndex = 2
	medal.Parent = frame

	local title = Style.text(frame, "Titulo", 30, nil, 2.5)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(94, 8)
	title.Size = UDim2.new(0.5, -94, 0, 32)
	Kit.gold(title)
	local reward, rewardText = CardParts.iconText(frame, "chest", 22, COLORS.Coins)
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.new(1, -12, 0, 10)
	reward.Size = UDim2.new(0.5, -12, 0, 30)
	rewardText.TextXAlignment = Enum.TextXAlignment.Right
	local rewardIcon = reward:FindFirstChildWhichIsA("ImageLabel")
	local bar = CardParts.bar(frame, Style.PALETTE.Cards.Green, 20)
	bar.track.Position = UDim2.fromOffset(94, 50)
	bar.track.Size = UDim2.new(1, -106 - ODDS_WIDTH - 8, 0, 34)
	-- Abre la tabla de probabilidades de la suerte (política de Roblox).
	local odds = Style.button(frame, "Probabilidades", Style.PALETTE.Cards.Blue, "% PROBABILIDADES")
	odds.AnchorPoint = Vector2.new(1, 0)
	odds.Position = UDim2.new(1, -12, 0, 50)
	odds.Size = UDim2.fromOffset(ODDS_WIDTH, 34)
	odds.Activated:Connect(function()
		LuckWindow.open()
	end)

	local function set(id: string, found: number, total: number)
		if not Icons.paint(medal, FishDexTabs.icon(id)) then
			medal.Image = ""
		end
		local all = id == FishDexTabs.ALL
		local rarity = if all then nil else FishCatalog.rarityById(id)
		title.Text = if rarity then TextCase.upper(rarity.displayName) else "TODOS LOS PECES"
		local color = if rarity then UIConfig.RarityColors[id] else nil
		bar.set(
			if total > 0 then found / total else 0,
			`Descubiertos {found} / {total}`,
			color or Style.PALETTE.Cards.Green
		)
		local icon: string
		if all then
			local nextStep = Collection.nextMilestone(found)
			icon = "chest"
			rewardText.TextColor3 = COLORS.Coins
			rewardText.Text = if nextStep
				then `+{NumberFormat.short(
					Collection.reward(player, nextStep) * Perks.coinMultiplier(player)
				)} con {nextStep} · suerte +{percent(CollectionLuck.bonus(player))}`
				else `¡Completa! · suerte +{percent(CollectionLuck.bonus(player))}`
		else
			local complete = total > 0 and found >= total
			icon = "luck"
			rewardText.TextColor3 = if complete then COLORS.Success else COLORS.Text
			rewardText.Text = if complete
				then `¡Completa! +{percent(CollectionLuck.value(id))} suerte`
				else `Complétala: +{percent(CollectionLuck.value(id))} suerte`
		end
		if rewardIcon then
			Icons.paint(rewardIcon, icon)
		end
	end
	return { height = HEIGHT, set = set }
end

return FishDexHeader
