--!strict
--[[
	StarterShortcut

	Atajo del pack de inicio arriba de la columna del menú (pedido del usuario
	el 2026-10-21), con el mismo estilo que los de Poder y Monedas
	(Interface/FloatShortcut): el regalo flotando, el precio en Robux y abajo
	una cuenta regresiva de `timerHours` que vuelve a empezar al llegar a cero
	(solo da urgencia). Aparece desde que el pack se le abrió solo (atributo
	PackVistoEn, que pone el servidor) hasta que lo compra. Tocarlo abre la
	ventana del pack.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FloatShortcut = require(script.Parent.Parent.Interface.FloatShortcut)
local Layout = require(script.Parent.Parent.Interface.Layout)
local HudButtonParts = require(script.Parent.HudButtonParts)
local Purchases = require(script.Parent.Purchases)

local PACK = Config.Monetization.starterPack
local PERIOD = PACK.timerHours * 3600
local SIZE = 100 -- como los atajos de Poder y Monedas
local ATTR = Protocol.PlayerAttributes

local StarterShortcut = {}

local function clock(seconds: number): string
	local total = math.ceil(seconds)
	return string.format("%d:%02d:%02d", total // 3600, total // 60 % 60, total % 60)
end

function StarterShortcut.mount(open: () -> ())
	local player = Players.LocalPlayer
	-- Una fila del ancho de la columna, con el atajo centrado.
	local holder = Instance.new("Frame")
	holder.Name = "AtajoPack"
	holder.LayoutOrder = 0 -- lo primero de la columna
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(Layout.MENU_WIDTH, SIZE + 12) -- +12: el precio sobresale arriba
	holder.Visible = false
	holder.Parent = Layout.menu()
	local shortcut = FloatShortcut.new(holder, "Boton", "pack", SIZE, 0)
	shortcut.button.AnchorPoint = Vector2.new(0.5, 1)
	shortcut.button.Position = UDim2.fromScale(0.5, 1)
	shortcut.price.Text = tostring(PACK.robux)
	task.spawn(function()
		shortcut.price.Text = tostring(Purchases.price("PackInicio", false, PACK.robux))
	end)
	HudButtonParts.press(shortcut.button, open)

	local function seenAt(): number
		local value = player:GetAttribute(ATTR.StarterSeenAt)
		return if type(value) == "number" then value else 0
	end
	local running = false
	local function refresh()
		local shown = seenAt() > 0 and player:GetAttribute(ATTR.StarterPack) ~= true
		holder.Visible = shown
		if not shown or running then
			return
		end
		running = true
		task.spawn(function()
			while holder.Visible do
				local elapsed = math.max(0, Workspace:GetServerTimeNow() - seenAt())
				shortcut.label.Text = clock(PERIOD - elapsed % PERIOD)
				task.wait(1)
			end
			running = false
		end)
	end
	player:GetAttributeChangedSignal(ATTR.StarterSeenAt):Connect(refresh)
	player:GetAttributeChangedSignal(ATTR.StarterPack):Connect(refresh)
	refresh()
end

return StarterShortcut
