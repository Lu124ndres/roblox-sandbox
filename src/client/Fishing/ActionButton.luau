--!strict
--[[
	ActionButton

	El aspecto de los botones grandes de acción (Pescar, Alimentar, ¡TIRA!):
	círculo con degradado (claro arriba, oscuro abajo), contorno oscuro, aro
	interior fino, brillo de vidrio arriba, ícono y el texto abajo. Al
	apretarlo se hunde un poco. `rings` lanza ondas que se abren y se
	desvanecen (llaman la atención sin cambiar el tamaño del botón).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)

local WHITE = Color3.new(1, 1, 1)
local PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ActionButton = {}

local function round(object: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = object
end

local function darker(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function ActionButton.new(
	screen: ScreenGui,
	name: string,
	text: string,
	color: Color3,
	icon: string
): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.BackgroundColor3 = WHITE
	button.AutoButtonColor = false
	button.Text = ""
	button.Visible = false
	round(button)
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color:Lerp(WHITE, 0.35)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, darker(color, 0.3)),
	})
	fill.Parent = button
	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = darker(color, 0.62)
	outline.Thickness = 3
	outline.Parent = button
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = button

	local ring = Instance.new("Frame")
	ring.Name = "Aro"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(0.86, 0.86)
	ring.BackgroundTransparency = 1
	round(ring)
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = WHITE
	ringStroke.Transparency = 0.55
	ringStroke.Thickness = 2
	ringStroke.Parent = ring
	ring.Parent = button

	local gloss = Instance.new("Frame")
	gloss.Name = "Brillo"
	gloss.AnchorPoint = Vector2.new(0.5, 0)
	gloss.Position = UDim2.fromScale(0.5, 0.06)
	gloss.Size = UDim2.fromScale(0.66, 0.34)
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0.55
	round(gloss)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new(0.2, 1)
	fade.Parent = gloss
	gloss.Parent = button

	local image = Icons.view(button, icon)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.4)
	image.Size = UDim2.fromScale(0.46, 0.46)

	local label = Style.text(button, "Texto", 40, WHITE, 2.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.75)
	label.Size = UDim2.fromScale(0.8, 0.22)
	label.Text = TextCase.upper(text)
	local labelStroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	labelStroke.Color = darker(color, 0.7)

	-- Se hunde al apretar (sirve igual con dedo, mouse o mando).
	local press = Instance.new("UIScale")
	press.Parent = button
	button.MouseButton1Down:Connect(function()
		TweenService:Create(press, PRESS, { Scale = 0.92 }):Play()
	end)
	local function release()
		TweenService:Create(press, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.Parent = screen
	return button
end

-- Ondas que salen del borde cada `every` segundos mientras el botón se ve.
function ActionButton.rings(button: TextButton, color: Color3, every: number)
	task.spawn(function()
		while button.Parent do
			if button.Visible then
				local wave = Instance.new("Frame")
				wave.Name = "Onda"
				wave.AnchorPoint = Vector2.new(0.5, 0.5)
				wave.Position = UDim2.fromScale(0.5, 0.5)
				wave.Size = UDim2.fromScale(1, 1)
				wave.BackgroundTransparency = 1
				round(wave)
				local stroke = Instance.new("UIStroke")
				stroke.Color = color:Lerp(WHITE, 0.3)
				stroke.Thickness = 4
				stroke.Transparency = 0.15
				stroke.Parent = wave
				wave.Parent = button
				local info =
					TweenInfo.new(every * 1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(wave, info, { Size = UDim2.fromScale(1.45, 1.45) }):Play()
				local out = TweenService:Create(stroke, info, { Transparency = 1, Thickness = 1 })
				out.Completed:Once(function()
					wave:Destroy()
				end)
				out:Play()
			end
			task.wait(every)
		end
	end)
end

return ActionButton
