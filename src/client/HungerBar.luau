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

	El total de comida lo publica el servidor (atributo Food: crece con los
	jugadores activos); si aún no llegó, se usa el de Config. Los cambios se
	juntan y se pintan como mucho 10 veces por segundo (cada pez cambia
	Progress y el enojo), y la barra solo se anima si algo cambió.
	Las piezas del panel las arma Interface/HungerPanel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local GiantName = require(script.Parent.GiantName)
local GiantPortrait = require(script.Parent.Giant.GiantPortrait)
local HungerPanel = require(script.Parent.Interface.HungerPanel)

local ATTR = Protocol.GiantAttributes
local STAGE_COLORS = UIConfig.HungerStageColors
local REFRESH_SECONDS = 0.1 -- 10 veces por segundo como mucho
-- Se lee con cuidado: si Protocol aún no tiene Food, el atributo se llama igual.
local FOOD_ATTRIBUTE: string = (ATTR :: any).Food or "Food"

-- Atributos de EstadoGigante que cambian lo que muestra la barra (no el enojo).
local WATCHED: { [string]: boolean } = {
	[ATTR.Id] = true,
	[ATTR.DisplayName] = true,
	[ATTR.Article] = true,
	[ATTR.Multiplier] = true,
	[ATTR.Progress] = true,
	[ATTR.Phase] = true,
	[ATTR.PhaseEndsAt] = true,
	[FOOD_ATTRIBUTE] = true,
}

local HungerBar = {}

function HungerBar.mount(
	screen: ScreenGui,
	onStageReached: (stage: number) -> (),
	onFull: () -> ()
): Frame
	-- Arriba al centro, compacta: retrato, nombre y etapa, la barra con la comida grande
	-- ("1,250 / 2,500"), la fila del enojo (AngerMeter) y los atajos para llenarlo.
	local parts = HungerPanel.build(screen)
	local panel, title, detail, amount, fill =
		parts.panel, parts.title, parts.detail, parts.amount, parts.fill
	local portrait = GiantPortrait.attach(parts.portrait)

	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local currentId: string? = nil
	local lastStage = 1
	local wasFull = false
	local shownFraction, shownColor = -1, Color3.new()

	-- Anima la barra solo si cambia (cada animación nueva reemplaza a la anterior).
	local function setFill(fraction: number, color: Color3)
		if math.abs(fraction - shownFraction) < 0.0005 and color == shownColor then
			return
		end
		shownFraction, shownColor = fraction, color
		TweenService:Create(fill, UIConfig.Tweens.BarFill, {
			Size = UDim2.fromScale(fraction, 1),
			BackgroundColor3 = color,
		}):Play()
	end

	-- Comida total del gigante actual: la que publica el servidor, o la de Config.
	local function totalFood(id: string): number
		local food = stateFolder:GetAttribute(FOOD_ATTRIBUTE)
		if type(food) == "number" and food > 0 then
			return food
		end
		return GiantStages.foodFor(id)
	end

	-- Fuera de la fase de comer, el panel cuenta la despedida, el descanso y la llegada.
	local restTotal = 0 -- lo que duraba este descanso al empezar (varía con los jugadores)
	local function showPhase(phase: string)
		if phase ~= "rest" then
			restTotal = 0
		end
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
			restTotal = math.max(restTotal, left)
			fraction = left / math.max(restTotal, 1)
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
		setFill(fraction, color)
	end

	local function refresh()
		local id = stateFolder:GetAttribute(ATTR.Id)
		local name = stateFolder:GetAttribute(ATTR.DisplayName)
		local progress = stateFolder:GetAttribute(ATTR.Progress)
		if type(id) ~= "string" or type(name) ~= "string" or type(progress) ~= "number" then
			return
		end
		portrait.set(id)
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
		title.Text = name
		detail.Text = `Etapa {stage}/{GiantStages.count}`
		local total = totalFood(id)
		amount.Text = `{NumberFormat.big(math.floor(progress * total))} / {NumberFormat.big(total)}`
		setFill(progress, STAGE_COLORS[math.min(stage, #STAGE_COLORS)])
	end

	-- Varios cambios seguidos (un lote de peces) se pintan una sola vez.
	local queued = false
	stateFolder.AttributeChanged:Connect(function(attribute: string)
		if queued or not WATCHED[attribute] then
			return
		end
		queued = true
		task.delay(REFRESH_SECONDS, function()
			queued = false
			refresh()
		end)
	end)
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
