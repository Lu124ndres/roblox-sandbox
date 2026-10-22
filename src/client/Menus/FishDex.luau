--!strict
--[[
	FishDex

	Índice de peces: a la izquierda una columna de secciones (Todos y una por
	rareza, FishDexTabs) con su medallón, su avance y la suerte que da
	completarla; a la derecha la cabecera de la sección elegida (FishDexHeader:
	avance y premio o suerte) y la cuadrícula de sus especies, por rareza. Las
	descubiertas giran en 3D con su rareza y cuántas se han pescado; las que
	faltan son una silueta con candado y "???". El botón Índice del HUD se
	marca cuando hay un pez nuevo sin mirar. Los datos vienen de los
	atributos Pez_<id>.

	Los peces solo giran con la ventana abierta (un único RenderStepped), y
	una captura actualiza solo la tarjeta de ese pez (o la deja pendiente
	hasta que se abra la ventana).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FishDexCard = require(script.Parent.FishDexCard)
local FishDexHeader = require(script.Parent.FishDexHeader)
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
	local size = WindowLayout.size(Vector2.new(780, 520), Vector2.new(1040, 440))
	local window = Window.create(screen, "Coleccion", "Índice de peces", size)
	local hud = HudButtons.wide("Índice", "fish", window.toggle)
	local side = if WindowLayout.wide() then 200 else 196
	local filter = FishDexTabs.ALL
	local grid = Instance.new("ScrollingFrame")
	local cards: { [string]: Card } = {}
	local found: { [string]: number } = {}
	local totals: { [string]: number } = { [FishDexTabs.ALL] = #FISH }
	for _, fish in FISH do
		totals[fish.rarity] = (totals[fish.rarity] or 0) + 1
	end
	local header = FishDexHeader.mount(window.content, side + 6)
	local function applyFilter()
		for _, fish in FISH do
			local card = cards[fish.id]
			if card then
				card.box.Visible = filter == FishDexTabs.ALL or fish.rarity == filter
			end
		end
		header.set(filter, found[filter] or 0, totals[filter] or 0)
	end
	local tabs = FishDexTabs.mount(window.content, side, function(id: string)
		filter = id
		applyFilter()
		grid.CanvasPosition = Vector2.zero
	end)
	local gridTop = header.height + 8
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromOffset(side + 6, gridTop)
	grid.Size = UDim2.new(1, -side - 6, 1, -gridTop)
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
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = grid

	local pending: { [string]: boolean } = {} -- tarjetas por (re)hacer al abrir
	for _, fish in FISH do
		pending[fish.id] = true
	end
	local function render()
		table.clear(found)
		for _, fish in FISH do
			local amount = caught(player, fish.id)
			local known = if amount > 0 then 1 else 0
			found[FishDexTabs.ALL] = (found[FishDexTabs.ALL] or 0) + known
			found[fish.rarity] = (found[fish.rarity] or 0) + known
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
		tabs.counts(found, totals)
		applyFilter()
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
