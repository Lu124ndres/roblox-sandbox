--!strict
--[[
	AdminPages

	Lo que lleva cada pestaña del panel admin (AdminPanel las arma):
		player  números, canasta, mejoras, velocidad, pases, regalos, mover y
		        reiniciar como recién llegado (pide confirmación)
		giants  cada monstruo con un botón por etapa, la barra y el descanso
		events  lanzar ya un evento del servidor
	Cada botón es una orden de server/Admin (nombre y valor).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local Style = require(script.Parent.Parent.Interface.Style)
local AdminRows = require(script.Parent.AdminRows)

local CARDS = Style.PALETTE.Cards

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
	page.row("Velocidad", {
		{ text = "Poner", name = "speed" },
		{ text = "Normal", name = "speed", value = 16 },
		{ text = "Rápido", name = "speed", value = 60 },
		{ text = "Turbo", name = "speed", value = 120 },
	}, "número")
	page.section("Pases y regalos")
	local passes: { Button } = {}
	for _, key in Config.Monetization.passOrder do
		local name = Config.Monetization.passes[key].name
		table.insert(passes, { text = name, name = "pass", value = key, color = CARDS.Purple })
	end
	page.row("Pases (on/off)", passes)
	page.row("Regalos tiempo", {
		{ text = "+10 min", name = "playtime", value = 10 },
		{ text = "+1 h", name = "playtime", value = 60 },
	})
	page.section("Mover")
	page.row("Llevar a", {
		{ text = "Orilla", name = "tp", value = "orilla" },
		{ text = "Volcán", name = "tp", value = "volcan" },
		{ text = "Plaza", name = "tp", value = "plaza" },
		{ text = "Tienda", name = "tp", value = "tienda" },
	})
	page.row("Otro jugador", {
		{ text = "Ir con él", name = "visit", value = 0, color = CARDS.Cyan },
		{ text = "Traerlo", name = "bring", value = 0, color = CARDS.Cyan },
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

local function fillGiants(page: Page)
	page.section("Monstruo y etapa", "si está comiendo cambia ya; si no, llega después")
	for _, def in Config.Giants.chain do
		local stages: { Button } = {}
		for stage = 1, #Config.Giants.stageThresholds do
			table.insert(
				stages,
				{ text = `Etapa {stage}`, name = "giant", value = `{def.id}:{stage}` }
			)
		end
		page.row(def.displayName, stages)
	end
	page.section("Barra y descanso")
	page.row("Barra", {
		{ text = "+25%", name = "fill", value = 0.25 },
		{ text = "+50%", name = "fill", value = 0.5 },
		{ text = "Llenar", name = "fill", value = 1, color = CARDS.Green },
	})
	page.row("Descanso", {
		{ text = "Terminar", name = "skipRest", value = 0, color = CARDS.Orange },
		{ text = "+1 min", name = "restTime", value = 0 },
	})
end

local function fillEvents(page: Page)
	page.section("Lanzar ya")
	local events: { Button } = {}
	for _, kind in Events.kinds do
		table.insert(
			events,
			{ text = kind.name, name = "event", value = kind.id, color = CARDS.Pink }
		)
	end
	page.row("Evento", events)
end

return table.freeze({ player = fillPlayer, giants = fillGiants, events = fillEvents })
