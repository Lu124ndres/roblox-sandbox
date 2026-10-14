--!strict
--[[
	Gifts

	Regalos con Robux. Roblox no deja comprar un producto "para otro", así
	que el cliente avisa antes de abrir la compra (SetGift: qué producto y
	para quién) y el servidor lo anota por GIFT_SECONDS. Si en ese tiempo
	llega el recibo de ese mismo producto, Receipts lo entrega al otro
	jugador. Si cancela la compra, se borra al momento; si el otro ya se
	fue, se lo queda quien pagó (nunca se pierde lo comprado).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Grants = require(script.Parent.Grants)

local GIFT_SECONDS = 120
local MAX_KEY_LENGTH = 40

type Pending = { key: string, target: Player, at: number }

local Gifts = {}

local pending: { [Player]: Pending } = {}

local function onSetGift(buyer: Player, key: unknown, targetUserId: unknown)
	if type(key) ~= "string" or #key > MAX_KEY_LENGTH or type(targetUserId) ~= "number" then
		return
	end
	if not Assets.Products[key] or not Grants.giftable(key) then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == buyer or not PlayerData.isLoaded(target) then
		pending[buyer] = nil
		return
	end
	pending[buyer] = { key = key, target = target, at = os.clock() }
end

-- A quién va la compra `key` de `buyer`: el regalado si hay un regalo
-- anotado para ese producto (y lo consume), si no el mismo comprador.
function Gifts.recipient(buyer: Player, key: string): Player
	local gift = pending[buyer]
	if not gift or gift.key ~= key then
		return buyer
	end
	pending[buyer] = nil
	local fresh = os.clock() - gift.at <= GIFT_SECONDS
	if fresh and gift.target.Parent == Players and PlayerData.isLoaded(gift.target) then
		return gift.target
	end
	return buyer
end

local function keyFor(productId: number): string?
	for key, id in Assets.Products do
		if id ~= 0 and id == productId then
			return key
		end
	end
	return nil
end

function Gifts.init()
	Remotes.SetGift.OnServerEvent:Connect(RateLimit.wrap("SetGift", 2, 4, onSetGift))
	MarketplaceService.PromptProductPurchaseFinished:Connect(
		function(userId: number, productId: number, purchased: boolean)
			local buyer = Players:GetPlayerByUserId(userId)
			local gift = buyer and pending[buyer]
			if buyer and gift and not purchased and gift.key == keyFor(productId) then
				pending[buyer] = nil
			end
		end
	)
	Players.PlayerRemoving:Connect(function(player: Player)
		pending[player] = nil
	end)
end

return Gifts
