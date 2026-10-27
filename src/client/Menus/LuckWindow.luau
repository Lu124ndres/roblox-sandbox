--!strict
--[[
	LuckWindow

	Ventana "Tus probabilidades": el % de cada rareza con la suerte de ahora (la misma
	que usa el sorteo del servidor, shared/LuckOdds). Si la abre una compra que da
	suerte (VIP, caña, pack: Menus/LuckLine), suma una columna con lo que tendría
	con esa compra. La política de Roblox pide explicar con números lo que se vende y
	cambia probabilidades; por eso no basta un ícono: la tabla dice los números.
		start(screen)          crea la ventana (Main.client)
		open(after?, label?)   la abre; `after` = la función que da la suerte con la
		                       compra (se recalcula si cambia algo) y `label` su nombre
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LuckOdds = require(ReplicatedStorage.Shared.LuckOdds)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local Window = require(script.Parent.Window)

local COLORS = UIConfig.Colors
local ROW_HEIGHT = 1 / 7 -- encabezado + 6 rarezas dentro del hueco

local LuckWindow = {}

local opener: (((() -> number)?, string?) -> ())? = nil

local function luckText(luck: number): string
	return `+{math.round(luck * 100)} %`
end

-- Una fila de la tabla: nombre, ahora y (si hay compra) con la compra.
local function row(parent: Instance, index: number): { TextLabel }
	local cells = {}
	for column, width in { 0.4, 0.3, 0.3 } do
		local x = if column == 1 then 0 elseif column == 2 then 0.4 else 0.7
		local label = Style.text(parent, `Celda{index}_{column}`, 26, nil, 2)
		label.Position = UDim2.new(x, 8, ROW_HEIGHT * (index - 1), 4)
		label.Size = UDim2.new(width, -16, ROW_HEIGHT, -8)
		label.TextXAlignment = if column == 1
			then Enum.TextXAlignment.Left
			else Enum.TextXAlignment.Right
		label.ZIndex = 2
		table.insert(cells, label)
	end
	return cells
end

function LuckWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window =
		Window.create(screen, "Probabilidades", "Tus probabilidades", Vector2.new(560, 500))

	local header = Style.text(window.content, "Suerte", 26, nil, 2)
	header.Size = UDim2.fromScale(1, 0.1)
	Kit.gold(header)

	local slot = Instance.new("Frame")
	slot.Name = "Tabla"
	slot.Position = UDim2.fromScale(0, 0.12)
	slot.Size = UDim2.fromScale(1, 0.72)
	slot.Parent = window.content
	Kit.skin(slot, "hondo")

	local titles = row(slot, 1)
	titles[1].Text = "Rareza"
	titles[2].Text = "Ahora"
	for _, label in titles do
		label.TextColor3 = COLORS.TextMuted
	end
	local rows: { { TextLabel } } = {}
	for index = 1, #LuckOdds.chances(0) do
		rows[index] = row(slot, index + 1)
	end

	local note = Style.text(window.content, "Nota", 18, COLORS.TextMuted, 2)
	note.Position = UDim2.fromScale(0, 0.86)
	note.Size = UDim2.fromScale(1, 0.12)
	note.Text = "La suerte sube todo menos lo común. Redondeado a dos decimales."

	local after: (() -> number)? = nil
	local label: string? = nil
	local function paint()
		local now = LuckOdds.total(player)
		header.Text = `Tu suerte: {luckText(now)}`
		titles[3].Text = if after then `Con {label or "la compra"}` else ""
		local current = LuckOdds.chances(now)
		local future = if after then LuckOdds.chances(after()) else nil
		for index, rarity in current do
			local cells = rows[index]
			cells[1].Text = rarity.name
			cells[1].TextColor3 = UIConfig.RarityColors[rarity.id] or COLORS.Text
			cells[2].Text = LuckOdds.text(rarity.chance)
			cells[3].Text = if future then LuckOdds.text(future[index].chance) else ""
			cells[3].TextColor3 = COLORS.Success
		end
	end

	-- Mientras está abierta, sigue a la suerte (caña nueva, pase, evento, colección).
	local pending = false
	player.AttributeChanged:Connect(function()
		if window.isOpen() and not pending then
			pending = true
			task.defer(function()
				pending = false
				paint()
			end)
		end
	end)

	opener = function(withPurchase: (() -> number)?, name: string?)
		after = withPurchase
		label = name
		paint()
		window.open()
	end
	window.onOpen(paint)
end

function LuckWindow.open(after: (() -> number)?, label: string?)
	if opener then
		opener(after, label)
	end
end

return LuckWindow
