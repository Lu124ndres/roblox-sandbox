--!strict
--[[
	AdminPagesMod

	Pestañas del panel admin de moderación y de diversión (AdminPanel las arma;
	la de diversión también va en la de todos los servidores):
		moderation  expulsar (con motivo), banear por minutos o para siempre,
		            silenciar, congelar y reaparecer al jugador elegido; quitar un
		            baneo por UserId (Admin/AdminModeration, AdminFun.unban)
		fun         anuncio grande, fuegos artificiales, lluvia de peces raros,
		            monedas y giros para todos (Admin/AdminFun)
]]

local Style = require(script.Parent.Parent.Interface.Style)
local AdminRows = require(script.Parent.AdminRows)

local CARDS = Style.PALETTE.Cards

type Page = AdminRows.Page

local function fillModeration(page: Page)
	page.section("Jugador elegido", "no se aplica a otro administrador")
	page.row("Expulsar", {
		{ text = "Expulsar", name = "kick", color = CARDS.Red, confirm = true },
	}, "motivo (opcional)", true)
	page.row("Banear", {
		{ text = "Minutos", name = "ban", color = CARDS.Red, confirm = true },
		{ text = "1 día", name = "ban", value = 60 * 24, color = CARDS.Red, confirm = true },
		{ text = "Para siempre", name = "ban", value = 0, color = CARDS.Red, confirm = true },
	}, "minutos")
	page.row("Chat", {
		{ text = "Silenciar", name = "mute", value = 0, color = CARDS.Orange },
		{ text = "Quitar", name = "unmute", value = 0, color = CARDS.Green },
	})
	page.row("Moverse", {
		{ text = "Congelar", name = "freeze", value = 0, color = CARDS.Cyan },
		{ text = "Soltar", name = "unfreeze", value = 0, color = CARDS.Green },
		{ text = "Reaparecer", name = "respawn", value = 0 },
	})
	page.section("Quitar un baneo", "el jugador ya no está: escribe su UserId")
	page.row("Desbanear", {
		{ text = "Desbanear", name = "unban", color = CARDS.Green, confirm = true },
	}, "UserId")
end

local function fillFun(page: Page)
	page.section("Anuncio", "cartel grande para todos; Roblox filtra el texto")
	page.row("Mensaje", { { text = "Enviar", name = "announce" } }, "escribe el mensaje", true)
	page.section("En vivo")
	page.row("Fuegos", { { text = "¡Fuegos!", name = "fireworks", value = 0 } })
	page.row("Lluvia de peces", {
		{ text = "Peces", name = "fishRain" },
		{ text = "10 c/u", name = "fishRain", value = 10 },
		{ text = "50 c/u", name = "fishRain", value = 50 },
	}, "peces por jugador")
	page.row("Monedas a todos", {
		{ text = "Dar", name = "giveCoins" },
		{ text = "1K", name = "giveCoins", value = 1000 },
		{ text = "10K", name = "giveCoins", value = 10000 },
		{ text = "100K", name = "giveCoins", value = 100000 },
	}, "monedas")
	page.row("Giros a todos", {
		{ text = "+1", name = "giveSpins", value = 1 },
		{ text = "+5", name = "giveSpins", value = 5 },
		{ text = "+10", name = "giveSpins", value = 10 },
	})
end

return table.freeze({ moderation = fillModeration, fun = fillFun })
