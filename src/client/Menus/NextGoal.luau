--!strict
--[[
	NextGoal

	"Siguiente meta" cuando ya terminó el tutorial (mismo lugar que su panel):
	siempre hay algo claro que perseguir, con su barra. Elige entre
		- algo que YA puede hacer: comprar la siguiente caña o renacer
		  (la tarjeta se pone verde);
		- si no, la meta más avanzada entre el siguiente estanque y el siguiente
		  título (monstruos llenados) y la siguiente caña (monedas).
	Se recalcula cada segundo como mucho. Solo lee atributos del jugador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local Titles = require(ReplicatedStorage.Shared.Titles)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards
local TITLES = Config.Social.titles
local PONDS = Config.Progression.ponds

type Goal = { icon: string, text: string, fraction: number, ready: boolean }

local NextGoal = {}

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

local function goals(player: Player): { Goal }
	local list: { Goal } = {}
	local coins = number(player, ATTR.Coins)
	local kills = number(player, ATTR.Kills)
	-- Siguiente estanque que se abre con monstruos (los de Robux no cuentan).
	for index, pond in PONDS do
		if not pond.robuxOnly and not Perks.pondOpen(player, index) then
			table.insert(list, {
				icon = "pond",
				text = `Llena {pond.requiredKills - kills} monstruos más: estanque x{pond.multiplier}`,
				fraction = kills / pond.requiredKills,
				ready = false,
			})
			break
		end
	end
	-- Siguiente caña.
	local rods = Upgrades.list("Rod")
	local nextRod = rods[Upgrades.level(player, "Rod") + 1]
	if nextRod then
		local ready = coins >= nextRod.price
		table.insert(list, {
			icon = "rod",
			text = if ready
				then `¡Ya puedes comprar la {nextRod.name}! (MEJORAS)`
				else `Junta {NumberFormat.short(nextRod.price - coins)} monedas: {nextRod.name}`,
			fraction = coins / math.max(nextRod.price, 1),
			ready = ready,
		})
	end
	-- Siguiente título (por monstruos llenados).
	local title = math.max(number(player, ATTR.Title), 1)
	local nextTitle = TITLES[title + 1]
	if nextTitle then
		table.insert(list, {
			icon = "crown",
			text = `Llena {nextTitle.kills - kills} monstruos más: título {Titles.name(title + 1)}`,
			fraction = kills / nextTitle.kills,
			ready = false,
		})
	end
	-- Renacer.
	local cost = RebirthMath.cost(RebirthMath.count(player))
	if coins >= cost then
		table.insert(list, {
			icon = "arrow",
			text = `¡Puedes RENACER! Alimentas x{RebirthMath.feedMultiplier(
				RebirthMath.count(player) + 1
			)} más rápido`,
			fraction = 1,
			ready = true,
		})
	end
	return list
end

-- Lo que ya puede hacer va primero; si no, la meta más avanzada.
local function pick(list: { Goal }): Goal?
	local best: Goal? = nil
	for _, goal in list do
		if goal.ready then
			return goal
		end
		if not best or goal.fraction > best.fraction then
			best = goal
		end
	end
	return best
end

function NextGoal.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	-- Como el tutorial: en PC en la columna izquierda; en pantallas táctiles abajo
	-- al centro (a la izquierda estorbaría al joystick).
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local card =
		CardParts.card(if touchOnly then screen else Layout.left(), "SiguienteMeta", CARDS.Blue, 12)
	card.LayoutOrder = 21
	if touchOnly then
		card.AnchorPoint = Vector2.new(0.5, 1)
		card.Position = UDim2.new(0.5, -40, 1, -8)
		Layout.scaleWith(card)
	end
	card.Size = UDim2.fromOffset(250, 74)
	card.Visible = false
	local icon: GuiObject? = nil
	local iconKind = ""
	local head = Style.text(card, "Titulo", 16, Color3.fromRGB(255, 225, 90), 2)
	head.Text = "SIGUIENTE META"
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.Position = UDim2.fromOffset(52, 4)
	head.Size = UDim2.new(1, -58, 0, 16)
	local text = Style.text(card, "Texto", 16, nil, 2)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextWrapped = true
	text.Position = UDim2.fromOffset(52, 20)
	text.Size = UDim2.new(1, -58, 0, 30)
	local bar = CardParts.bar(card, CARDS.Green, 14)
	bar.track.Position = UDim2.fromOffset(52, 52)
	bar.track.Size = UDim2.new(1, -60, 0, 16)
	local painted: Color3? = nil

	local function refresh()
		local tutorialDone = number(player, ATTR.Tutorial) >= #Config.Retention.tutorial
		local goal = if tutorialDone and player:GetAttribute(ATTR.DataLoaded) == true
			then pick(goals(player))
			else nil
		card.Visible = goal ~= nil
		if not goal then
			return
		end
		if goal.icon ~= iconKind then
			iconKind = goal.icon
			if icon then
				icon:Destroy()
			end
			local view = Icons.view(card, goal.icon)
			view.Position = UDim2.fromOffset(4, 12)
			view.Size = UDim2.fromOffset(46, 46)
			icon = view
		end
		text.Text = goal.text
		bar.set(goal.fraction, `{math.floor(math.clamp(goal.fraction, 0, 1) * 100)}%`)
		local color = if goal.ready then CARDS.Green else CARDS.Blue
		if color ~= painted then
			painted = color
			CardParts.paint(card, color)
		end
	end

	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.delay(1, function()
			pending = false
			refresh()
		end)
	end
	player.AttributeChanged:Connect(schedule)
	refresh()
end

return NextGoal
