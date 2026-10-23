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
	Más grande y llamativo que los de Poder y Monedas (pedido del usuario el
	2026-10-22: «está muy pequeño»): un segundo halo de rayos naranja que gira
	al revés, un latido suave y una cinta roja de ¡OFERTA! (dress).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FloatShortcut = require(script.Parent.Parent.Interface.FloatShortcut)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local HudButtonParts = require(script.Parent.HudButtonParts)
local Purchases = require(script.Parent.Purchases)
local Style = require(script.Parent.Parent.Interface.Style)

local PACK = Config.Monetization.starterPack
local PERIOD = PACK.timerHours * 3600
local SIZE = 170 -- los de Poder y Monedas miden 100: este tiene que destacar
local ROW_HEIGHT = 112 -- alto de su fila en la columna (el de cuando medía 100)
local HALO_COLOR = Color3.fromRGB(255, 130, 40)
local RIBBON_COLOR = Color3.fromRGB(220, 40, 45)
local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local HALO_SPIN = TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local ATTR = Protocol.PlayerAttributes

local StarterShortcut = {}

local function clock(seconds: number): string
	local total = math.ceil(seconds)
	return string.format("%d:%02d:%02d", total // 3600, total // 60 % 60, total % 60)
end

-- Lo que lo hace destacar sobre los otros atajos: halo, latido y cinta de oferta.
local function dress(shortcut: FloatShortcut.Shortcut)
	local float = shortcut.button:FindFirstChild("Flota")
	if not float or not float:IsA("Frame") then
		return
	end
	local halo = Icons.view(float, "sunburst")
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.42)
	halo.Size = UDim2.fromScale(1.5, 1.5)
	halo.ZIndex = 0
	if halo:IsA("ImageLabel") then
		halo.ImageColor3 = HALO_COLOR
		halo.ImageTransparency = 0.3
	end
	TweenService:Create(halo, HALO_SPIN, { Rotation = -360 }):Play()

	local pulse = Instance.new("UIScale")
	pulse.Parent = float
	TweenService:Create(pulse, PULSE, { Scale = 1.08 }):Play()

	local ribbon = Instance.new("Frame")
	ribbon.Name = "Oferta"
	ribbon.BackgroundColor3 = RIBBON_COLOR
	ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
	ribbon.Position = UDim2.fromScale(0.24, 0.14)
	ribbon.Size = UDim2.fromScale(0.6, 0.2)
	ribbon.Rotation = -14
	ribbon.ZIndex = 4
	ribbon.Parent = float
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = ribbon
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(90, 10, 10)
	edge.Thickness = 2.5
	edge.Parent = ribbon
	local text = Style.text(ribbon, "Texto", 26, Color3.new(1, 1, 1), 2)
	text.Text = "¡OFERTA!"
	text.Size = UDim2.fromScale(0.9, 0.85)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	text.ZIndex = 5

	shortcut.label.Size = UDim2.new(1, 0, 0, 30) -- la cuenta regresiva, más grande
	local limit = shortcut.label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 28
	end
end

function StarterShortcut.mount(open: () -> ())
	local player = Players.LocalPlayer
	-- Una fila del ancho de la columna, con el atajo centrado.
	local holder = Instance.new("Frame")
	holder.Name = "AtajoPack"
	holder.LayoutOrder = 0 -- lo primero de la columna
	holder.BackgroundTransparency = 1
	-- La fila guarda el alto de antes y el ícono sobresale hacia arriba: si creciera,
	-- la columna (que se ajusta a la pantalla) achicaría todos sus botones.
	holder.Size = UDim2.fromOffset(Layout.MENU_WIDTH, ROW_HEIGHT)
	holder.Visible = false
	holder.Parent = Layout.menu()
	local shortcut = FloatShortcut.new(holder, "Boton", "pack", SIZE, 0)
	shortcut.button.AnchorPoint = Vector2.new(0.5, 1)
	shortcut.button.Position = UDim2.fromScale(0.5, 1)
	shortcut.price.Text = tostring(PACK.robux)
	dress(shortcut)
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
