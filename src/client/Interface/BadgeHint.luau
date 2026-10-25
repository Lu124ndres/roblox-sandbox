--!strict
--[[
	BadgeHint

	Texto que aparece sobre una insignia de BoostBadges mientras el mouse está
	encima (p. ej. «+10% suerte y +10% poder» en la del grupo). En táctil las
	insignias no reciben toques (quedan detrás del joystick), así que ahí no
	sale: el porcentaje de abajo ya dice lo principal.
]]

local Style = require(script.Parent.Style)

local WIDTH = 260
local HEIGHT = 24
local LIFT = 6 -- separación entre la insignia y el texto
local COLOR = Color3.new(1, 1, 1)

local BadgeHint = {}

-- `text` se lee cada vez que entra el mouse: así sigue al estado (reclamado o no).
function BadgeHint.attach(button: GuiButton, text: () -> string)
	local label = Style.text(button, "Ayuda", 20, COLOR, 2.5)
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.fromOffset(0, -LIFT)
	label.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 5
	label.Visible = false
	button.MouseEnter:Connect(function()
		label.Text = text()
		label.Visible = true
	end)
	button.MouseLeave:Connect(function()
		label.Visible = false
	end)
end

return BadgeHint
