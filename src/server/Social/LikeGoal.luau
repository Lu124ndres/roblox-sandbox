--!strict
--[[
	LikeGoal

	Meta de likes de la actualización (pedido del usuario el 2026-10-26): los
	likes los publica en ReplicatedStorage (carpeta MetaLikes: Likes, Meta y
	Codigo) para el letrero de la plaza (client/Menus/LikeSign). La meta y su
	premio son el código de CodeList con `likes` que no haya vencido; su nombre
	solo se publica al llegar, y Social/Codes no lo acepta antes (LikeGoal.locked).
	Roblox no deja leer los votos desde el juego, así que se piden a un
	intermediario propio en Cloudflare (`WORKER_URL`, código y pasos en
	tools/likes-worker/; no un proxy público). Si no hay worker o falla, vale el
	número que pone el admin desde el panel (orden `likes`, AdminFun; para todos
	los servidores con "g:likes"), guardado en el DataStore MetaLikes. Cada
	servidor relee cada POLL_SECONDS. Sin número (-1), el letrero muestra solo la
	meta; el código también se abre con `unlocked = true`. El worker necesita
	"Permitir solicitudes HTTP" en los ajustes del juego.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local CodeList = require(script.Parent.CodeList)

-- Dirección del worker de tools/likes-worker ("" = solo el número del panel).
local WORKER_URL = ""
local STORE_NAME = "MetaLikes"
local STORE_KEY = "likes"
local POLL_SECONDS = 300
local FIRST_POLL_JITTER = 20 -- los servidores no leen todos a la vez
local MAX_LIKES = 1e9
local ATTR = Protocol.LikeGoalAttributes

local LikeGoal = {}

local likes = -1 -- el último número puesto por el admin (-1 = todavía no hay)
local folder: Folder? = nil

local function store(): DataStore?
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	return if ok then result else nil
end

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

local function publish(target: Folder)
	local key, code = active()
	target:SetAttribute(ATTR.Likes, likes)
	target:SetAttribute(ATTR.Goal, if code and code.likes then code.likes else 0)
	target:SetAttribute(ATTR.Code, if key and code and not LikeGoal.locked(code) then key else "")
end

-- Orden del admin: los likes del juego ahora. Los guarda para los servidores que abran
-- después (con "g:likes" cada servidor escribe el mismo número: son pocas escrituras).
function LikeGoal.set(value: number): boolean
	likes = math.clamp(math.floor(value), 0, MAX_LIKES)
	if folder then
		publish(folder)
	end
	local data = store()
	local ok = data ~= nil and pcall(data.SetAsync, data, STORE_KEY, likes)
	return ok == true
end

local function sane(value: unknown): number?
	return if type(value) == "number"
			and value == value
			and value >= 0
			and value < MAX_LIKES
		then value
		else nil
end

-- Los likes reales, del worker (nil si no hay worker o falla).
local function fetch(): number?
	if WORKER_URL == "" then
		return nil
	end
	local ok, body = pcall(HttpService.GetAsync, HttpService, WORKER_URL)
	if not ok then
		return nil
	end
	local decoded, data = pcall(HttpService.JSONDecode, HttpService, body)
	return if decoded and type(data) == "table" then sane(data.likes) else nil
end

local function read(): number?
	local data = store()
	if not data then
		return nil
	end
	local ok, value = pcall(data.GetAsync, data, STORE_KEY)
	return if ok then sane(value) else nil
end

function LikeGoal.init()
	local created = Instance.new("Folder")
	created.Name = Protocol.LikeGoalFolder
	folder = created
	publish(created)
	created.Parent = ReplicatedStorage
	task.spawn(function()
		task.wait(math.random() * FIRST_POLL_JITTER)
		while true do
			local saved = fetch() or read()
			if saved then
				likes = saved
			end
			publish(created)
			task.wait(POLL_SECONDS)
		end
	end)
end

return LikeGoal
