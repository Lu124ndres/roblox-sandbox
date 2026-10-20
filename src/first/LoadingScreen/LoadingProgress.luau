--!strict
--[[
	LoadingProgress

	Mide la carga real en cinco fases, cada una con su tramo de la barra
	(Look.phaseEnds):
	1. join: llega el juego (game.Loaded).
	2. player: el personaje y el guardado del jugador (atributo DataLoaded del servidor).
	3. island: el servidor terminó de armar el terreno, los decorados y los hábitats
	   (Workspace.MundoListo: los arma después de que entran los jugadores) y el cliente
	   terminó de arrancar lo suyo (LocalPlayer.ClienteListo, lo pone Main.client).
	4. world: el mapa alrededor del personaje (streaming) y sus mallas, texturas,
	   partículas y sonidos (WorldPreload); avanza con cada uno.
	5. assets: las imágenes de la interfaz y los sonidos de Assets, para que no
	   aparezcan en blanco ni mudos al entrar; avanza con cada uno.
	Las fases que no se pueden medir por partes (join, island) se acercan solas a su
	tope según Look.guessSeconds y saltan al terminar.
		start(onPhase) -> Progress   arranca en su propio hilo
		progress.fraction() -> 0..1
		progress.done() -> boolean
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)
local WorldPreload = require(script.Parent.WorldPreload)

export type Phase = "join" | "player" | "island" | "world" | "assets"
export type Progress = {
	fraction: () -> number,
	done: () -> boolean,
}

local ENDS = Look.phaseEnds
local STARTS: { [Phase]: number } = {
	join = 0,
	player = ENDS.join,
	island = ENDS.player,
	world = ENDS.island,
	assets = ENDS.world,
}
local CONTENT_PREFIX = "rbxassetid://"
local POLL_SECONDS = 0.1

local function uploaded(id: string, missing: string): boolean
	return string.sub(id, 1, #CONTENT_PREFIX) == CONTENT_PREFIX and id ~= missing
end

-- Las imágenes de la interfaz (un ID suelto se precarga como imagen) y los sonidos (como
-- Sound sin padre: un ID suelto de sonido falla), sin los que faltan subir.
local function interfaceList(): { any }
	-- Recién ahora (después de game.Loaded) está todo ReplicatedStorage.
	local Assets = require(ReplicatedStorage.Shared.Assets)
	local list: { any } = {}
	for _, id in Assets.UI do
		if uploaded(id, Assets.MISSING) then
			table.insert(list, id)
		end
	end
	for _, id in Assets.Sounds do
		if uploaded(id, Assets.MISSING) then
			local sound = Instance.new("Sound")
			sound.SoundId = id
			table.insert(list, sound)
		end
	end
	return list
end

-- Espera a que el atributo valga true, como mucho Look.waitLimit segundos.
local function waitForFlag(owner: Instance, attribute: string)
	local deadline = os.clock() + Look.waitLimit
	while owner:GetAttribute(attribute) ~= true and os.clock() < deadline do
		task.wait(POLL_SECONDS)
	end
end

local LoadingProgress = {}

function LoadingProgress.start(onPhase: (phase: Phase) -> ()): Progress
	local phase: Phase = "join"
	local phaseStarted = os.clock()
	local done, total = 0, 0 -- assets precargados de la fase (o pasos, en player)
	local finished = false

	local function enter(next: Phase)
		phase, phaseStarted = next, os.clock()
		done, total = 0, 0
		onPhase(next)
	end

	-- Precarga una lista contando cada asset (el contador puede pasarse: una
	-- SurfaceAppearance trae varias texturas).
	local function preload(list: { any })
		total = #list
		-- pcall: si un asset falla (moderado, borrado) la carga sigue igual.
		pcall(function()
			ContentProvider:PreloadAsync(list, function()
				done += 1
			end)
		end)
		done = total
	end

	task.spawn(function()
		local player = Players.LocalPlayer
		enter("join")
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		local Protocol = require(ReplicatedStorage.Shared.Protocol)

		enter("player")
		total = 2
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		done = 1
		waitForFlag(player, Protocol.PlayerAttributes.DataLoaded)

		enter("island")
		waitForFlag(Workspace, Protocol.WorldReadyAttribute)
		waitForFlag(player, Protocol.ClientReadyAttribute)

		enter("world")
		WorldPreload.streamAround(player)
		preload(WorldPreload.collect(Workspace))

		enter("assets")
		preload(interfaceList())
		finished = true
	end)

	return {
		fraction = function(): number
			local from = STARTS[phase]
			local to = ENDS[phase]
			if phase == "join" or phase == "island" then
				local guess = 1 - math.exp(-(os.clock() - phaseStarted) / Look.guessSeconds)
				return from + (to - from) * 0.95 * guess
			end
			local share = if total > 0 then math.min(done / total, 1) else 0
			return from + (to - from) * share
		end,
		done = function(): boolean
			return finished
		end,
	}
end

return table.freeze(LoadingProgress)
