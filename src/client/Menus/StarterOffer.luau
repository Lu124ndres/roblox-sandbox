--!strict
--[[
	StarterOffer

	Oferta de bienvenida: a los `DELAY_SECONDS` de cada partida, si todavía
	no compró el pack de inicio (atributo PackInicio), se abre una ventana
	con lo que trae y el botón de compra (producto PackInicio). Una vez por
	partida; también está siempre arriba en la TIENDA hasta comprarlo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)
local Window = require(script.Parent.Window)

local DELAY_SECONDS = 150
local PACK = Config.Monetization.starterPack

local StarterOffer = {}

function StarterOffer.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window =
		Window.create(screen, "PackInicio", "¡Oferta de bienvenida!", Vector2.new(560, 430))
	local content = window.content
	local gift = Icons.view(content, "giftPink")
	gift.AnchorPoint = Vector2.new(0.5, 0)
	gift.Position = UDim2.fromScale(0.5, 0)
	gift.Size = UDim2.fromOffset(110, 110)
	local lines = {
		`{NumberFormat.short(PACK.coins)} monedas`,
		`{Upgrades.list("Rod")[PACK.rod].name} y {Upgrades.list("Basket")[PACK.basket].name}`,
		`x2 poder por {PACK.boostMinutes} minutos`,
	}
	for index, text in lines do
		local label = Style.text(
			content,
			`Linea{index}`,
			26,
			if index == 1 then UIConfig.Colors.Coins else nil,
			2.5
		)
		label.Text = `✓ {text}`
		label.Position = UDim2.fromOffset(0, 112 + (index - 1) * 32)
		label.Size = UDim2.new(1, 0, 0, 30)
	end
	local note = Style.text(content, "Nota", 18, UIConfig.Colors.TextMuted, 1.5)
	note.Text = "Solo una vez · Vale mucho más que su precio"
	note.Position = UDim2.fromOffset(0, 212)
	note.Size = UDim2.new(1, 0, 0, 22)
	local buy = Style.button(content, "Comprar", Style.PALETTE.Buy, "")
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.fromScale(0.5, 1)
	buy.Size = UDim2.new(0.6, 0, 0, 64)
	local price = Style.robuxBadge(buy, PACK.robux)
	local label = buy:FindFirstChild("Texto") :: TextLabel
	label.Text = "¡LO QUIERO!"
	buy.Activated:Connect(function()
		Purchases.promptProduct("PackInicio")
	end)
	window.onOpen(function()
		task.spawn(function()
			price.Text = tostring(Purchases.price("PackInicio", false, PACK.robux))
		end)
	end)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.StarterPack):Connect(function()
		if
			player:GetAttribute(Protocol.PlayerAttributes.StarterPack) == true and window.isOpen()
		then
			window.close()
		end
	end)

	task.delay(DELAY_SECONDS, function()
		if player:GetAttribute(Protocol.PlayerAttributes.StarterPack) ~= true then
			window.open()
		end
	end)
end

return StarterOffer
