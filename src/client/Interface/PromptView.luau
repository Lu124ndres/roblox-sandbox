--!strict
--[[
	PromptView

	El aviso de los ProximityPrompt (entrenar, mejoras, comprar un traje, la
	ruleta) con la temática de la interfaz, en lugar del de Roblox: una placa
	de piedra volcánica (Interface/Kit) con la tecla tallada a la izquierda
	(E dorada en PC, el botón del mando en consola, «TOCA» en celular), el
	objeto arriba en chico («Requiere 3 monstruos») y la acción grande en
	dorado («Entrenar x3»). Entra con un rebote, late suave y, al apretar, se
	hunde. En celular la placa entera es el botón.

	Funciona con los prompts de Style = Custom (los que arma server/Proximity y
	Ambient/SpinStand); Roblox no dibuja nada para esos.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local InputHints = require(script.Parent.InputHints)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local SIZE = Vector2.new(270, 74) -- píxeles
local KEY = 56
local SLICE = 0.28
local KEY_SLICE = 0.2
local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LEAVE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BEAT = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local PromptView = {}

-- Dónde se ancla el cartel: la pieza o el Attachment que tiene el prompt.
local function adornee(prompt: ProximityPrompt): Instance?
	local parent = prompt.Parent
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment") or parent:IsA("Model")) then
		return parent
	end
	return nil
end

-- La tecla tallada: letra dorada, el botón del mando o «TOCA».
local function key(parent: Instance, prompt: ProximityPrompt): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Tecla"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 9, 0.5, 0)
	frame.Size = UDim2.fromOffset(KEY, KEY)
	frame.ZIndex = 3
	Kit.skin(frame, "boton", Kit.STONE).SliceScale = KEY_SLICE
	frame.Parent = parent
	local letter = Style.text(frame, "Letra", 34, nil, 3)
	letter.Position = UDim2.fromScale(0.1, 0.1)
	letter.Size = UDim2.fromScale(0.8, 0.8)
	letter.ZIndex = 4
	Kit.gold(letter)
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Boton"
	glyph.BackgroundTransparency = 1
	glyph.Position = UDim2.fromScale(0.12, 0.12)
	glyph.Size = UDim2.fromScale(0.76, 0.76)
	glyph.ScaleType = Enum.ScaleType.Fit
	glyph.ZIndex = 4
	glyph.Parent = frame
	local mode = InputHints.mode()
	glyph.Visible = mode == "gamepad"
	letter.Visible = mode ~= "gamepad"
	if mode == "gamepad" then
		glyph.Image = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
	elseif mode == "touch" then
		letter.Text = "TOCA"
	else
		letter.Text = string.upper(UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode))
	end
	return frame
end

local function build(prompt: ProximityPrompt, holder: Instance): BillboardGui
	local touch = InputHints.mode() == "touch"
	local gui = Instance.new("BillboardGui")
	gui.Name = "AvisoAccion"
	gui.Adornee = adornee(prompt)
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(SIZE.X, SIZE.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Active = touch
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Instance.new(if touch then "TextButton" else "Frame") :: GuiObject
	card.Name = "Placa"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromScale(1, 1)
	if card:IsA("TextButton") then
		card.Text = ""
		card.AutoButtonColor = false
	end
	local skin = Kit.skin(card, "casilla")
	skin.SliceScale = SLICE
	card.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = card

	key(card, prompt)
	local left = KEY + 18
	local object = Style.text(card, "Objeto", 17, UIConfig.Colors.TextMuted, 2)
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Position = UDim2.fromOffset(left, 8)
	object.Size = UDim2.new(1, -left - 12, 0, 20)
	object.Text = prompt.ObjectText
	object.Visible = prompt.ObjectText ~= ""
	object.ZIndex = 3
	local action = Style.text(card, "Accion", 32, nil, 3)
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Position = UDim2.fromOffset(left, if object.Visible then 28 else 16)
	action.Size = UDim2.new(1, -left - 12, 0, if object.Visible then 36 else 42)
	action.Text = prompt.ActionText
	action.ZIndex = 3
	Kit.gold(action)

	-- Los textos pueden cambiar mientras se ve (las vitrinas: Comprar / Ponerte).
	prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		action.Text = prompt.ActionText
	end)
	prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
		object.Text = prompt.ObjectText
	end)

	if card:IsA("TextButton") then
		card.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldBegin()
			end
		end)
		card.InputEnded:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldEnd()
			end
		end)
	end

	-- Se hunde un poco al apretar y vuelve.
	prompt.PromptButtonHoldBegan:Connect(function()
		TweenService:Create(scale, PRESS, { Scale = 0.92 }):Play()
	end)
	prompt.PromptButtonHoldEnded:Connect(function()
		TweenService:Create(scale, PRESS, { Scale = 1 }):Play()
	end)
	prompt.Triggered:Connect(function()
		scale.Scale = 0.9
		TweenService:Create(scale, POP, { Scale = 1 }):Play()
	end)

	gui.Parent = holder
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
	local beat = TweenService:Create(action, BEAT, { TextTransparency = 0.12 })
	beat:Play()
	gui.Destroying:Connect(function()
		beat:Cancel()
	end)
	return gui
end

function PromptView.start()
	local holder = Players.LocalPlayer:WaitForChild("PlayerGui")
	local shown: { [ProximityPrompt]: BillboardGui } = {}
	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or shown[prompt] then
			return
		end
		shown[prompt] = build(prompt, holder)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
		local gui = shown[prompt]
		shown[prompt] = nil
		if not gui then
			return
		end
		local card = gui:FindFirstChild("Placa")
		local scale = card and card:FindFirstChildOfClass("UIScale")
		if scale then
			TweenService:Create(scale, LEAVE, { Scale = 0.3 }):Play()
		end
		task.delay(LEAVE.Time, function()
			gui:Destroy()
		end)
	end)
end

return PromptView
