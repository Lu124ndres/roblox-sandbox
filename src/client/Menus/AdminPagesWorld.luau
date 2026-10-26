--!strict
--[[
	AdminPagesWorld

	Pestañas del panel admin de moverse y del servidor (AdminPanel las arma;
	world y giants también van en la de todos los servidores):
		moves   volar y sin colisión (solo tú, AdminMoves), velocidad, llevar a
		        un lugar e ir con el jugador elegido / traerlo
		world   la hora del cielo, eventos (y el admin abuse con sus minutos) y
		        entrenamiento del servidor
		giants  cada monstruo con un botón por etapa, la barra y el descanso
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local Style = require(script.Parent.Parent.Interface.Style)
local AdminMoves = require(script.Parent.AdminMoves)
local AdminRows = require(script.Parent.AdminRows)

local CARDS = Style.PALETTE.Cards

type Button = AdminRows.Button
type Page = AdminRows.Page

local function fillMoves(page: Page)
	page.section("Tú", "solo tu personaje; se apaga al reaparecer")
	page.row("Volar", {
		{
			text = "Volar: no",
			name = "fly",
			color = CARDS.Cyan,
			run = AdminMoves.toggleFly,
			label = AdminMoves.flyLabel,
		},
		{
			text = "Sin colisión: no",
			name = "noclip",
			color = CARDS.Cyan,
			run = AdminMoves.toggleNoclip,
			label = AdminMoves.noclipLabel,
		},
	})
	page.section("Jugador elegido")
	page.row("Velocidad", {
		{ text = "Poner", name = "speed" },
		{ text = "Normal", name = "speed", value = 16 },
		{ text = "Rápido", name = "speed", value = 60 },
		{ text = "Turbo", name = "speed", value = 120 },
	}, "número")
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
end

local function fillWorld(page: Page)
	page.section("Hora del cielo")
	page.row("Cielo", {
		{ text = "Día", name = "time", value = 8, color = CARDS.Yellow },
		{ text = "Mediodía", name = "time", value = 12, color = CARDS.Yellow },
		{ text = "Atardecer", name = "time", value = 18.4, color = CARDS.Orange },
		{ text = "Noche", name = "time", value = 0, color = CARDS.Purple },
		{ text = "Ciclo normal", name = "time", value = "auto", color = CARDS.Green },
	})
	page.section("Eventos", "empiezan ya; los minutos de la casilla cambian su duración")
	local events: { Button } = {}
	for _, kind in Events.kinds do
		if not kind.adminOnly then
			table.insert(
				events,
				{ text = kind.name, name = "event", value = kind.id, color = CARDS.Pink }
			)
		end
	end
	page.row("Evento ya", events)
	page.row("Admin abuse", {
		{ text = "Minutos", name = "abuse", color = CARDS.Red },
		{ text = "15 min", name = "abuse", value = 15, color = CARDS.Red },
		{ text = "30 min", name = "abuse", value = 30, color = CARDS.Red },
		{ text = "60 min", name = "abuse", value = 60, color = CARDS.Red },
	}, "minutos")
	page.row("Terminar", {
		{ text = "Terminar evento", name = "stopEvent", value = 0, color = CARDS.Orange },
	})
	page.section("Entrenamiento")
	local boosts: { Button } = {}
	for level = 1, #Config.Monetization.serverBoost.robux do
		table.insert(boosts, { text = `x{2 ^ level}`, name = "boost", value = level })
	end
	page.row("Entrenamiento", boosts)
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

return table.freeze({ moves = fillMoves, world = fillWorld, giants = fillGiants })
