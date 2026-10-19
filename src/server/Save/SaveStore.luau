--!strict
--[[
	SaveStore

	Lee y escribe los datos de un jugador en el DataStore con dos reglas:

	1. Reintentos: cada llamada se repite hasta maxAttempts veces con espera
	   creciente (1 s, 2 s, 4 s...) si Roblox falla o no hay presupuesto.
	2. Bloqueo de sesión: el registro guarda qué servidor lo tiene abierto
	   ({ data, lock = { jobId, time } }). Otro servidor no lo abre ni lo
	   escribe mientras el bloqueo esté vivo (se renueva en cada guardado y
	   vence a los lockExpireSeconds si el servidor se cayó). Así nunca se
	   duplican ni se pisan los datos al cambiar de servidor rápido.

	3. Nunca se pisa lo que no se entiende: si el registro guardado no es una
	   tabla (corrupto) o es de una versión del esquema más nueva que la de
	   este servidor (uno nuevo ya escribió), acquire devuelve "error" o
	   "newer" y el jugador no carga; así nada se guarda encima.

	Si el DataStore no está disponible (Studio sin acceso a la API o un
	lugar sin publicar), usa una tabla en memoria con el mismo
	comportamiento: el juego funciona y los datos duran lo que el servidor.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SaveSchema = require(script.Parent.SaveSchema)

local SAVING = Config.Saving

export type Status = "ok" | "locked" | "error" | "newer"
type Record = { data: any, lock: { jobId: string, time: number }? }
type Store = { UpdateAsync: (self: any, key: string, transform: (any) -> any) -> any }

local SaveStore = {}

local memory: { [string]: Record } = {}
local memoryStore: Store = {
	UpdateAsync = function(_, key: string, transform: (any) -> any): any
		local result = transform(memory[key])
		if result ~= nil then
			memory[key] = result
		end
		return result
	end,
}

local store: Store = memoryStore
SaveStore.persistent = false

-- Al cerrar el servidor hay ~25 s para todos: menos reintentos (ver SaveStore.shuttingDown).
local SHUTDOWN_ATTEMPTS = 2
local maxAttempts = SAVING.maxAttempts

local okStore, realStore = pcall(function()
	return DataStoreService:GetDataStore(SAVING.storeName)
end)
if okStore and game.PlaceId ~= 0 then
	store = realStore :: any
	SaveStore.persistent = true
else
	warn(
		"SaveStore: DataStore no disponible (lugar sin publicar o sin acceso a la API); datos en memoria"
	)
end

local function keyFor(userId: number): string
	return `jugador_{userId}`
end

local function lockIsMine(record: Record?): boolean
	local lock = record and record.lock
	return lock == nil
		or lock.jobId == game.JobId
		or os.time() - lock.time > SAVING.lockExpireSeconds
end

-- Llama a UpdateAsync con reintentos. Devuelve false si falló todas las veces.
local function update(key: string, transform: (any) -> any): (boolean, any)
	local waitSeconds = SAVING.retryBaseSeconds
	for attempt = 1, maxAttempts do
		local ok, result = pcall(function()
			return store:UpdateAsync(key, transform)
		end)
		if ok then
			return true, result
		end
		warn(`SaveStore: intento {attempt} falló para {key}: {result}`)
		if attempt < maxAttempts then
			task.wait(waitSeconds)
			waitSeconds *= 2
		end
	end
	return false, nil
end

-- Qué hacer con los datos guardados antes de tomarlos: se revisa dentro de UpdateAsync
-- para no dejar el bloqueo puesto en datos que este servidor no va a cargar.
local function verdict(raw: any): Status
	if raw ~= nil and type(raw) ~= "table" then
		return "error" -- corrupto: no se carga ni se pisa
	end
	local version = if type(raw) == "table" then raw.version else nil
	if type(version) == "number" and version > SaveSchema.VERSION then
		return "newer" -- otro servidor ya corre una versión más nueva del juego
	end
	return "ok"
end

-- Abre los datos de un jugador y los bloquea para este servidor.
function SaveStore.acquire(userId: number): (Status, SaveSchema.SaveData?)
	local status: Status = "locked"
	local ok, record = update(keyFor(userId), function(current: any): any
		local previous = if type(current) == "table" then current :: Record else nil
		if not lockIsMine(previous) then
			status = "locked"
			return nil -- no tocar: otro servidor lo tiene abierto
		end
		status = verdict(if previous then previous.data else nil)
		if status ~= "ok" then
			return nil -- no se toma ni se escribe
		end
		return {
			data = if previous then previous.data else nil,
			lock = { jobId = game.JobId, time = os.time() },
		}
	end)
	if not ok then
		return "error", nil
	end
	if status ~= "ok" or record == nil then
		if status == "error" then
			warn(`SaveStore: los datos de {userId} no son una tabla; no se cargan`)
		end
		return if status == "ok" then "locked" else status, nil
	end
	return "ok", SaveSchema.read((record :: Record).data)
end

-- El servidor se cierra: cada escritura reintenta menos para que todas quepan.
function SaveStore.shuttingDown()
	maxAttempts = math.min(maxAttempts, SHUTDOWN_ATTEMPTS)
end

-- Escribe los datos. release = true suelta el bloqueo (el jugador se fue).
function SaveStore.write(userId: number, data: SaveSchema.SaveData, release: boolean): boolean
	local refused = false
	local ok = update(keyFor(userId), function(current: any): any
		local previous = if type(current) == "table" then current :: Record else nil
		if not lockIsMine(previous) then
			refused = true
			return nil -- otro servidor tomó los datos: no se pisan
		end
		refused = false
		return {
			data = data,
			lock = if release then nil else { jobId = game.JobId, time = os.time() },
		}
	end)
	if refused then
		warn(`SaveStore: los datos de {userId} están abiertos en otro servidor; no se guardó`)
	end
	return ok and not refused
end

return SaveStore
