--!strict
--[[
	GearIcons

	Íconos del equipo de la tienda: uno distinto por cada nivel de caña, canasta y
	botas. Cada categoría es una hoja de 5 columnas con celdas de 200 px; la celda
	es nivel - 1, por filas (assets/ui/iconos/equipo_*.png).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

local CELL = 200
local COLUMNS = 5

-- Claves en minúscula; se acepta también la categoría de Upgrades ("Rod").
local SHEETS: { [string]: { id: string, count: number } } = {
	rod = { id = Assets.UI.EquipoRod, count = 20 },
	basket = { id = Assets.UI.EquipoBasket, count = 14 },
	boots = { id = Assets.UI.EquipoBoots, count = 14 },
}

local GearIcons = {}

-- Pinta el ícono de un nivel en un ImageLabel que ya existe.
function GearIcons.paint(image: ImageLabel, category: string, level: number): boolean
	local sheet = SHEETS[string.lower(category)]
	if not sheet or sheet.id == nil or sheet.id == Assets.MISSING then
		return false
	end
	local index = math.clamp(level, 1, sheet.count) - 1
	image.Image = sheet.id
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
