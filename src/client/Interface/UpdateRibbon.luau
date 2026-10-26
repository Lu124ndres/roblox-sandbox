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
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)
local UpdateRibbonLook = require(script.Parent.UpdateRibbonLook)

local WIDTH, HEIGHT = 360, 30 -- antes de la escala del HUD
local GAP = 6 -- aire debajo del panel
local TEXT_SIZE = 20
local WORD_GAP = 8 -- entre las palabras y el reloj
local REFRESH_SECONDS = 1
local SOON_SECONDS = 24 * 3600 -- desde aquí late
local PULSE = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local PULSE_SCALE = 1.06
local FRESH = Color3.fromRGB(110, 226, 140)

local UpdateRibbon = {}

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
	local ribbon = UpdateRibbonLook.band(panel, Vector2.new(WIDTH, HEIGHT))
	-- Palabras y reloj juntos, centrados como un solo bloque (pedido del usuario el 2026-10-26).
	-- En etiquetas separadas: AutoTranslate solo traduce las palabras.
	local line = Instance.new("Frame")
	line.Name = "Linea"
	line.BackgroundTransparency = 1
	line.Size = UDim2.fromScale(1, 1)
	line.Parent = ribbon
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, WORD_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = line
	local function label(name: string, order: number): TextLabel
		local text = Style.text(line, name, TEXT_SIZE)
		text.LayoutOrder = order
		text.TextScaled = false -- tamaño fijo: así el bloque mide lo que mide el texto
		text.TextSize = TEXT_SIZE
		text.AutomaticSize = Enum.AutomaticSize.X
		text.Size = UDim2.new(0, 0, 1, -6)
		return text
	end
	local words = label("Texto", 1)
	Kit.gold(words)
	local clock = label("Reloj", 2)
	UpdateRibbonLook.shine(ribbon)
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
			clock.Visible = true
			clock.Text = UpdateClock.format(left)
			clock.TextColor3 = Color3.new(1, 1, 1)
			setPulse(left < SOON_SECONDS)
		elseif fresh then
			words.Text = "¡NUEVA ACTUALIZACIÓN!"
			clock.Visible = false
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
