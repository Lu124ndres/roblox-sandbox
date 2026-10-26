--!strict
--[[
	LikeGoal

	Meta de likes de la actualización (pedido del usuario el 2026-10-26): cada
	POLL_SECONDS lee los likes del juego y los publica en ReplicatedStorage
	(carpeta MetaLikes: Likes, Meta y Codigo) para el letrero de la plaza
	(client/Menus/LikeSign). La meta y su premio son el código de CodeList con
	`likes` que no haya vencido; su nombre solo se publica al llegar, y
	Social/Codes no lo acepta antes (LikeGoal.locked).
	Roblox no deja leer los votos desde el juego, así que se piden a la API
	pública de juegos por un proxy (roproxy.com). Si falla, Likes queda en -1 y
	el letrero muestra solo la meta; el código se puede abrir a mano con
	`unlocked = true`. Requiere "Permitir solicitudes HTTP" en los ajustes del juego.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local CodeList = require(script.Parent.CodeList)

local URL = "https://games.roproxy.com/v1/games/votes?universeIds=%d"
local POLL_SECONDS = 300
local FIRST_POLL_JITTER = 20 -- los servidores no piden todos a la vez
local ATTR = Protocol.LikeGoalAttributes

local LikeGoal = {}

local likes = -1 -- el máximo leído en este servidor (-1 = todavía no se sabe)

-- La meta activa: el código con `likes` que no venció (nil si no hay).
local function active(): (string?, CodeList.Code?)
	for key, code in CodeList do
		if code.likes and not (code.expires and os.time() > code.expires) then
			return key, code
		end
	end
	return nil, nil
end

-- ¿Este código todavía no se puede canjear porque falta llegar a su meta?
function LikeGoal.locked(code: CodeList.Code): boolean
	local goal = code.likes
	return goal ~= nil and not code.unlocked and likes < goal
end

local function fetch(): number?
	if game.GameId == 0 then
		return nil -- lugar sin publicar
	end
	local ok, body = pcall(HttpService.GetAsync, HttpService, string.format(URL, game.GameId))
	if not ok then
		return nil
	end
	local decoded, data = pcall(HttpService.JSONDecode, HttpService, body)
	local entry = decoded and type(data) == "table" and type(data.data) == "table" and data.data[1]
	return if type(entry) == "table" and type(entry.upVotes) == "number" then entry.upVotes else nil
end

local function publish(folder: Folder)
	local key, code = active()
	folder:SetAttribute(ATTR.Likes, likes)
	folder:SetAttribute(ATTR.Goal, if code and code.likes then code.likes else 0)
	folder:SetAttribute(ATTR.Code, if key and code and not LikeGoal.locked(code) then key else "")
end

function LikeGoal.init()
	local folder = Instance.new("Folder")
	folder.Name = Protocol.LikeGoalFolder
	publish(folder)
	folder.Parent = ReplicatedStorage
	task.spawn(function()
		task.wait(math.random() * FIRST_POLL_JITTER)
		while true do
			local read = fetch()
			if read then
				likes = math.max(likes, read) -- un "ya no me gusta" no vuelve a cerrar el código
			end
			publish(folder)
			task.wait(POLL_SECONDS)
		end
	end)
end

return LikeGoal
