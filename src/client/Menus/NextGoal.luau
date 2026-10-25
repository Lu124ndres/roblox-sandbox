--!strict
--[[
	NextGoal

	Avisa la siguiente meta con un globo sobre el botón que la cumple (GoalBadge),
	solo cuando ya terminó el tutorial y cargaron sus datos:
		MEJORAS   la siguiente caña: "!" si ya le alcanzan las monedas, o el % de
		          avance desde NEAR_FRACTION
		RENACER   renacer: "!" si ya puede, o el % de avance (lo que va más atrás
		          entre monedas y poder) desde NEAR_FRACTION
	Los dos globos son independientes: pueden verse a la vez.
	Antes era un panel «SIGUIENTE META» que además mostraba el siguiente estanque y
	el siguiente título; el usuario lo cambió por el aviso en el botón (pedido del
	2026-10-24: el panel no quedaba centrado y se veía fuera de lugar), y estanques
	y títulos ya se ven en los carteles del mapa.
	Se recalcula cada REFRESH_SECONDS como mucho. Solo lee atributos del jugador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local GoalBadge = require(script.Parent.GoalBadge)
local HudButtons = require(script.Parent.HudButtons)

local ATTR = Protocol.PlayerAttributes
local NEAR_FRACTION = 0.75 -- desde aquí "le falta poco" y se ve el % en el botón
local REFRESH_SECONDS = 1

type Goal = GoalBadge.Goal
type Target = { button: string, goal: (player: Player) -> Goal?, badge: GoalBadge.Badge? }

local NextGoal = {}

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

local function rodGoal(player: Player): Goal?
	local nextRod = Upgrades.list("Rod")[Upgrades.level(player, "Rod") + 1]
	if not nextRod then
		return nil -- ya tiene la mejor caña
	end
	local coins = number(player, ATTR.Coins)
	local ready = coins >= nextRod.price
	return {
		text = if ready
			then `¡Ya puedes comprar la {nextRod.name}!`
			else `Te faltan {NumberFormat.short(nextRod.price - coins)} monedas para la {nextRod.name}`,
		fraction = coins / math.max(nextRod.price, 1),
		ready = ready,
	}
end

-- Renacer pide monedas y poder; el texto dice lo que falta de cada uno.
local function rebirthGoal(player: Player): Goal?
	local coins, power = number(player, ATTR.Coins), number(player, ATTR.Power)
	local rebirths = RebirthMath.count(player)
	local cost, powerCost = RebirthMath.cost(rebirths), RebirthMath.powerCost(rebirths)
	local ready = RebirthMath.canRebirth(coins, power, rebirths)
	local missingCoins = NumberFormat.short(math.max(cost - coins, 0))
	local missingPower = NumberFormat.short(math.max(powerCost - power, 0))
	local text = if ready
		then `¡Ya puedes renacer! Alimentarás {RebirthMath.speedText(rebirths + 1)} peces/s`
		elseif
			coins < cost and power < powerCost
		then `Para renacer: te faltan {missingCoins} monedas y {missingPower} poder`
		elseif coins < cost then `Para renacer: te faltan {missingCoins} monedas`
		else `Para renacer: te falta {missingPower} poder`
	return {
		text = text,
		fraction = math.min(coins / math.max(cost, 1), power / math.max(powerCost, 1)),
		ready = ready,
	}
end

function NextGoal.start(_screen: ScreenGui)
	local player = Players.LocalPlayer
	local targets: { Target } = {
		{ button = "Mejoras", goal = rodGoal },
		{ button = "Renacer", goal = rebirthGoal },
	}

	local function refresh()
		local tutorialDone = number(player, ATTR.Tutorial) >= #Config.Retention.tutorial
		local active = tutorialDone and player:GetAttribute(ATTR.DataLoaded) == true
		for _, target in targets do
			-- El globo se arma al encontrar el botón (su módulo puede ponerlo después).
			if not target.badge then
				local button = HudButtons.sideButton(target.button)
				target.badge = if button then GoalBadge.mount(button) else nil
			end
			local badge = target.badge
			if badge then
				local goal = if active then target.goal(player) else nil
				local near = goal and (goal.ready or goal.fraction >= NEAR_FRACTION)
				badge.set(if near then goal else nil)
			end
		end
	end

	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.delay(REFRESH_SECONDS, function()
			pending = false
			refresh()
		end)
	end
	player.AttributeChanged:Connect(schedule)
	refresh()
end

return NextGoal
