--!strict
--[[
	TutorialBanner

	La instrucción grande del tutorial, arriba al centro (pedido del usuario:
	«letras grandes que digan qué hay que hacer»): el título en blanco con
	borde oscuro, como los anuncios del juego («¡PESCA 5 PECES!»), el avance
	al final en dorado («2/5») y debajo una línea corta de cómo se hace
	(«Mantén E en la playa»). Entra con un rebote, late suave y, al cumplir
	un paso, muestra «¡LISTO!» en verde un momento. En celular es más chico
	(SCALE_TOUCH) para no tapar la vista. Solo muestra: el paso y el avance
	los decide el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WIDTH, HEIGHT = 720, 118
local SCALE_TOUCH = 0.62
local TOP = 92 -- píxeles desde arriba: debajo del panel de hambre
local TOP_TOUCH = 118 -- en celular el panel de hambre baja más y el aviso va debajo del nombre
local WHITE = Color3.new(1, 1, 1)
local DONE = Color3.fromRGB(120, 240, 130)
local GOLD_HEX = "FFD24A"
local POP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BEAT = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local DONE_SECONDS = 1.4

export type Banner = {
	set: (title: string, progress: string, hint: string) -> (),
	done: () -> (),
	show: (visible: boolean) -> (),
}

local TutorialBanner = {}

function TutorialBanner.new(screen: ScreenGui): Banner
	local root = Instance.new("Frame")
	root.Name = "Tutorial"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, if Device.touch() then TOP_TOUCH else TOP)
	root.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.ZIndex = 20
	root.Parent = screen
	Layout.scaleWith(root)
	local device = Instance.new("UIScale")
	device.Scale = if Device.touch() then SCALE_TOUCH else 1
	device.Parent = root
	local pop = Instance.new("UIScale")
	pop.Parent = root

	local row = Instance.new("Frame")
	row.Name = "Fila"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 64)
	row.Parent = root
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 14)
	list.Parent = row
	-- Un solo texto («¡PESCA 5 PECES!  2/5»): con dos etiquetas de ancho automático la
	-- lista las cruzaba. El avance va en dorado con un texto enriquecido.
	local title = Style.text(row, "Titulo", 56, WHITE, 5)
	title.RichText = true
	title.Size = UDim2.new(1, 0, 0, 64)
	title.LayoutOrder = 1
	local hint = Style.text(root, "Como", 26, WHITE:Lerp(UIConfig.Colors.Fishing, 0.35), 2.5)
	hint.Position = UDim2.fromOffset(0, 70)
	hint.Size = UDim2.new(1, 0, 0, 32)

	local beat = TweenService:Create(title, BEAT, { TextTransparency = 0.1 })
	local token = 0
	local function set(titleText: string, progressText: string, hintText: string)
		token += 1
		title.Text = if progressText ~= ""
			then `{titleText}  <font color="#{GOLD_HEX}">{progressText}</font>`
			else titleText
		title.TextColor3 = WHITE
		hint.Text = hintText
		pop.Scale = 0.4
		TweenService:Create(pop, POP, { Scale = 1 }):Play()
		beat:Play()
	end

	-- «¡LISTO!» en verde; quien llama vuelve a poner el paso siguiente con `set`.
	local function done()
		token += 1
		local mine = token
		title.Text = "¡LISTO!"
		title.TextColor3 = DONE
		hint.Text = ""
		pop.Scale = 0.6
		TweenService:Create(pop, POP, { Scale = 1.1 }):Play()
		task.delay(DONE_SECONDS, function()
			if token == mine then
				TweenService:Create(pop, POP, { Scale = 1 }):Play()
			end
		end)
	end

	return {
		set = set,
		done = done,
		show = function(visible: boolean)
			root.Visible = visible
		end,
	}
end

return TutorialBanner
