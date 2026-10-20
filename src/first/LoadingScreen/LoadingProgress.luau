--!strict
--[[
	LoadingProgress

	Mide la carga real en cuatro fases, cada una con su tramo de la barra
	(Look.phaseEnds):
	1. join: llega el juego (game.Loaded). No se puede medir por partes, así que la
	   barra se acerca sola a su tope según joinGuessSeconds y salta al llegar.
	2. player: el personaje y el guardado del jugador (atributo DataLoaded del servidor).
	3. world: el mapa alrededor del personaje y sus mallas, texturas, partículas y
	   sonidos (WorldPreload); avanza con cada uno.
	4. assets: las imágenes de la interfaz y los sonidos de Assets, para que no
	   aparezcan en blanco ni mudos al entrar; avanza con cada uno.
		start(onPhase) -> Progress   arranca en su propio hilo
		progress.fraction(transcurrido) -> 0..1
		progress.done() -> boolean
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)
local WorldPreload = require(script.Parent.WorldPreload)

export type Phase = "join" | "player" | "world" | "assets"
export type Progress = {
	fraction: (elapsed: number) -> number,
	done: () -> boolean,
}

local ENDS = Look.phaseEnds
local CONTENT_PREFIX = "rbxassetid://"

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

local function waitForPlayer(player: Player, onStep: () -> ())
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	onStep()
	local Protocol = require(ReplicatedStorage.Shared.Protocol)
	local attribute = Protocol.PlayerAttributes.DataLoaded
	while player:GetAttribute(attribute) ~= true do
		player:GetAttributeChangedSignal(attribute):Wait()
	end
	onStep()
end

local LoadingProgress = {}

function LoadingProgress.start(onPhase: (phase: Phase) -> ()): Progress
	local phase: Phase = "join"
	local done, total = 0, 0
	local playerSteps = 0
	local finished = false

	-- Precarga una lista contando cada asset (el contador puede pasarse: una
	-- SurfaceAppearance trae varias texturas).
	local function preload(list: { any })
		done, total = 0, #list
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
		onPhase("join")
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end

		phase = "player"
		onPhase("player")
		waitForPlayer(player, function()
			playerSteps += 1
		end)

		phase = "world"
		onPhase("world")
		WorldPreload.streamAround(player)
		preload(WorldPreload.collect(workspace))

		phase = "assets"
		onPhase("assets")
		preload(interfaceList())
		finished = true
	end)

	return {
		fraction = function(elapsed: number): number
			local share = if total > 0 then math.min(done / total, 1) else 0
			if phase == "join" then
				local guess = 1 - math.exp(-elapsed / Look.joinGuessSeconds)
				return ENDS.join * 0.95 * guess
			elseif phase == "player" then
				return ENDS.join + (ENDS.player - ENDS.join) * (playerSteps / 2)
			elseif phase == "world" then
				return ENDS.player + (ENDS.world - ENDS.player) * share
			end
			return ENDS.world + (ENDS.assets - ENDS.world) * share
		end,
		done = function(): boolean
			return finished
		end,
	}
end

return table.freeze(LoadingProgress)
