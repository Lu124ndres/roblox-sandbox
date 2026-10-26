--!strict
--[[
	AdminSections

	Qué secciones tiene el panel admin y de qué alcance es cada una (AdminPanel
	las arma): su color, el título de su grupo en la columna de la izquierda y
	cómo se llena su página (AdminPages, AdminPagesWorld, AdminPagesMod). Las
	de INFO no tienen `fill`: las arma AdminLog.
]]

local Style = require(script.Parent.Parent.Interface.Style)
local AdminPages = require(script.Parent.AdminPages)
local AdminPagesMod = require(script.Parent.AdminPagesMod)
local AdminPagesWorld = require(script.Parent.AdminPagesWorld)
local AdminRows = require(script.Parent.AdminRows)

local CARDS = Style.PALETTE.Cards

local AdminSections = {}

export type Scope = "player" | "server" | "global" | "info"
local SCOPES: { [Scope]: { color: Color3, group: string } } = {
	player = { color = CARDS.Blue, group = "JUGADOR" },
	server = { color = CARDS.Orange, group = "ESTE SERVIDOR" },
	global = { color = CARDS.Red, group = "TODOS LOS SERVIDORES" },
	info = { color = CARDS.Purple, group = "INFO" },
}
local SCOPE_ORDER: { Scope } = { "player", "server", "global", "info" }

export type Section = { title: string, scope: Scope, fill: ((page: AdminRows.Page) -> ())? }
local SECTIONS: { Section } = {
	{ title = "Jugador", scope = "player", fill = AdminPages.player },
	{ title = "Compras", scope = "player", fill = AdminPages.shop },
	{ title = "Moverse", scope = "player", fill = AdminPagesWorld.moves },
	{ title = "Moderación", scope = "player", fill = AdminPagesMod.moderation },
	{ title = "Mundo", scope = "server", fill = AdminPagesWorld.world },
	{ title = "Monstruos", scope = "server", fill = AdminPagesWorld.giants },
	{ title = "Diversión", scope = "server", fill = AdminPagesMod.fun },
	{
		title = "Global",
		scope = "global",
		fill = function(page)
			AdminPagesMod.fun(page)
			AdminPagesWorld.world(page)
			AdminPagesWorld.giants(page)
		end,
	},
	{ title = "Servidores", scope = "info" },
	{ title = "Registro", scope = "info" },
}

AdminSections.SCOPES = SCOPES
AdminSections.SCOPE_ORDER = SCOPE_ORDER
AdminSections.SECTIONS = SECTIONS

-- Columna de la izquierda (los botones los pone AdminPanel).
function AdminSections.sidebar(parent: Instance, width: number): ScrollingFrame
	local side = Instance.new("ScrollingFrame")
	side.Name = "Secciones"
	side.BackgroundTransparency = 1
	side.BorderSizePixel = 0
	side.Size = UDim2.new(0, width, 1, 0)
	side.AutomaticCanvasSize = Enum.AutomaticSize.Y
	side.CanvasSize = UDim2.new()
	side.ScrollBarThickness = 4
	side.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = side
	return side
end

return AdminSections
