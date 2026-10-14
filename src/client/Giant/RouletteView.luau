--!strict
--[[
	RouletteView

	La ruleta de monstruos al final del descanso, en el centro y con el
	fondo oscurecido para que nada la tape (los avisos esperan: Toasts.hold).
	Una tira de tarjetas (color e ícono de cada monstruo con su probabilidad)
	pasa rápido y frena dentro del marco dorado del centro; el que sale se
	agranda con destellos. La decide el servidor (EstadoGigante.RuletaResultado,
	RuletaComprador y RuletaInicio); aquí solo se anima.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local RouletteParts = require(script.Parent.RouletteParts)

local ATTR = Protocol.GiantAttributes
local CELL, GAP = RouletteParts.CELL, RouletteParts.GAP
local STRIP_WIDTH, CELLS, RESULT_INDEX = RouletteParts.STRIP_WIDTH, RouletteParts.CELLS, 36
local SPIN_SHARE = 0.72 -- parte del tiempo de la ruleta que gira; el resto muestra el resultado
local GOLD, COLORS = RouletteParts.GOLD, RouletteParts.COLORS

local RouletteView = {}

local function defFor(id: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == id then
			return def
		end
	end
	return nil
end

function RouletteView.start(screen: ScreenGui)
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local parts = RouletteParts.build(screen)
	local shade, panel, track = parts.shade, parts.panel, parts.track
	local result, footer, pop = parts.result, parts.footer, parts.pop

	local playing = 0
	local function play(resultId: string, buyer: string, startedAt: number)
		local chosen = defFor(resultId)
		if not chosen then
			return
		end
		playing += 1
		local mine = playing
		local seconds = Config.Giants.cycle.rouletteSeconds
		local left =
			math.max(1.5, seconds * SPIN_SHARE - (Workspace:GetServerTimeNow() - startedAt))
		Toasts.hold(left + 1.2)
		local list, total = GiantPool.candidates()
		if #list == 0 then
			list, total = { chosen }, chosen.rouletteWeight
		end
		local function percent(def: Config.GiantDef): string
			return if buyer ~= ""
				then ""
				else `{math.round(def.rouletteWeight / math.max(total, 1) * 100)}%`
		end
		track:ClearAllChildren()
		local rng = Random.new(math.floor(startedAt * 10))
		for index = 1, CELLS do
			local def = if index == RESULT_INDEX then chosen else list[rng:NextInteger(1, #list)]
			RouletteParts.card(track, index, def, percent(def))
		end
		result.Text = ""
		footer.Text = if buyer ~= ""
			then `{buyer} lo eligió con Robux`
			else "En el descanso puedes comprar el que quieres que salga"
		local stopX = -((RESULT_INDEX - 1) * (CELL + GAP) - (STRIP_WIDTH - CELL) / 2)
		track.Position = UDim2.fromOffset(0, 0)
		shade.Visible, panel.Visible = true, true
		local spin = TweenService:Create(
			track,
			TweenInfo.new(left, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(stopX, 0) }
		)
		spin:Play()
		task.spawn(function() -- tic cada vez que pasa un monstruo por el marco
			local lastCell = 0
			while spin.PlaybackState == Enum.PlaybackState.Playing and mine == playing do
				local at = math.floor((-track.Position.X.Offset + STRIP_WIDTH / 2) / (CELL + GAP))
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
			Sounds.play("LegendaryCatch")
			result.Text = `¡Sale {chosen.article} {chosen.displayName}!`
			result.TextColor3 = COLORS[chosen.id] or GOLD
			pop.Scale = 0.4
			TweenService:Create(pop, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 })
				:Play()
			task.delay(math.max(1.2, seconds * (1 - SPIN_SHARE)), function()
				if mine == playing then
					shade.Visible, panel.Visible = false, false
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
