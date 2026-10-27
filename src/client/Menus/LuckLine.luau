--!strict
--[[
	LuckLine

	Línea que va en cada compra que da suerte (la tarjeta del VIP, la caña en MEJORAS,
	el pack de inicio): "Legendario 0.64 % → 0.72 %" con los números de este jugador
	(shared/LuckOdds) y el botón "Ver probabilidades", que abre la tabla completa con
	la columna de la compra (Menus/LuckWindow). Así el número se ve antes de comprar.
		mount(parent, label, after) -> { frame, refresh }
			label  nombre de la compra para la tabla ("VIP")
			after  función que da la suerte con la compra (se llama al repintar)
	Se repinta sola cuando cambia algo del jugador (caña, pase, colección).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LuckOdds = require(ReplicatedStorage.Shared.LuckOdds)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)
local LuckWindow = require(script.Parent.LuckWindow)

local COLORS = UIConfig.Colors
local SHOWN = "Legendario" -- la rareza que se compara en la línea: rara, pero no en milésimas
local NARROW = 320 -- px: con menos ancho, el % y el botón van en dos filas

export type Line = { frame: Frame, refresh: () -> () }

local LuckLine = {}

function LuckLine.mount(parent: Instance, label: string, after: () -> number): Line
	local player = Players.LocalPlayer
	local frame = Instance.new("Frame")
	frame.Name = "LineaSuerte"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	local text = Style.text(frame, "Probabilidad", 24, COLORS.Success, 2)
	local button =
		Style.button(frame, "VerProbabilidades", Style.PALETTE.Cards.Blue, "Ver probabilidades")
	button.Activated:Connect(function()
		LuckWindow.open(after, label)
	end)

	-- En un hueco angosto (tarjeta de la tienda), dos filas: el % arriba y el botón abajo.
	local function place()
		local narrow = frame.AbsoluteSize.X < NARROW
		text.Size = if narrow then UDim2.fromScale(1, 0.48) else UDim2.fromScale(0.62, 1)
		text.TextXAlignment = if narrow
			then Enum.TextXAlignment.Center
			else Enum.TextXAlignment.Left
		button.AnchorPoint = if narrow then Vector2.new(0.5, 1) else Vector2.new(1, 0)
		button.Position = if narrow then UDim2.fromScale(0.5, 1) else UDim2.fromScale(1, 0)
		button.Size = if narrow then UDim2.fromScale(0.9, 0.5) else UDim2.fromScale(0.36, 1)
		local caption = button:FindFirstChild("Texto") :: TextLabel?
		if caption then -- angosto: la palabra sola, así la letra no se achica
			caption.Text = if narrow then "Probabilidades" else "Ver probabilidades"
		end
	end
	place()
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	local function chanceOf(luck: number): (string, number)
		for _, rarity in LuckOdds.chances(luck) do
			if rarity.id == SHOWN then
				return rarity.name, rarity.chance
			end
		end
		return SHOWN, 0
	end

	local function refresh()
		local name, now = chanceOf(LuckOdds.total(player))
		local _, later = chanceOf(after())
		text.Text = if later > now
			then `{name} {LuckOdds.text(now)} → {LuckOdds.text(later)}`
			else `{name} {LuckOdds.text(now)}`
	end
	refresh()

	local pending = false
	local connection = player.AttributeChanged:Connect(function()
		if not pending then
			pending = true
			task.defer(function()
				pending = false
				if frame.Parent then
					refresh()
				end
			end)
		end
	end)
	frame.Destroying:Connect(function()
		connection:Disconnect()
	end)
	return { frame = frame, refresh = refresh }
end

return LuckLine
