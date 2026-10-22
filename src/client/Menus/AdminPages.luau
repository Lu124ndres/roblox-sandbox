--!strict
--[[
	AdminPages

	Lo que lleva cada pestaña del panel admin que cambia al jugador elegido
	(AdminPanel las arma; las del mundo están en AdminPagesWorld):
		player  números, canasta, mejoras de monedas, regalos por tiempo y
		        reiniciar como recién llegado (pide confirmación)
		shop    lo que se compra con Robux: todo de una vez, pases, Poder y
		        Monedas, estanques, pack de inicio y giros
	Cada botón es una orden de server/Admin (nombre y valor).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(script.Parent.Parent.Interface.Style)
local AdminRows = require(script.Parent.AdminRows)

local CARDS = Style.PALETTE.Cards
local MONETIZATION = Config.Monetization

type Button = AdminRows.Button
type Page = AdminRows.Page

local function fillPlayer(page: Page)
	page.section("Números")
	for _, spec in
		{
			{ "Poder", "power" },
			{ "Monedas", "coins" },
			{ "Kills", "kills" },
			{ "Renacimientos", "rebirths" },
		}
	do
		page.row(spec[1], {
			{ text = "Poner", name = spec[2] },
			{ text = "Cero", name = spec[2], value = 0, color = CARDS.Orange },
		}, "número")
	end
	page.section("Canasta y mejoras")
	page.row("Peces", {
		{ text = "Agregar", name = "fish" },
		{ text = "+1.000", name = "fish", value = 1000 },
		{ text = "Vaciar", name = "emptyBasket", value = 0, color = CARDS.Orange },
	}, "cuántos")
	page.row("Mejoras", {
		{ text = "Caña", name = "Rod" },
		{ text = "Canasta", name = "Basket" },
		{ text = "Botas", name = "Boots" },
		{ text = "Todo al máximo", name = "maxUpgrades", value = 0, color = CARDS.Green },
	}, "nivel")
	page.row("Regalos tiempo", {
		{ text = "+10 min", name = "playtime", value = 10 },
		{ text = "+1 h", name = "playtime", value = 60 },
	})
	page.section("Reiniciar", "como jugador nuevo; toca dos veces")
	page.row("Reiniciar", {
		{
			text = "Progreso",
			name = "reset",
			value = "progress",
			color = CARDS.Red,
			confirm = true,
		},
		{
			text = "Todo (cuenta nueva)",
			name = "reset",
			value = "all",
			color = CARDS.Red,
			confirm = true,
		},
	})
end

local function fillShop(page: Page)
	page.section("Todo de una vez", "pases, Poder, Monedas, estanques y pack")
	page.row("Productos", {
		{ text = "Poner todo", name = "allProducts", value = 0, color = CARDS.Green },
		{
			text = "Quitar todo",
			name = "clearProducts",
			value = 0,
			color = CARDS.Red,
			confirm = true,
		},
	})
	page.section("Pases", "toca para poner o quitar")
	local passes: { Button } = {}
	for _, key in MONETIZATION.passOrder do
		local name = MONETIZATION.passes[key].name
		table.insert(passes, { text = name, name = "pass", value = key, color = CARDS.Purple })
	end
	page.row("Pases", passes)
	page.section("Mejoras de Robux", "x2 por nivel")
	for _, key in MONETIZATION.levelOrder do
		local max = #MONETIZATION.levels[key].robux
		page.row(MONETIZATION.levels[key].name, {
			{ text = "Quitar", name = "level", value = `{key}:0`, color = CARDS.Orange },
			{ text = "x2", name = "level", value = `{key}:1` },
			{ text = `x{2 ^ max}`, name = "level", value = `{key}:{max}`, color = CARDS.Green },
		})
	end
	page.section("Otros")
	page.row("Estanques", {
		{ text = "Abrir todos", name = "ponds", value = "all", color = CARDS.Green },
		{ text = "Cerrar", name = "ponds", value = "none", color = CARDS.Orange },
	})
	page.row("Pack de inicio", {
		{ text = "Dármelo", name = "starterPack", value = 0, color = CARDS.Yellow },
	})
	page.row("Ruleta", {
		{ text = "+1 giro", name = "spins", value = 1 },
		{ text = "+5 giros", name = "spins", value = 5 },
	})
end

return table.freeze({ player = fillPlayer, shop = fillShop })
