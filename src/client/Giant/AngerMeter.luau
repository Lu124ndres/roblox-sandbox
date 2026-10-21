--!strict
--[[
	AngerMeter

	Fila del enojo dentro del panel de hambre: "Calmada", "Molesta" o
	"¡FURIOSA!" con una barrita que se llena y late. Durante el descanso del
	volcán dice cuánto poder por segundo gana el jugador ahí dentro. Avisa con un cartel y un
	rugido cuando el gigante empieza a enojarse y cuando se enfurece, y
	cuando alguien lo calma. Solo muestra: el enojo lo decide el servidor
	(EstadoGigante.Anger, ver server/GiantMood).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local GiantName = require(script.Parent.Parent.GiantName)
local Toasts = require(script.Parent.Parent.Toasts)
local Ui = require(script.Parent.Parent.Ui)
local HungerPanel = require(script.Parent.Parent.Interface.HungerPanel)
local Style = require(script.Parent.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local ANGER = Config.Giants.anger
local LEFT, TOP = HungerPanel.LEFT, HungerPanel.ANGER_TOP

type Level = "calm" | "angry" | "furious"

local AngerMeter = {}

local function levelFor(anger: number): Level
	if anger >= 1 then
		return "furious"
	elseif anger >= ANGER.angryThreshold then
		return "angry"
	end
	return "calm"
end

local function word(level: Level, female: boolean): string
	local ending = if female then "a" else "o"
	if level == "furious" then
		return `¡FURIOS{string.upper(ending)}!`
	elseif level == "angry" then
		return "Molest" .. ending
	end
	return "Calmad" .. ending
end

function AngerMeter.mount(panel: Frame, toasts: Toasts.Toasts)
	-- Fila debajo de la barra de hambre, a la derecha del retrato.
	local label = Style.text(panel, "Enojo", 15, nil, 1.5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(LEFT + 2, TOP)
	label.Size = UDim2.new(0.34, 0, 0, 15)

	local track = Instance.new("Frame")
	track.Name = "PistaEnojo"
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	track.AnchorPoint = Vector2.new(1, 0)
	track.Position = UDim2.new(1, -2, 0, TOP + 3)
	track.Size = UDim2.new(0.42, 0, 0, 10)
	Style.border(track, 2)
	track.ClipsDescendants = true
	Ui.corner(track, 5)
	track.Parent = panel

	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = COLORS.Calm
	Ui.corner(fill, 5)
	fill.Parent = track

	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local level: Level = "calm"
	local anger = 0

	local function female(): boolean
		return stateFolder:GetAttribute(Protocol.GiantAttributes.Article) == "la"
	end

	-- Fuera de la fase de comer la fila dice cuánto poder da el descanso del volcán.
	local function showRest(phase: unknown): boolean
		local resting = phase ~= nil and phase ~= "feeding"
		track.Visible = not resting
		label.Size = if resting then UDim2.new(1, -LEFT - 4, 0, 15) else UDim2.new(0.34, 0, 0, 15)
		if resting then
			local player = Players.LocalPlayer
			local rest = GiantPool.restMultiplier()
			local training = Config.Gameplay.training
			local perSecond = training.powerPerTick -- igual que GiantCycle.restTick, por segundo
				* Perks.bestPondMultiplier(player)
				* Perks.powerMultiplier(player)
				* rest
				/ training.tickSeconds
			local spinAt = stateFolder:GetAttribute(Protocol.GiantAttributes.RouletteAt)
			local spinning = type(spinAt) == "number"
				and Workspace:GetServerTimeNow() - spinAt
					< Config.Giants.cycle.rouletteSeconds + 1
			label.Text = if phase == "rest" and not spinning
				then `En la guarida del volcán: +{NumberFormat.short(perSecond)} poder/s (x{rest})`
				else ""
			label.TextColor3 = COLORS.Power
			label.TextTransparency = 0
			level = "calm"
		end
		return resting
	end

	local function refresh()
		if showRest(stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)) then
			return
		end
		local value = stateFolder:GetAttribute(Protocol.GiantAttributes.Anger)
		anger = if type(value) == "number" then value else 0
		local nextLevel: Level = levelFor(anger)
		local name = GiantName.current(true)
		if nextLevel ~= level then
			if nextLevel == "furious" then
				Sounds.play("Roar")
				toasts.banner(
					`¡{name} está furios{if female() then "a" else "o"}! ¡Aliméntal{if female()
						then "a"
						else "o"}!`,
					COLORS.Furious
				)
			elseif nextLevel == "angry" and level == "calm" then
				Sounds.play("Roar", nil, 1.15)
				toasts.banner(`{name} tiene hambre y se está enojando`, COLORS.Annoyed)
			elseif nextLevel == "calm" then
				toasts.show(`{name} se calmó`, COLORS.Calm)
			end
			level = nextLevel
		end
		label.Text = word(level, female())
		local color = if level == "furious"
			then COLORS.Furious
			elseif level == "angry" then COLORS.Annoyed
			else COLORS.Calm
		label.TextColor3 = color
		fill.BackgroundColor3 = color
		fill.Size = UDim2.fromScale(math.max(anger, 0.03), 1)
	end

	stateFolder.AttributeChanged:Connect(refresh)
	refresh()

	-- Furioso: la fila late.
	RunService.RenderStepped:Connect(function()
		local beat = if level == "furious" then 0.5 + 0.5 * math.sin(os.clock() * 9) else 0
		label.TextTransparency = beat * 0.45
		fill.BackgroundTransparency = beat * 0.5
	end)
end

return AngerMeter
