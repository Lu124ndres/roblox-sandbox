--!strict
--[[
	HungerBar

	Barra de hambre del gigante actual, arriba al centro y compacta: la comida
	que lleva sobre el total en grande, el nombre y la etapa. Lee el estado de
	ReplicatedStorage.EstadoGigante (atributos que publica el servidor).

	La barra marca las 4 etapas del gigante (empiezan en 0, 25, 50 y 75 %):
	marcas en la barra, un color por etapa y avisos al pasar de etapa y al
	llenarse. Al llenarse muestra la despedida, la cuenta regresiva del
	descanso del volcán y la llegada del siguiente gigante.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local GiantName = require(script.Parent.GiantName)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Ui = require(script.Parent.Ui)
local Layout = require(script.Parent.Interface.Layout)
local Style = require(script.Parent.Interface.Style)

local ATTR = Protocol.GiantAttributes
local THRESHOLDS = Config.Giants.stageThresholds
local PANEL_WIDTH = 440
local STAGE_COLORS = UIConfig.HungerStageColors

local HungerBar = {}

function HungerBar.mount(
	screen: ScreenGui,
	onStageReached: (stage: number) -> (),
	onFull: () -> ()
): Frame
	-- Arriba al centro, compacta: nombre y etapa, la barra con la comida grande
	-- ("1,250 / 2,500"), la fila del enojo (AngerMeter) y los atajos para llenarlo.
	local panel = Instance.new("Frame")
	panel.Name = "Hambre"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 8)
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, 150)
	panel.Parent = screen
	Layout.scaleWith(panel)

	local title = Style.text(panel, "Nombre", 28)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(0.62, 0, 0, 30)

	local detail = Style.text(panel, "Etapa", 22, Color3.fromRGB(255, 220, 70))
	detail.TextXAlignment = Enum.TextXAlignment.Right
	detail.AnchorPoint = Vector2.new(1, 0)
	detail.Position = UDim2.new(1, -4, 0, 4)
	detail.Size = UDim2.new(0.38, 0, 0, 24)
	detail.Rotation = 4

	local track = Instance.new("Frame")
	track.Name = "Pista"
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	track.Position = UDim2.fromOffset(0, 32)
	track.Size = UDim2.new(1, 0, 0, 42)
	Ui.corner(track, 12)
	Style.border(track, 4)
	track.Parent = panel
	local clip = Instance.new("Frame")
	clip.Name = "Recorte"
	clip.BackgroundTransparency = 1
	clip.Size = UDim2.fromScale(1, 1)
	clip.ClipsDescendants = true
	clip.Parent = track
	Ui.corner(clip, 12)

	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = STAGE_COLORS[1]
	Ui.corner(fill, 12)
	Style.gradient(fill, Color3.new(1, 1, 1))
	fill.Parent = clip

	for index = 2, #THRESHOLDS do
		local tick = Instance.new("Frame")
		tick.Name = `Marca{index}`
		tick.BackgroundColor3 = Style.OUTLINE
		tick.BackgroundTransparency = 0.3
		tick.BorderSizePixel = 0
		tick.AnchorPoint = Vector2.new(0.5, 0)
		tick.Position = UDim2.fromScale(THRESHOLDS[index], 0)
		tick.Size = UDim2.new(0, 3, 1, 0)
		tick.ZIndex = 2
		tick.Parent = clip
	end

	local amount = Style.text(track, "Cantidad", 34, nil, 3)
	amount.AnchorPoint = Vector2.new(0.5, 0.5)
	amount.Position = UDim2.fromScale(0.5, 0.5)
	amount.Size = UDim2.new(1, -16, 1, -4)
	amount.ZIndex = 4

	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local currentId: string? = nil
	local lastStage = 1
	local wasFull = false

	-- Fuera de la fase de comer, el panel cuenta la despedida, el descanso y la llegada.
	local function showPhase(phase: string)
		local name = GiantName.current(true)
		local endsAt = stateFolder:GetAttribute(ATTR.PhaseEndsAt)
		local left = if type(endsAt) == "number"
			then math.max(0, endsAt - Workspace:GetServerTimeNow())
			else 0
		local fraction, color = 0, UIConfig.Colors.Power
		if phase == "rest" then
			title.Text = "Descanso del volcán"
			detail.Text = "x2 entrenando"
			amount.Text = string.format("%d:%02d", left // 60, math.floor(left % 60))
			fraction = left / Config.Giants.cycle.restSeconds
		elseif phase == "farewell" then
			title.Text = `¡{name} se llenó!`
			detail.Text = ""
			amount.Text = "¡LLENO!"
			fraction, color = 1, UIConfig.Colors.Feeding
		else
			title.Text = `¡Llega {GiantName.current()}!`
			detail.Text = ""
			amount.Text = "..."
		end
		TweenService:Create(fill, UIConfig.Tweens.BarFill, {
			Size = UDim2.fromScale(fraction, 1),
			BackgroundColor3 = color,
		}):Play()
	end

	local function refresh()
		local id = stateFolder:GetAttribute(ATTR.Id)
		local name = stateFolder:GetAttribute(ATTR.DisplayName)
		local multiplier = stateFolder:GetAttribute(ATTR.Multiplier)
		local progress = stateFolder:GetAttribute(ATTR.Progress)
		if type(id) ~= "string" or type(name) ~= "string" or type(progress) ~= "number" then
			return
		end
		local stage = GiantStages.stageFor(progress)
		local full = progress >= 1
		if id ~= currentId then
			currentId = id
			lastStage, wasFull = stage, full -- al entrar o cambiar de gigante no se anuncia nada
		else
			if stage > lastStage then
				onStageReached(stage)
			end
			if full and not wasFull then
				onFull()
			end
			lastStage, wasFull = stage, full
		end

		local phase = stateFolder:GetAttribute(ATTR.Phase)
		if phase == "rest" or phase == "farewell" or phase == "arriving" then
			showPhase(phase)
			return
		end
		title.Text = `{name}  x{multiplier}`
		detail.Text = `Etapa {stage}/{GiantStages.count}`
		local total = GiantStages.foodFor(id)
		amount.Text = `{NumberFormat.big(math.floor(progress * total))} / {NumberFormat.big(total)}`
		local color = STAGE_COLORS[math.min(stage, #STAGE_COLORS)]
		TweenService:Create(fill, UIConfig.Tweens.BarFill, {
			Size = UDim2.fromScale(progress, 1),
			BackgroundColor3 = color,
		}):Play()
	end

	stateFolder.AttributeChanged:Connect(refresh)
	refresh()
	task.spawn(function() -- la cuenta regresiva del descanso
		while true do
			task.wait(0.5)
			if stateFolder:GetAttribute(ATTR.Phase) == "rest" then
				refresh()
			end
		end
	end)
	return panel
end

return HungerBar
