--!strict
--[[
	FishDex

	Colección de peces: todas las especies (36) en una cuadrícula ordenada por
	rareza, con pestañas por categoría (FishDexTabs); en táctil, ancha. Las
	descubiertas giran en 3D con su rareza y cuántas se han pescado; las que
	faltan son una silueta con "???". Arriba, el avance (7/36) y el siguiente
	premio (shared/Collection). El botón Peces del HUD se marca cuando hay un
	pez nuevo sin mirar. Los datos vienen de los atributos Pez_<id>.

	Los peces solo giran con la ventana abierta (un único RenderStepped), y
	una captura actualiza solo la tarjeta de ese pez (o la deja pendiente
	hasta que se abra la ventana).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Collection = require(ReplicatedStorage.Shared.Collection)
local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Style = require(script.Parent.Parent.Interface.Style)
local FishDexCard = require(script.Parent.FishDexCard)
local FishDexTabs = require(script.Parent.FishDexTabs)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)
local WindowLayout = require(script.Parent.WindowLayout)

local FISH = Config.Economy.fish
local PREFIX = Protocol.PlayerAttributes.FishPrefix

-- Orden en la cuadrícula: por rareza y, dentro de ella, como en Config.
local ORDER: { [string]: number } = {}
for index, fish in FISH do
	for rank, rarity in Config.Economy.rarities do
		if rarity.id == fish.rarity then
			ORDER[fish.id] = rank * 1000 + index
		end
	end
end

type Card = FishDexCard.Card

local FishDex = {}

local function caught(player: Player, fishId: string): number
	local value = player:GetAttribute(`{PREFIX}{fishId}`)
	return if type(value) == "number" then value else 0
end

-- Punto rojo en el botón Peces cuando aparece una especie nueva sin mirar.
local function watchSpecies(
	player: Player,
	hud: HudButtons.HudButton,
	changed: (fishId: string) -> ()
)
	for _, fish in FISH do
		local before = caught(player, fish.id)
		player:GetAttributeChangedSignal(`{PREFIX}{fish.id}`):Connect(function()
			local now = caught(player, fish.id)
			if before == 0 and now > 0 then
				hud.setAlert(true) -- especie nueva sin mirar
			end
			before = now
			changed(fish.id)
		end)
	end
end

function FishDex.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local size = WindowLayout.size(Vector2.new(660, 500), Vector2.new(1040, 440))
	local window = Window.create(screen, "Coleccion", "Colección de peces", size)
	local hud = HudButtons.top("Peces", "fish", window.toggle)
	-- Arriba: barra de especies descubiertas y el premio por completarla.
	local bar = CardParts.bar(window.content, Style.PALETTE.Cards.Green, 22)
	bar.track.Position = UDim2.fromOffset(4, 6)
	bar.track.Size = UDim2.new(0.62, 0, 0, 36)
	local prize, prizeText = CardParts.iconText(window.content, "chest", 26, UIConfig.Colors.Coins)
	prize.AnchorPoint = Vector2.new(1, 0)
	prize.Position = UDim2.new(1, -4, 0, 2)
	prize.Size = UDim2.new(0.35, 0, 0, 44)
	local filter = FishDexTabs.ALL
	local grid = Instance.new("ScrollingFrame")
	local cards: { [string]: Card } = {}
	local function applyFilter()
		for _, fish in FISH do
			local card = cards[fish.id]
			if card then
				card.box.Visible = filter == FishDexTabs.ALL or fish.rarity == filter
			end
		end
	end
	local tabs = FishDexTabs.mount(window.content, 50, function(id: string)
		filter = id
		applyFilter()
		grid.CanvasPosition = Vector2.zero
	end)
	local gridTop = 52 + tabs.height
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromOffset(0, gridTop)
	grid.Size = UDim2.new(1, 0, 1, -gridTop)
	grid.ScrollBarThickness = 6
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(134, 158)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	local pad = Instance.new("UIPadding") -- deja ver el borde negro de las tarjetas
	pad.PaddingTop, pad.PaddingLeft = UDim.new(0, 4), UDim.new(0, 4)
	pad.Parent = grid
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local pending: { [string]: boolean } = {} -- tarjetas por (re)hacer al abrir
	for _, fish in FISH do
		pending[fish.id] = true
	end
	local function render()
		local found = 0
		local byRarity: { [string]: number } = {}
		local totals: { [string]: number } = { [FishDexTabs.ALL] = #FISH }
		for _, fish in FISH do
			local amount = caught(player, fish.id)
			found += if amount > 0 then 1 else 0
			totals[fish.rarity] = (totals[fish.rarity] or 0) + 1
			byRarity[fish.rarity] = (byRarity[fish.rarity] or 0) + (if amount > 0 then 1 else 0)
			local existing = cards[fish.id]
			if pending[fish.id] and existing and existing.known and amount > 0 then
				existing.info.Text = FishDexCard.infoText(fish.id, amount) -- solo cambió la cantidad
			elseif pending[fish.id] then
				if existing then
					existing.box:Destroy()
				end
				cards[fish.id] = FishDexCard.build(grid, fish.id, amount, ORDER[fish.id])
			end
			pending[fish.id] = nil
		end
		byRarity[FishDexTabs.ALL] = found
		tabs.counts(byRarity, totals)
		applyFilter()
		local nextStep = Collection.nextMilestone(found)
		bar.set(
			found / #FISH,
			if nextStep
				then `Descubiertos {found} / {#FISH} · premio con {nextStep}`
				else `¡Colección completa! {found} / {#FISH}`
		)
		prizeText.Text = if nextStep
			then `+{NumberFormat.short(
				Collection.reward(player, nextStep) * Perks.coinMultiplier(player)
			)} monedas`
			else "¡Cobrado!"
	end
	local spin: RBXScriptConnection? = nil
	window.onOpen(function()
		hud.setAlert(false)
		render()
		if not spin then
			spin = RunService.RenderStepped:Connect(function()
				local t = os.clock() * 1.2
				for _, entry in cards do
					if entry.model then
						entry.model:PivotTo(CFrame.Angles(0, t + entry.order, 0))
					end
				end
			end)
		end
	end)
	window.onClose(function()
		if spin then
			spin:Disconnect()
			spin = nil
		end
	end)
	local function changed(fishId: string)
		pending[fishId] = true
		if window.isOpen() then
			render()
		end
	end
	-- Las alertas empiezan cuando los datos ya cargaron (si no, todo parecería
	-- nuevo). En otro hilo: el resto del cliente no espera a los datos.
	task.spawn(function()
		while player:GetAttribute(Protocol.PlayerAttributes.DataLoaded) ~= true do
			player:GetAttributeChangedSignal(Protocol.PlayerAttributes.DataLoaded):Wait()
		end
		watchSpecies(player, hud, changed)
	end)
end

return FishDex
