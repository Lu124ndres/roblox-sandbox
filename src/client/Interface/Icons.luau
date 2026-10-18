--!strict
--[[
	Icons

	Íconos de la interfaz: pintados a mano (Canva, assets/ui/iconos/v4) en hojas
	de 4x4 (256 px cada uno); cada ícono es un recorte de su hoja
	(ImageRectOffset). Si la hoja no tiene ID, se usa el modelo 3D de Icon3D.
	Hoja 1: coin, crystal, basketFish, skull (ya no es una calavera: el monstruo
	        alimentado del contador "monstruos llenados"), basket, chest, gift,
	        gear, fish, ticket, friends, group, fang, fed (cuenco de peces).
	Hoja 2: rod, boots, crown, pond, bolt, orca, minotaur, dragon, fox,
	        giftPink, arrow, meat, sunburst (rayos blancos para teñir), glow.
	Hoja 3: la anterior del monstruo panzón (ya no se usa: fed va en la hoja 1).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Icon3D = require(script.Parent.Icon3D)

local CELL = 256
local COLUMNS = 4

type Cell = { sheet: number, index: number, fallback: string }

-- Tipo de ícono -> hoja, lugar en la hoja (0..15, por filas) y modelo 3D de reserva.
local CELLS: { [string]: Cell } = {
	coin = { sheet = 1, index = 0, fallback = "coin" },
	crystal = { sheet = 1, index = 1, fallback = "crystal" },
	basketFish = { sheet = 1, index = 2, fallback = "fish:Sardina" },
	skull = { sheet = 1, index = 3, fallback = "skull" },
	basket = { sheet = 1, index = 4, fallback = "basket" },
	chest = { sheet = 1, index = 5, fallback = "chest" },
	gift = { sheet = 1, index = 6, fallback = "gift" },
	gear = { sheet = 1, index = 7, fallback = "gear" },
	fish = { sheet = 1, index = 8, fallback = "fish:PezPayaso" },
	ticket = { sheet = 1, index = 9, fallback = "gift" },
	friends = { sheet = 1, index = 10, fallback = "fish:PezGlobo" },
	group = { sheet = 1, index = 11, fallback = "chest" },
	fang = { sheet = 1, index = 12, fallback = "skull" },
	rod = { sheet = 2, index = 0, fallback = "fish:Sardina" },
	boots = { sheet = 2, index = 1, fallback = "crystal" },
	crown = { sheet = 2, index = 2, fallback = "coin" },
	pond = { sheet = 2, index = 3, fallback = "fish:PezPayaso" },
	bolt = { sheet = 2, index = 4, fallback = "crystal" },
	orca = { sheet = 2, index = 5, fallback = "skull" },
	minotaur = { sheet = 2, index = 6, fallback = "skull" },
	dragon = { sheet = 2, index = 7, fallback = "skull" },
	fox = { sheet = 2, index = 8, fallback = "skull" },
	giftPink = { sheet = 2, index = 9, fallback = "gift" },
	arrow = { sheet = 2, index = 10, fallback = "crystal" },
	meat = { sheet = 2, index = 11, fallback = "fish:Atun" },
	sunburst = { sheet = 2, index = 12, fallback = "" },
	glow = { sheet = 2, index = 13, fallback = "" },
	fed = { sheet = 1, index = 13, fallback = "skull" },
}

local Icons = {}

local function sheetId(number: number): string?
	local id = ({ Assets.UI.IconSheet, Assets.UI.IconSheet2, Assets.UI.IconSheet3 })[number]
	return if id and id ~= Assets.MISSING then id else nil
end

-- ¿Ya hay imagen para este tipo? (los rayos de fondo no tienen reserva 3D).
function Icons.has(kind: string): boolean
	local cell = CELLS[kind]
	return cell ~= nil and sheetId(cell.sheet) ~= nil
end

-- Recorte de la hoja en un ImageLabel/ImageButton que ya existe.
function Icons.paint(image: ImageLabel, kind: string): boolean
	local cell = CELLS[kind]
	local sheet = cell and sheetId(cell.sheet)
	if not cell or not sheet then
		return false
	end
	image.Image = sheet
	image.ImageRectSize = Vector2.new(CELL, CELL)
	image.ImageRectOffset =
		Vector2.new((cell.index % COLUMNS) * CELL, (cell.index // COLUMNS) * CELL)
	return true
end

function Icons.view(parent: Instance, kind: string): GuiObject
	local cell = CELLS[kind]
	local label = Instance.new("ImageLabel")
	label.Name = `Icono_{kind}`
	label.BackgroundTransparency = 1
	label.ScaleType = Enum.ScaleType.Fit
	if not Icons.paint(label, kind) then
		label:Destroy()
		local fallback = if cell then cell.fallback else kind
		if fallback == "" then
			local empty = Instance.new("Frame")
			empty.BackgroundTransparency = 1
			empty.Parent = parent
			return empty
		end
		return Icon3D.view(parent, fallback)
	end
	label.Parent = parent
	return label
end

return Icons
