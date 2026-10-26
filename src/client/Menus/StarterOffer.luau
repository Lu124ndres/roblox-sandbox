--!strict
--[[
	StarterOffer

	Oferta de bienvenida: `DELAY_SECONDS` después de terminar el tutorial (o de
	entrar, si ya lo había terminado), si todavía no compró el pack de inicio
	(atributo PackInicio), se abre esta ventana, más chica que las demás para
	no tapar toda la pantalla (pedido del usuario el 2026-10-21). Se abre sola
	una sola vez en la vida del jugador: el servidor anota cuándo (StarterSeen,
	atributo PackVistoEn) y desde ahí queda su atajo con cuenta regresiva
	arriba del menú (StarterShortcut).
	Arriba el regalo sobre rayos, el título y la etiqueta de descuento; en el
	medio cinco tarjetas con lo que trae (monedas, caña, canasta, botas con
	sus íconos de MEJORAS y x2 poder); abajo lo que costaría por separado
	(precios en Robux de MEJORAS) tachado y el botón de lava que late, con
	una gema a cada lado. También está siempre en la TIENDA hasta comprarlo. Las piezas de piedra salen de StarterParts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)
local ShopStone = require(script.Parent.ShopStone)
local StarterParts = require(script.Parent.StarterParts)
local StarterShortcut = require(script.Parent.StarterShortcut)
local Window = require(script.Parent.Window)

local DELAY_SECONDS = 60
local SHRINK = 0.7 -- parte de la pantalla que ocupa, comparada con las demás ventanas
local ATTR = Protocol.PlayerAttributes
local TUTORIAL_STEPS = #Config.Retention.tutorial
local PACK = Config.Monetization.starterPack
local ROBUX = Config.Monetization.upgradeRobux
local CARDS = Style.PALETTE.Cards
local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

type Item = {
	color: Color3,
	title: string,
	detail: string,
	gear: string?,
	level: number?,
	icon: string?,
}

local StarterOffer = {}

-- Lo que costarían las mejoras del pack compradas con Robux en MEJORAS.
local function separateRobux(): number
	local function price(category: string, level: number): number
		local list = ROBUX[category]
		return if list and list[level] then list[level] else 0
	end
	return price("Rod", PACK.rod) + price("Basket", PACK.basket) + price("Boots", PACK.boots)
end

local function gearItem(category: Upgrades.Category, level: number, color: Color3): Item
	return {
		color = color,
		title = Upgrades.list(category)[level].name,
		detail = `Nivel {level}`,
		gear = category,
		level = level,
	}
end

function StarterOffer.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "PackInicio", "¡Oferta!", Vector2.new(820, 500))
	window.setShrink(SHRINK)
	local content = window.content
	local separate = separateRobux()
	local function discountFor(robuxPrice: number): number
		return if separate > robuxPrice then math.floor((1 - robuxPrice / separate) * 100) else 0
	end
	local setDiscount = StarterParts.header(content, discountFor(PACK.robux))
	local items: { Item } = {
		{
			color = CARDS.Yellow,
			title = NumberFormat.short(PACK.coins),
			detail = "monedas",
			icon = "coin",
		},
		gearItem("Rod", PACK.rod, CARDS.Blue),
		gearItem("Basket", PACK.basket, CARDS.Green),
		gearItem("Boots", PACK.boots, CARDS.Cyan),
		{
			color = CARDS.Purple,
			title = "x2 poder",
			detail = `{PACK.boostMinutes} minutos`,
			icon = "bolt",
		},
	}
	for index, item in items do
		StarterParts.card(content, index, item)
	end

	local value = Style.text(content, "Valor", 24, Color3.fromRGB(255, 214, 200), 2)
	value.RichText = true
	value.Position = UDim2.fromOffset(0, 310)
	value.Size = UDim2.new(1, 0, 0, 28)
	-- Con el precio que cobra Roblox (el del botón), no el de Config: si no, no coinciden
	local function showValue(robuxPrice: number)
		value.Text = `Solo el equipo, por separado: <s>{separate} R$</s>   ¡Hoy {robuxPrice} R$!`
		value.Visible = separate > robuxPrice
		setDiscount(discountFor(robuxPrice))
	end
	showValue(PACK.robux)

	local buy = Style.lavaButton(content, "Comprar", "¡LO QUIERO!")
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 1, -8)
	buy.Size = UDim2.new(0.56, 0, 0, 78)
	local label = buy:FindFirstChild("Texto") :: TextLabel
	label.Position = UDim2.new(0.04, 0, 0, 8)
	label.Size = UDim2.new(0.54, 0, 1, -16)
	local robux = ShopStone.robuxIcon(buy)
	robux.AnchorPoint = Vector2.new(0, 0.5)
	robux.Position = UDim2.fromScale(0.6, 0.5)
	robux.Size = UDim2.fromScale(0.12, 0.58)
	local price = Style.text(buy, "Precio", 40, nil, 3)
	price.Text = tostring(PACK.robux)
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.Position = UDim2.fromScale(0.73, 0.14)
	price.Size = UDim2.fromScale(0.23, 0.72)
	Kit.gold(price)
	Kit.gems(buy, 46)
	local beat = Instance.new("UIScale")
	beat.Parent = buy
	TweenService:Create(beat, PULSE, { Scale = 1.06 }):Play()
	buy.Activated:Connect(function()
		Purchases.promptProduct("PackInicio")
	end)
	window.onOpen(function()
		task.spawn(function()
			local robuxPrice = Purchases.price("PackInicio", false, PACK.robux)
			price.Text = tostring(robuxPrice)
			showValue(robuxPrice)
		end)
	end)
	player:GetAttributeChangedSignal(ATTR.StarterPack):Connect(function()
		if player:GetAttribute(ATTR.StarterPack) == true and window.isOpen() then
			window.close()
		end
	end)

	StarterShortcut.mount(window.open)

	-- El minuto empieza al terminar el tutorial (el servidor cuenta los pasos hechos
	-- en el atributo Tutorial). Si ya se le abrió solo alguna vez, no se abre más.
	local seenRemote = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
		:WaitForChild(Protocol.Remotes.StarterSeen) :: RemoteEvent
	local scheduled = false
	local function due(): boolean
		local steps = player:GetAttribute(ATTR.Tutorial)
		local seenAt = player:GetAttribute(ATTR.StarterSeenAt)
		return player:GetAttribute(ATTR.DataLoaded) == true
			and type(steps) == "number"
			and steps >= TUTORIAL_STEPS
			and (seenAt == nil or seenAt == 0)
			and player:GetAttribute(ATTR.StarterPack) ~= true
	end
	local function schedule()
		if scheduled or not due() then
			return
		end
		scheduled = true
		task.delay(DELAY_SECONDS, function()
			Window.waitClosed()
			if due() then
				window.open()
				seenRemote:FireServer()
			end
		end)
	end
	player:GetAttributeChangedSignal(ATTR.Tutorial):Connect(schedule)
	player:GetAttributeChangedSignal(ATTR.DataLoaded):Connect(schedule)
	schedule()
end

return StarterOffer
