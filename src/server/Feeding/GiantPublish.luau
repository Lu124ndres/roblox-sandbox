--!strict
--[[
	GiantPublish

	La carpeta ReplicatedStorage.EstadoGigante con el estado del gigante como
	atributos (la llena GiantService). Progress cambia con cada lote de peces
	de cada jugador: se publica a lo sumo cada delivery.broadcastSeconds (el
	último valor), salvo cuando quien llama pide publicarlo al instante
	(cruzó una etapa, se llenó, llegó otro gigante).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local DELIVERY = Config.Giants.delivery

local GiantPublish = {}

local folder = Instance.new("Folder")
folder.Name = Protocol.GiantStateFolder

local latestProgress = 0
local progressAt = -math.huge -- última vez que se publicó Progress
local queued = false

function GiantPublish.set(attribute: string, value: any)
	folder:SetAttribute(attribute, value)
end

-- Progress al instante (now) o, si se publicó hace poco, al cumplirse el plazo.
function GiantPublish.progress(value: number, now: boolean)
	latestProgress = value
	local remaining = DELIVERY.broadcastSeconds - (os.clock() - progressAt)
	if now or remaining <= 0 then
		progressAt = os.clock()
		folder:SetAttribute(Protocol.GiantAttributes.Progress, latestProgress)
	elseif not queued then
		queued = true
		task.delay(remaining, function()
			queued = false
			GiantPublish.progress(latestProgress, true)
		end)
	end
end

-- La carpeta aparece para los clientes (después de publicar el estado inicial).
function GiantPublish.show()
	folder.Parent = ReplicatedStorage
end

return GiantPublish
