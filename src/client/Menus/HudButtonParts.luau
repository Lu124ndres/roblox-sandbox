--!strict
--[[
	HudButtonParts

	Piezas que comparten los botones del HUD (HudButtons) y los atajos de Robux
	(Interface/QuickBuys):
		alertDot  punto rojo de "hay algo nuevo" en la esquina de arriba a la derecha
		press     rebote y sonido al tocarlo, y luego la acción (devuelve el apretón)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

local HudButtonParts = {}

function HudButtonParts.alertDot(parent: GuiObject): Frame
	local dot = Instance.new("Frame")
	dot.Name = "Aviso"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -8, 0, 8)
	dot.Size = UDim2.fromOffset(14, 14)
	dot.BackgroundColor3 = UIConfig.Colors.Bite
	dot.Visible = false
	dot.ZIndex = 6
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot
	Style.border(dot, 2)
	dot.Parent = parent
	return dot
end

-- Devuelve el apretón, para dispararlo también sin tocar el botón (las flechas del mando).
function HudButtonParts.press(button: GuiButton, onClick: () -> ()): () -> ()
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local function pressed()
		Sounds.play("Click")
		scale.Scale = 0.88
		TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
		onClick()
	end
	button.Activated:Connect(pressed)
	return pressed
end

return table.freeze(HudButtonParts)
