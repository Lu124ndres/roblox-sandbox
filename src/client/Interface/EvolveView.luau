--!strict
--[[
	EvolveView

	Cada cuarto de barra que se llena, el monstruo evoluciona y no come por
	unos segundos (Config.Giants.cycle.evolveSeconds). Mientras tanto, encima
	de la barra del hambre aparece un cartel brillante con la cuenta regresiva
	("✨ ¡EVOLUCIONANDO! 4 ✨"). Lee el atributo EvolucionHasta que publica el
	servidor (GiantService) con la hora del servidor en que termina.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Ui = require(script.Parent.Parent.Ui)
local HungerPanel = require(script.Parent.HungerPanel)
local Style = require(script.Parent.Style)

local COLOR_A = Color3.fromRGB(150, 90, 255)
local COLOR_B = Color3.fromRGB(255, 120, 220)

local EvolveView = {}

function EvolveView.mount(panel: Frame)
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local left = HungerPanel.LEFT
	local card = Instance.new("Frame")
	card.Name = "Evolucion"
	card.BackgroundColor3 = COLOR_A
	card.Position = UDim2.fromOffset(left, 22)
	card.Size = UDim2.new(1, -left, 0, 30)
	card.ZIndex = 20
	card.Visible = false
	Ui.corner(card, 10)
	Style.border(card, 3)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLOR_A),
		ColorSequenceKeypoint.new(0.5, COLOR_B),
		ColorSequenceKeypoint.new(1, COLOR_A),
	})
	gradient.Parent = card
	card.Parent = panel
	local label = Style.text(card, "Texto", 24, nil, 2.5)
	label.ZIndex = 21
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.new(1, -12, 1, -4)

	local connection: RBXScriptConnection? = nil
	local function stop()
		card.Visible = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
	local function refresh()
		local untilAt = state:GetAttribute(Protocol.GiantAttributes.EvolvingUntil)
		if type(untilAt) ~= "number" or untilAt <= Workspace:GetServerTimeNow() then
			stop()
			return
		end
		local endsAt: number = untilAt
		card.Visible = true
		if connection then
			return
		end
		connection = RunService.RenderStepped:Connect(function()
			local remaining = endsAt - Workspace:GetServerTimeNow()
			if remaining <= 0 then
				stop()
				return
			end
			local t = os.clock()
			gradient.Offset = Vector2.new(math.sin(t * 2) * 0.5, 0)
			label.Rotation = math.sin(t * 6) * 2
			label.Text = `✨ ¡EVOLUCIONANDO! {math.ceil(remaining)} ✨`
		end)
	end
	state:GetAttributeChangedSignal(Protocol.GiantAttributes.EvolvingUntil):Connect(function()
		stop()
		refresh()
	end)
	refresh()
end

return EvolveView
