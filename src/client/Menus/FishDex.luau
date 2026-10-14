--!strict
--[[
	FishDex

	Colección de peces: las 12 especies en una cuadrícula. Las descubiertas
	se ven en 3D girando, con su rareza y cuántas se han pescado; las que
	faltan, como una silueta oscura con "???". Arriba, el avance (7/12) y el
	premio por completarla. El botón Peces del HUD se marca cuando hay un
	pez nuevo sin mirar. Los datos vienen de los atributos Pez_<id>.

	Los peces solo giran con la ventana abierta (un único RenderStepped), y
	una captura actualiza solo la tarjeta de ese pez (o la deja pendiente
	hasta que se abra la ventana).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local FishDexCard = require(script.Parent.FishDexCard)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local FISH = Config.Economy.fish
local PREFIX = Protocol.PlayerAttributes.FishPrefix

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
	local window = Window.create(screen, "Coleccion", "Colección de peces", Vector2.new(620, 460))
	local hud = HudButtons.top("Peces", "fish", window.toggle)

	local summary = Ui.label("Avance", window.content, UIConfig.Fonts.Body, UIConfig.TextSizes.Body)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.Size = UDim2.new(1, 0, 0, 26)
	local grid = Instance.new("ScrollingFrame")
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromOffset(0, 32)
	grid.Size = UDim2.new(1, 0, 1, -32)
	grid.ScrollBarThickness = 6
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(132, 150)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local cards: { [string]: Card } = {}
	local pending: { [string]: boolean } = {} -- tarjetas por (re)hacer al abrir
	for _, fish in FISH do
		pending[fish.id] = true
	end
	local function render()
		local found = 0
		for index, fish in FISH do
			local amount = caught(player, fish.id)
			found += if amount > 0 then 1 else 0
			local existing = cards[fish.id]
			if pending[fish.id] and existing and existing.known and amount > 0 then
				existing.info.Text = FishDexCard.infoText(fish.id, amount) -- solo cambió la cantidad
			elseif pending[fish.id] then
				if existing then
					existing.box:Destroy()
				end
				cards[fish.id] = FishDexCard.build(grid, fish.id, amount, index)
			end
			pending[fish.id] = nil
		end
		summary.Text =
			`Descubiertos {found}/{#FISH} · completa la colección: +{NumberFormat.short(
				Config.Retention.collectionBonus
			)} monedas`
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
