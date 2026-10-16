--!strict
--[[
	SpinTimer

	Giros por jugar (Config.Spin.playSpins): cada `everyMinutes` minutos
	conectado en esta sesión (desde que cargó su guardado) suma +1 giro
	guardado de la ruleta, hasta `maxPerSession` por sesión. El atributo
	GiroPorTiempoEn dice el unix del próximo (0 = ya no hay más en esta
	sesión) y el aviso Notice "spinsGained" (1, "play") pone el cartel.
	Al volver a entrar empieza de cero. Lo arranca SpinWheel.init.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)

local ATTR = Protocol.PlayerAttributes
local PLAY = SPIN.playSpins
local CHECK_SECONDS = 1

type State = { nextAt: number, given: number }

local SpinTimer = {}

local states: { [Player]: State } = {}

local function every(): number
	return math.floor(PLAY.everyMinutes * 60)
end

local function check(player: Player, now: number)
	local state = states[player]
	if not state then
		if PlayerData.isLoaded(player) then -- empieza a contar cuando cargó
			states[player] = { nextAt = now + every(), given = 0 }
			player:SetAttribute(ATTR.SpinTimeAt, now + every())
		end
		return
	end
	if state.given >= PLAY.maxPerSession or now < state.nextAt then
		return
	end
	state.given += 1
	PlayerData.edit(player, function(save)
		save.spins += 1
	end)
	state.nextAt = if state.given < PLAY.maxPerSession then state.nextAt + every() else 0
	player:SetAttribute(ATTR.SpinTimeAt, state.nextAt)
	Remotes.Notice:FireClient(player, "spinsGained", 1, "play")
end

function SpinTimer.init()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				check(player, now)
			end
		end
	end)
end

return SpinTimer
