--!strict
--[[
	GoalBadge

	Globo de la siguiente meta sobre un botón grande del HUD (lo usa NextGoal):
	una píldora en la esquina de arriba a la derecha del botón, donde va el punto
	rojo de HudButtonParts (lo tapa), con "!" en verde y latiendo si ya puede
	hacerlo, o el % de avance en ámbar si le falta poco.
	El texto de la meta sale en una placa chica de piedra a la derecha del botón:
	en PC al pasar el mouse por el botón y en táctil al tocar el globo. Se va sola
	a los TIP_SECONDS, al sacar el mouse o al apretar el botón.
		mount(botón) -> { set(meta?) }   nil esconde el globo y la placa
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Parent.Interface.Device)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local BADGE_WIDTH, BADGE_HEIGHT = 48, 28
local BADGE_TEXT = 22
local BADGE_INSET = 8 -- el centro del globo, adentro de la esquina (como el punto rojo)
local BADGE_Z = 7 -- encima del punto rojo (ZIndex 6)
local PULSE_SCALE = 1.15 -- cuánto crece al latir cuando ya se puede
local TIP_WIDTH, TIP_HEIGHT = 230, 56
local TIP_TEXT = 18
local TIP_GAP = 8 -- aire entre el botón y la placa
local TIP_SLICE = 0.3
local TIP_Z = 8
local TIP_START_SCALE = 0.85 -- la placa entra creciendo desde aquí
local TIP_SECONDS = 4

export type Goal = { text: string, fraction: number, ready: boolean }
export type Badge = { set: (goal: Goal?) -> () }

local GoalBadge = {}

local function makeBadge(button: TextButton): (TextButton, TextLabel, UIScale)
	local badge = Instance.new("TextButton")
	badge.Name = "Meta"
	badge.Text = ""
	badge.AutoButtonColor = false
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, -BADGE_INSET, 0, BADGE_INSET)
	badge.Size = UDim2.fromOffset(BADGE_WIDTH, BADGE_HEIGHT)
	badge.ZIndex = BADGE_Z
	badge.Visible = false
	-- En PC el globo deja pasar el clic al botón (el texto sale al pasar el mouse).
	badge.Interactable = Device.touch()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = badge
	Style.border(badge, 2)
	local scale = Instance.new("UIScale")
	scale.Parent = badge
	local label = Style.text(badge, "Texto", BADGE_TEXT, nil, 2)
	label.Position = UDim2.fromOffset(4, 2)
	label.Size = UDim2.new(1, -8, 1, -4)
	label.Interactable = false
	badge.Parent = button
	return badge, label, scale
end

local function makeTip(button: TextButton): (Frame, TextLabel, UIScale)
	local tip = Instance.new("Frame")
	tip.Name = "MetaTexto"
	tip.AnchorPoint = Vector2.new(0, 0.5)
	tip.Position = UDim2.new(1, TIP_GAP, 0.5, 0)
	tip.Size = UDim2.fromOffset(TIP_WIDTH, TIP_HEIGHT)
	tip.ZIndex = TIP_Z
	tip.Interactable = false
	tip.Visible = false
	Kit.skin(tip, "hondo").SliceScale = TIP_SLICE
	local scale = Instance.new("UIScale")
	scale.Parent = tip
	local label = Style.text(tip, "Texto", TIP_TEXT, nil, 2)
	label.TextWrapped = true
	label.Position = UDim2.fromOffset(10, 6)
	label.Size = UDim2.new(1, -20, 1, -12)
	tip.Parent = button
	return tip, label, scale
end

function GoalBadge.mount(button: TextButton): Badge
	local badge, badgeLabel, badgeScale = makeBadge(button)
	local tip, tipLabel, tipScale = makeTip(button)
	local pulse = TweenService:Create(badgeScale, UIConfig.Tweens.Pulse, { Scale = PULSE_SCALE })
	local current: Goal? = nil
	local pulsing = false
	local token = 0 -- cada vez que se muestra o esconde; el temporizador viejo no la cierra

	local function hide()
		token += 1
		tip.Visible = false
	end

	local function show()
		if not current then
			return
		end
		token += 1
		local mine = token
		tip.Visible = true
		tipScale.Scale = TIP_START_SCALE
		TweenService:Create(tipScale, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
		task.delay(TIP_SECONDS, function()
			if token == mine then
				tip.Visible = false
			end
		end)
	end

	button.MouseEnter:Connect(show)
	button.MouseLeave:Connect(hide)
	button.Activated:Connect(hide)
	badge.Activated:Connect(function()
		if tip.Visible then
			hide()
		else
			show()
		end
	end)

	local function set(goal: Goal?)
		current = goal
		badge.Visible = goal ~= nil
		local ready = goal ~= nil and goal.ready
		if ready ~= pulsing then
			pulsing = ready
			if ready then
				pulse:Play()
			else
				pulse:Cancel()
				badgeScale.Scale = 1
			end
		end
		if not goal then
			hide()
			return
		end
		badgeLabel.Text = if goal.ready
			then "!"
			else `{math.floor(math.clamp(goal.fraction, 0, 1) * 100)}%`
		badge.BackgroundColor3 = if goal.ready then COLORS.Success else COLORS.Warning
		tipLabel.Text = goal.text
	end

	return { set = set }
end

return GoalBadge
