--!strict
--[[
	Receipts

	Productos de Robux (MarketplaceService.ProcessReceipt). Reglas de Roblox
	para no cobrar sin entregar ni entregar dos veces:
		- Si el jugador no está o sus datos no cargaron: NotProcessedYet
		  (Roblox vuelve a intentar cuando entre otra vez).
		- Cada PurchaseId se anota en el guardado de quien pagó; si ya está,
		  no se vuelve a dar nada, pero solo se confirma (PurchaseGranted)
		  después de volver a guardar: un reintento de Roblox tras un guardado
		  fallido no confirma algo que nunca llegó al DataStore.
		- Se entrega, se anota y se guarda en el momento; solo si el guardado
		  se escribió (el de quien pagó y, si era un regalo, el de quien lo
		  recibió) se confirma la compra. Si no: NotProcessedYet.
	Qué da cada producto: Grants. Si era un regalo (Gifts), lo recibe el otro
	jugador y los dos ven el aviso.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local SaveService = require(script.Parent.Parent.Save.SaveService)
local GiantFill = require(script.Parent.GiantFill)
local Gifts = require(script.Parent.Gifts)
local Grants = require(script.Parent.Grants)
local ServerBoost = require(script.Parent.ServerBoost)

local MONETIZATION = Config.Monetization

local Receipts = {}

-- Regalos entregados cuyo guardado todavía no se confirmó: PurchaseId -> quien lo recibió.
local unconfirmed: { [string]: Player } = {}

-- Guarda a quien pagó y, si era un regalo, a quien lo recibió (si sigue en el servidor:
-- si salió, su guardado de salida ya lo llevó). true si todo quedó escrito.
local function persist(player: Player, purchaseId: string): boolean
	local recipient = unconfirmed[purchaseId]
	if recipient and recipient ~= player and recipient.Parent then
		if not SaveService.saveNow(recipient) then
			return false
		end
	end
	if not SaveService.saveNow(player) then
		return false
	end
	unconfirmed[purchaseId] = nil
	return true
end

-- Entrega `key` a `player` con su aviso (también lo usan las pruebas de Studio).
function Receipts.grant(player: Player, key: string, giver: Player?): boolean
	local ok, item = Grants.grant(player, key)
	if ok and item then
		if giver and giver ~= player then
			Remotes.Notice:FireClient(
				player,
				"purchase",
				`¡{giver.DisplayName} te regaló {item}!`
			)
			Remotes.Notice:FireClient(
				giver,
				"purchase",
				`¡Le regalaste {item} a {player.DisplayName}!`
			)
		else
			Remotes.Notice:FireClient(player, "purchase", `¡{item} para siempre!`)
		end
	end
	return ok
end

local function keyFor(productId: number): string?
	for key, id in Assets.Products do
		if id ~= 0 and id == productId then
			return key
		end
	end
	return nil
end

local function process(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local save = if player then PlayerData.read(player) else nil
	if not player or not save then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(save.receipts, purchaseId) then
		-- Ya se entregó: confirmar solo si quedó guardado (un guardado anterior pudo fallar).
		return if persist(player, purchaseId)
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local key = keyFor(receipt.ProductId)
	if not key then
		warn(`Receipts: producto {receipt.ProductId} no está en Assets.Products`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local recipient = Gifts.recipient(player, key)
	local ok, granted = pcall(Receipts.grant, recipient, key, player)
	if not ok or not granted then
		warn(`Receipts: no se pudo entregar {key}: {granted}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PlayerData.edit(player, function(data)
		table.insert(data.receipts, purchaseId)
		while #data.receipts > MONETIZATION.receiptHistory do
			table.remove(data.receipts, 1)
		end
	end)
	if recipient ~= player then
		unconfirmed[purchaseId] = recipient
	end
	-- Si el guardado falla, la compra queda anotada en memoria: el reintento de
	-- Roblox en este servidor no la vuelve a entregar, solo vuelve a guardar.
	if not persist(player, purchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Receipts.init()
	ServerBoost.init()
	GiantFill.init()
	Gifts.init()
	MarketplaceService.ProcessReceipt = process
end

return Receipts
