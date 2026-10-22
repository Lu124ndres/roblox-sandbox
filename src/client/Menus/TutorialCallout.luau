--!strict
--[[
	TutorialCallout

	El anuncio grande de cada paso del tutorial («¡PESCA!», «¡ENTRENA!»), en
	letras de cómic blancas con borde negro grueso, como en
	referencias/Ejemplo.mp4. Para que no estorbe (pedido del usuario):
		- sale una sola vez por paso y dura Config.Retention.tutorialIntroSeconds;
		- va en el tercio de arriba, nunca en el centro de la pantalla;
		- entra achicándose, se queda quieto y se desvanece (no late);
		- no sale si hay una ventana abierta;
		- no atrapa toques ni clics.
	Lo que queda mientras dura el paso es la línea de objetivo (TutorialBanner).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local Window = require(script.Parent.Window)

local WIDTH, HEIGHT = 900, 110
local SCALE_TOUCH = 0.6
local Y = 0.24 -- alto de la pantalla donde va el centro del texto
local IN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type Callout = { play: (text: string) -> () }

local TutorialCallout = {}

function TutorialCallout.new(screen: ScreenGui): Callout
	local root = Instance.new("Frame")
	root.Name = "AnuncioTutorial"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, Y)
	root.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	root.BackgroundTransparency = 1
	root.Active = false
	root.Visible = false
	root.ZIndex = 21
	root.Parent = screen
	Layout.scaleWith(root)
	local device = Instance.new("UIScale")
	device.Scale = if Device.touch() then SCALE_TOUCH else 1
	device.Parent = root
	local pop = Instance.new("UIScale")
	pop.Parent = root
	local label = Style.text(root, "Texto", 96, Color3.new(1, 1, 1), 7)
	label.Size = UDim2.fromScale(1, 1)
	local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke

	local openWindows: { [Window.Window]: true } = {}
	Window.onAnyChange(function(window: Window.Window, opened: boolean)
		openWindows[window] = if opened then true else nil
		if opened then
			root.Visible = false
		end
	end)

	local token = 0
	local function play(text: string)
		if next(openWindows) ~= nil then
			return
		end
		token += 1
		local mine = token
		label.Text = text
		label.TextTransparency = 0
		stroke.Transparency = 0
		pop.Scale = 1.5
		root.Visible = true
		TweenService:Create(pop, IN, { Scale = 1 }):Play()
		task.delay(Config.Retention.tutorialIntroSeconds, function()
			if token ~= mine then
				return
			end
			TweenService:Create(label, OUT, { TextTransparency = 1 }):Play()
			TweenService:Create(stroke, OUT, { Transparency = 1 }):Play()
			task.delay(OUT.Time, function()
				if token == mine then
					root.Visible = false
				end
			end)
		end)
	end

	return { play = play }
end

return TutorialCallout
