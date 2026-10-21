--!strict
--[[
	HudFocus

	En táctil, con una ventana abierta solo se ve la ventana: se ocultan las
	columnas del HUD, el panel de hambre, los potenciadores (Interface/BoostBadges) y los botones
	de arriba, y un velo oscuro tapa lo demás (Pescar, «Siguiente meta», el
	aviso de los prompts y el juego). En un teléfono la ventana llena casi toda
	la pantalla y lo que asomaba por los costados se veía encimado (la X caía
	sobre la barra de arriba). En PC las ventanas son más chicas y el HUD queda
	a la vista, como siempre.
	El velo va justo debajo de las ventanas (Window usa ZIndex 10) y tapa
	también la franja de la barra de Roblox; los botones de Roblox quedan encima.
]]

local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Window = require(script.Parent.Window)

local VEIL_TRANSPARENCY = 0.45
local VEIL_Z = 9
local INSET_COVER = 120 -- cuánto sube el velo por encima de la pantalla del HUD

local HudFocus = {}

function HudFocus.start(screen: ScreenGui)
	local veil = Instance.new("Frame")
	veil.Name = "Velo"
	veil.BackgroundColor3 = Color3.new(0, 0, 0)
	veil.BackgroundTransparency = VEIL_TRANSPARENCY
	veil.BorderSizePixel = 0
	veil.Position = UDim2.fromOffset(0, -INSET_COVER)
	veil.Size = UDim2.new(1, 0, 1, INSET_COVER)
	veil.ZIndex = VEIL_Z
	veil.Active = true -- los toques no pasan al juego
	veil.Visible = false
	veil.Parent = screen

	local hud: { GuiObject } = { Layout.left(), Layout.right(), Layout.topBar() }
	for _, name in { "Hambre", "Impulsos" } do
		local object = screen:FindFirstChild(name)
		if object and object:IsA("GuiObject") then
			table.insert(hud, object)
		end
	end

	local open: { [Window.Window]: boolean } = {}
	Window.onAnyChange(function(window: Window.Window, opened: boolean)
		open[window] = if opened then true else nil
		-- Se pregunta a cada una si sigue abierta: alguna pudo ocultarse sin avisar.
		for each in open do
			if not each.isOpen() then
				open[each] = nil
			end
		end
		local focus = Device.touch() and next(open) ~= nil
		veil.Visible = focus
		for _, object in hud do
			object.Visible = not focus
		end
	end)
end

return HudFocus
