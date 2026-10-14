--!strict
--[[
	ShopController

	Abre y cierra MEJORAS (cañas, canastas y botas): con el botón "Mejoras"
	del HUD o con E en el mostrador de la cabaña, donde están las cañas (el
	servidor manda OpenShop). Pide las compras con monedas (BuyUpgrade) y
	muestra el resultado (ShopResult): sonido, aviso y la lista
	actualizada. Con Robux abre el producto <Categoría><nivel> (Purchases).
	Las monedas y los niveles los decide el servidor; aquí solo se muestran.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local HudButtons = require(script.Parent.Parent.Menus.HudButtons)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local ShopWindow = require(script.Parent.ShopWindow)

local COLORS = UIConfig.Colors
local ATTR = Protocol.PlayerAttributes

local ShopController = {}

function ShopController.start(screen: ScreenGui, player: Player, toasts: Toasts.Toasts)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local buyRemote = remotes:WaitForChild(Protocol.Remotes.BuyUpgrade) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(Protocol.Remotes.ShopResult) :: RemoteEvent
	local openRemote = remotes:WaitForChild(Protocol.Remotes.OpenShop) :: RemoteEvent

	local shop = ShopWindow.mount(screen, player, function(category: Upgrades.Category)
		Sounds.play("Click")
		buyRemote:FireServer(category)
	end, function(category: Upgrades.Category, level: number)
		Purchases.promptProduct(`{category}{level}`)
	end, function(key: string, robux: number)
		return Purchases.price(key, false, robux)
	end)
	local window = shop.window

	HudButtons.side("Mejoras", "rod", window.toggle)
	openRemote.OnClientEvent:Connect(function()
		if not window.isOpen() then
			window.open()
		end
	end)

	resultRemote.OnClientEvent:Connect(function(status: unknown, category: unknown, level: unknown)
		if status == "ok" and Upgrades.isCategory(category) and type(level) == "number" then
			local def = Upgrades.list(category :: any)[level]
			Sounds.play("LegendaryCatch")
			Sounds.play("Coins")
			toasts.banner(`¡Compraste {def.name}!`, COLORS.Coins)
		elseif status == "poor" and Upgrades.isCategory(category) and type(level) == "number" then
			local def = Upgrades.list(category :: any)[level + 1]
			local wallet = player:GetAttribute(ATTR.Coins)
			local missing = def.price - (if type(wallet) == "number" then wallet else 0)
			toasts.show(
				`Te faltan {NumberFormat.short(math.max(missing, 0))} monedas`,
				COLORS.Warning
			)
		elseif status == "max" then
			toasts.show("Ya tienes el mejor nivel", COLORS.Success)
		end
		if window.isOpen() then
			shop.refresh()
		end
	end)

	-- Las monedas cambian seguido: se repinta como mucho dos veces por segundo.
	local pending = false
	for _, attribute in { ATTR.Coins, ATTR.Rod, ATTR.Basket, ATTR.Boots } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if pending or not window.isOpen() then
				return
			end
			pending = true
			task.delay(0.5, function()
				pending = false
				if window.isOpen() then
					shop.refresh()
				end
			end)
		end)
	end
end

return ShopController
