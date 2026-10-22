--!strict
--[[
	GearIcons

	Íconos del equipo de la tienda: uno distinto por cada nivel de caña, canasta y
	botas (v4, pintados a mano en Canva). Cada categoría tiene varias hojas de 5x4
	celdas de 200 px (1000x800: Roblox achica lo que pase de 1024): la hoja 1 tiene
	los niveles 1-20, la 2 los 21-40; dentro de la hoja, por filas
	(assets/ui/iconos/v4/equipo/).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

local CELL = 200
local COLUMNS = 5
local PER_SHEET = 20

-- Claves en minúscula; se acepta también la categoría de Upgrades ("Rod").
local SHEETS: { [string]: { ids: { string }, count: number } } = {
	rod = { ids = { Assets.UI.EquipoRod1, Assets.UI.EquipoRod2 }, count = 40 },
	basket = { ids = { Assets.UI.EquipoBasket1, Assets.UI.EquipoBasket2 }, count = 40 },
	boots = { ids = { Assets.UI.EquipoBoots1, Assets.UI.EquipoBoots2 }, count = 40 },
}

local GearIcons = {}

-- Pinta el ícono de un nivel en un ImageLabel que ya existe.
function GearIcons.paint(image: ImageLabel, category: string, level: number): boolean
	local sheet = SHEETS[string.lower(category)]
	if not sheet then
		return false
	end
	local index = math.clamp(level, 1, sheet.count) - 1
	local id = sheet.ids[index // PER_SHEET + 1]
	if id == nil or id == Assets.MISSING then
		return false
	end
	index %= PER_SHEET
	image.Image = id
	image.ImageRectSize = Vector2.new(CELL, CELL)
	image.ImageRectOffset = Vector2.new((index % COLUMNS) * CELL, (index // COLUMNS) * CELL)
	image.ScaleType = Enum.ScaleType.Fit
	return true
end

function GearIcons.view(parent: Instance, category: string, level: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = `Equipo_{category}_{level}`
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	GearIcons.paint(image, category, level)
	image.Parent = parent
	return image
end

-- Color del nivel según qué tan alto está en su categoría (común → mítico).
local TIERS = {
	Color3.fromRGB(150, 170, 190),
	Color3.fromRGB(90, 210, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(255, 70, 110),
	Color3.fromRGB(60, 230, 230),
}

function GearIcons.tierColor(category: string, level: number): Color3
	local sheet = SHEETS[string.lower(category)]
	local count = if sheet then sheet.count else 20
	return TIERS[math.clamp(math.ceil(level / count * #TIERS), 1, #TIERS)]
end

function GearIcons.count(category: string): number
	local sheet = SHEETS[string.lower(category)]
	return if sheet then sheet.count else 0
end

return GearIcons
