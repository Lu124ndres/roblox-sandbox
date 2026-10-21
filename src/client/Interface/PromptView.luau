--!strict
--[[
	PromptView

	El aviso de los ProximityPrompt (entrenar, mejoras, comprar un traje, la
	ruleta) con la temática de la interfaz, en lugar del de Roblox: una placa
	de piedra volcánica (Interface/Kit) con la tecla tallada a la izquierda
	(E dorada en PC, el botón del mando en consola, «TOCA» en celular), el
	objeto arriba en chico («Requiere 3 monstruos») y la acción grande en
	dorado («Entrenar x3»). Entra con un rebote, late suave y, al apretar, se
	hunde. En táctil no flota sobre el objeto: va fijo junto al botón de saltar
	(PromptDock) y la placa entera es el botón. La tecla la talla PromptKey.

	Funciona con los prompts de Style = Custom (los que arma server/Proximity y
	Ambient/SpinStand); Roblox no dibuja nada para esos.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Device)
local InputHints = require(script.Parent.InputHints)
local Kit = require(script.Parent.Kit)
local PromptDock = require(script.Parent.PromptDock)
local PromptKey = require(script.Parent.PromptKey)
local Style = require(script.Parent.Style)

local SIZE = Vector2.new(270, 74) -- píxeles
local KEY = PromptKey.SIZE
local SLICE = 0.28
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

-- PC y mando: el cartel flota sobre el objeto (BillboardGui).
local function billboard(prompt: ProximityPrompt): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "AvisoAccion"
	gui.Adornee = adornee(prompt)
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(SIZE.X, SIZE.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Name = "Marco"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui
	return gui, frame
end

local function build(prompt: ProximityPrompt, holder: Instance): LayerCollector
	-- Táctil: fijo junto a Saltar (PromptDock); la placa entera es el botón.
	local docked = Device.touch()
	local touch = docked or InputHints.mode() == "touch"
	local gui: LayerCollector, frame: Frame
	if docked then
		gui, frame = PromptDock.make(holder, SIZE)
	else
		gui, frame = billboard(prompt)
	end
	if gui:IsA("BillboardGui") then
		gui.Active = touch
	end

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
	card.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = card

	PromptKey.make(card, prompt)
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
	local shown: { [ProximityPrompt]: LayerCollector } = {}
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
		local card = gui:FindFirstChild("Placa", true)
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
