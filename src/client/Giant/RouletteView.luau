--!strict
--[[
	RouletteView

	La ruleta de monstruos al final del descanso, en el centro de la pantalla
	para todos: una tira de íconos de los monstruos (Interface/Icons) que
	pasa rápido y frena en el que salió, con la probabilidad de cada uno
	abajo (Config: rouletteWeight entre los que tienen inRoulette) o quién lo
	compró. La decide el servidor (EstadoGigante.RuletaResultado,
	RuletaComprador y RuletaInicio); aquí solo se anima.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local Ui = require(script.Parent.Parent.Ui)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local GiantPortrait = require(script.Parent.GiantPortrait)

local ATTR = Protocol.GiantAttributes
local CELL, STRIP_WIDTH, STRIP_HEIGHT = 120, 600, 120
local CELLS, RESULT_INDEX = 40, 34
local SPIN_SHARE = 0.7 -- parte del tiempo de la ruleta que gira; el resto muestra el resultado

local RouletteView = {}

local function defFor(id: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == id then
			return def
		end
	end
	return nil
end

local function cell(parent: Instance, index: number, def: Config.GiantDef)
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.Position = UDim2.fromOffset((index - 1) * CELL, 0)
	box.Size = UDim2.fromOffset(CELL, STRIP_HEIGHT)
	box.Parent = parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Position = UDim2.fromOffset(10, 4)
	image.Size = UDim2.fromOffset(CELL - 20, STRIP_HEIGHT - 32)
	Icons.paint(image, GiantPortrait.iconFor(def.id))
	image.Parent = box
	local name = Style.text(box, "Nombre", 18, nil, 2)
	name.Text = def.displayName
	name.Position = UDim2.fromOffset(2, STRIP_HEIGHT - 28)
	name.Size = UDim2.fromOffset(CELL - 4, 24)
end

function RouletteView.start(screen: ScreenGui)
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local panel = Ui.panel("Ruleta", screen)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.6) -- debajo de los carteles (Toasts)
	panel.Size = UDim2.fromOffset(STRIP_WIDTH + 24, 250)
	panel.Visible = false
	Style.border(panel, 4)
	Layout.scaleWith(panel)
	local title = Style.text(panel, "Titulo", 34, Color3.fromRGB(255, 220, 70), 3)
	title.Position = UDim2.fromOffset(0, 6)
	title.Size = UDim2.new(1, 0, 0, 36)
	local strip = Instance.new("Frame")
	strip.Name = "Tira"
	strip.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	strip.ClipsDescendants = true
	strip.Position = UDim2.fromOffset(12, 46)
	strip.Size = UDim2.fromOffset(STRIP_WIDTH, STRIP_HEIGHT)
	Ui.corner(strip, 12)
	strip.Parent = panel
	local track = Instance.new("Frame")
	track.BackgroundTransparency = 1
	track.Size = UDim2.fromOffset(CELL * CELLS, STRIP_HEIGHT)
	track.Parent = strip
	local pointer = Instance.new("Frame")
	pointer.BackgroundColor3 = Color3.fromRGB(255, 220, 70)
	pointer.AnchorPoint = Vector2.new(0.5, 0)
	pointer.Position = UDim2.new(0.5, 0, 0, 40)
	pointer.Size = UDim2.fromOffset(6, STRIP_HEIGHT + 12)
	pointer.ZIndex = 5
	pointer.Parent = panel
	local footer = Style.text(panel, "Probabilidades", 22, nil, 2)
	footer.Position = UDim2.fromOffset(8, 172)
	footer.Size = UDim2.new(1, -16, 0, 26)
	local result = Style.text(panel, "Resultado", 30, nil, 3)
	result.Position = UDim2.fromOffset(8, 204)
	result.Size = UDim2.new(1, -16, 0, 34)

	local playing = 0
	local function play(resultId: string, buyer: string, startedAt: number)
		local chosen = defFor(resultId)
		if not chosen then
			return
		end
		playing += 1
		local mine = playing
		local list, total = GiantPool.candidates()
		local odds = {}
		for _, def in list do
			table.insert(odds, `{def.displayName} {math.round(def.rouletteWeight / total * 100)}%`)
		end
		footer.Text = if buyer ~= ""
			then `{buyer} lo compró: sale seguro`
			else table.concat(odds, "  ·  ")
		title.Text = "¡RULETA DE MONSTRUOS!"
		result.Text = ""
		track:ClearAllChildren()
		local rng = Random.new(math.floor(startedAt * 10))
		for index = 1, CELLS do
			local def = if index == RESULT_INDEX then chosen else list[rng:NextInteger(1, #list)]
			cell(track, index, def)
		end
		local seconds = Config.Giants.cycle.rouletteSeconds
		local left =
			math.max(1.5, seconds * SPIN_SHARE - (Workspace:GetServerTimeNow() - startedAt))
		local stopX = -((RESULT_INDEX - 1) * CELL - (STRIP_WIDTH - CELL) / 2)
		track.Position = UDim2.fromOffset(0, 0)
		panel.Visible = true
		local spin = TweenService:Create(
			track,
			TweenInfo.new(left, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(stopX, 0) }
		)
		spin:Play()
		task.spawn(function() -- tic cada vez que pasa un monstruo
			local lastCell = 0
			while spin.PlaybackState == Enum.PlaybackState.Playing and mine == playing do
				local at = math.floor(-track.Position.X.Offset / CELL)
				if at ~= lastCell then
					lastCell = at
					Sounds.play("Click", nil, 1.4)
				end
				task.wait()
			end
		end)
		spin.Completed:Once(function()
			if mine ~= playing then
				return
			end
			Sounds.play("StageUp")
			result.Text = `¡Sale {chosen.article} {chosen.displayName}!`
			task.delay(math.max(1.5, seconds * (1 - SPIN_SHARE)), function()
				if mine == playing then
					panel.Visible = false
				end
			end)
		end)
	end

	state:GetAttributeChangedSignal(ATTR.RouletteAt):Connect(function()
		local at = state:GetAttribute(ATTR.RouletteAt)
		local id = state:GetAttribute(ATTR.RouletteResult)
		local buyer = state:GetAttribute(ATTR.RouletteBy)
		if type(at) == "number" and type(id) == "string" then
			-- Quien entra cuando ya terminó no la ve.
			if Workspace:GetServerTimeNow() - at < Config.Giants.cycle.rouletteSeconds then
				play(id, if type(buyer) == "string" then buyer else "", at)
			end
		end
	end)
end

return RouletteView
