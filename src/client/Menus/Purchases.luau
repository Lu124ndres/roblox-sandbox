--!strict
--[[
	Purchases

	Abre la ventana de compra de Roblox para un pase o un producto (claves de
	Assets.GamePasses / Assets.Products) y lee su precio real. Mientras el ID
	esté en 0 (juego sin publicar) avisa en vez de abrirla. Lo que se entrega
	lo decide el servidor (Passes, Receipts).
	No abre la compra de giros de la ruleta a quien no se le pueden vender
	objetos al azar (atributo AzarPagadoRestringido, Monetization/RandomPolicy)
	ni el pack de inicio a quien ya lo compró (es una sola vez).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Toasts = require(script.Parent.Parent.Toasts)

local ATTR = Protocol.PlayerAttributes
local STARTER_PACK = "PackInicio"

local Purchases = {}

local toasts: Toasts.Toasts? = nil
local prices: { [string]: number } = {}

function Purchases.start(toastApi: Toasts.Toasts)
	toasts = toastApi
end

local function unavailable(): boolean
	if toasts then
		toasts.show("Disponible cuando el juego esté publicado", UIConfig.Colors.Warning)
	end
	return false
end

function Purchases.promptPass(key: string): boolean
	local id = Assets.GamePasses[key]
	if not id or id == 0 then
		return unavailable()
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, id)
	return true
end

-- ¿Se le puede vender este producto a este jugador? (los giros pagados son un premio al azar)
function Purchases.allowed(key: string): boolean
	local player = Players.LocalPlayer
	if Config.Monetization.spinProducts[key] then
		return player:GetAttribute(ATTR.PaidRandomRestricted) == false
	elseif key == STARTER_PACK then
		return player:GetAttribute(ATTR.StarterPack) ~= true
	end
	return true
end

function Purchases.promptProduct(key: string): boolean
	if not Purchases.allowed(key) then
		return false
	end
	local id = Assets.Products[key]
	if not id or id == 0 then
		return unavailable()
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
	return true
end

-- Precio real en Robux (cacheado), o `fallback` (Config) si aún no hay ID.
function Purchases.price(key: string, isPass: boolean, fallback: number): number
	if prices[key] then
		return prices[key]
	end
	local id = if isPass then Assets.GamePasses[key] else Assets.Products[key]
	if not id or id == 0 then
		return fallback
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(
			id,
			if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product
		)
	end)
	local price = if ok and type(info) == "table" then info.PriceInRobux else nil
	prices[key] = if type(price) == "number" then price else fallback
	return prices[key]
end

return Purchases
