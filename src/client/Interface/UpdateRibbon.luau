--!strict
--[[
	UpdateRibbon

	Cinta dorada justo debajo de la barra de hambre con la cuenta regresiva de
	la próxima actualización (Config/Updates, shared/UpdateClock):
	«ACTUALIZACIÓN EN 4d 12:30:05». Llamativa sin estorbar (pedido del
	usuario): es angosta, un brillo la cruza cada `SHINE_EVERY` segundos y en
	las últimas 24 h late suave. Cuando sale, dice «¡NUEVA ACTUALIZACIÓN!»
	durante Updates.freshHours. Tocarla abre NOVEDADES.
	Es hija del panel de hambre: se oculta con él (tutorial, ventana abierta
	en táctil), se escala con él y los avisos (Toasts.placeBelow) bajan
	debajo de ella. Se acomoda debajo del hijo visible más bajo del panel
	(los atajos de llenar y del descanso).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UpdateClock = require(ReplicatedStorage.Shared.UpdateClock)
local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local NAME = "CintaActualizacion"
local WIDTH, HEIGHT = 360, 30 -- antes de la escala del HUD
local GAP = 6 -- aire debajo del panel
local ICON_LEFT = 10
local TEXT_LEFT = 36 -- después del ícono
local WORDS_WIDTH = 170
local REFRESH_SECONDS = 1
local SOON_SECONDS = 24 * 3600 -- desde aquí late
local SHINE_EVERY = 8
local SHINE = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local PULSE = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local PULSE_SCALE = 1.06
local BAND = Color3.fromRGB(28, 18, 14)
local FRESH = Color3.fromRGB(110, 226, 140)

local UpdateRibbon = {}

local function band(panel: GuiObject): TextButton
	local ribbon = Instance.new("TextButton")
	ribbon.Name = NAME
	ribbon.Text = ""
	ribbon.AutoButtonColor = false
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	ribbon.BackgroundColor3 = BAND
	ribbon.BackgroundTransparency = 0.2
	ribbon.ClipsDescendants = true
	ribbon.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ribbon
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.Thickness = 2
	stroke.Parent = ribbon
	-- Las puntas se desvanecen: parece una cinta y no un botón más.
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	fade.Parent = ribbon
	ribbon.Parent = panel
	return ribbon
end

local function shine(ribbon: GuiObject)
	local light = Instance.new("Frame")
	light.Name = "Brillo"
	light.BackgroundColor3 = Color3.new(1, 1, 1)
	light.BorderSizePixel = 0
	light.Size = UDim2.fromScale(0.25, 1)
	light.Position = UDim2.fromScale(-0.3, 0)
	light.ZIndex = 3
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 20
	gradient.Parent = light
	light.Parent = ribbon
	task.spawn(function()
		while ribbon.Parent do
			task.wait(SHINE_EVERY)
			if ribbon.Visible then
				light.Position = UDim2.fromScale(-0.3, 0)
				TweenService:Create(light, SHINE, { Position = UDim2.fromScale(1.05, 0) }):Play()
			end
		end
	end)
end

-- Debajo del hijo visible más bajo del panel (en unidades del panel, antes de escalar).
local function follow(panel: GuiObject, ribbon: GuiObject)
	local function place()
		local scale = if panel.Size.X.Offset > 0
			then panel.AbsoluteSize.X / panel.Size.X.Offset
			else 1
		local bottom = panel.AbsoluteSize.Y
		for _, child in panel:GetChildren() do
			if child ~= ribbon and child:IsA("GuiObject") and child.Visible then
				local childBottom = child.AbsolutePosition.Y
					+ child.AbsoluteSize.Y
					- panel.AbsolutePosition.Y
				bottom = math.max(bottom, childBottom)
			end
		end
		ribbon.Position = UDim2.new(0.5, 0, 0, math.floor(bottom / math.max(scale, 0.01) + GAP))
	end
	local function watch(child: Instance)
		if child ~= ribbon and child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(place)
			child:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		end
	end
	for _, child in panel:GetChildren() do
		watch(child)
	end
	panel.ChildAdded:Connect(function(child)
		watch(child)
		task.defer(place)
	end)
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
end

function UpdateRibbon.mount(panel: GuiObject, openNews: () -> ())
	local ribbon = band(panel)
	local icon = Icons.view(ribbon, "sunburst")
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, ICON_LEFT, 0.5, 0)
	icon.Size = UDim2.fromOffset(HEIGHT - 6, HEIGHT - 6)
	if icon:IsA("ImageLabel") then
		icon.ImageColor3 = Color3.fromRGB(255, 206, 84)
	end
	-- Palabras y reloj en etiquetas separadas: AutoTranslate solo traduce las palabras.
	local words = Style.text(ribbon, "Texto", 20)
	words.AnchorPoint = Vector2.new(0, 0.5)
	Kit.gold(words)
	local clock = Style.text(ribbon, "Reloj", 20)
	clock.AnchorPoint = Vector2.new(0, 0.5)
	clock.TextXAlignment = Enum.TextXAlignment.Left
	clock.Position = UDim2.new(0, TEXT_LEFT + WORDS_WIDTH + 8, 0.5, 0)
	clock.Size = UDim2.new(0, WIDTH - TEXT_LEFT - WORDS_WIDTH - 18, 1, -6)
	-- Cuenta regresiva: palabras a la izquierda del reloj. Recién salida: el aviso centrado.
	local function arrange(countdown: boolean)
		words.TextXAlignment = if countdown
			then Enum.TextXAlignment.Right
			else Enum.TextXAlignment.Center
		words.Position = UDim2.new(0, TEXT_LEFT, 0.5, 0)
		words.Size = UDim2.new(0, if countdown then WORDS_WIDTH else WIDTH - TEXT_LEFT - 10, 1, -6)
		clock.Visible = countdown
	end
	shine(ribbon)
	follow(panel, ribbon)
	local scale = Instance.new("UIScale")
	scale.Parent = ribbon
	local pulse: Tween? = nil
	local function setPulse(on: boolean)
		if on and not pulse then
			pulse = TweenService:Create(scale, PULSE, { Scale = PULSE_SCALE })
			pulse:Play()
		elseif not on and pulse then
			pulse:Cancel()
			pulse = nil
			scale.Scale = 1
		end
	end
	ribbon.Activated:Connect(openNews)

	local function refresh()
		local upcoming = UpdateClock.upcoming()
		local fresh = UpdateClock.fresh()
		if upcoming then
			local left = upcoming.at - UpdateClock.now()
			words.Text = "ACTUALIZACIÓN EN"
			arrange(true)
			clock.Text = UpdateClock.format(left)
			clock.TextColor3 = Color3.new(1, 1, 1)
			setPulse(left < SOON_SECONDS)
		elseif fresh then
			words.Text = "¡NUEVA ACTUALIZACIÓN!"
			arrange(false)
			setPulse(true)
		end
		ribbon.Visible = upcoming ~= nil or fresh ~= nil
		local stroke = ribbon:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if upcoming == nil and fresh then FRESH else Kit.GOLD_OUTLINE
		end
	end
	task.spawn(function()
		while ribbon.Parent do
			refresh()
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return UpdateRibbon
