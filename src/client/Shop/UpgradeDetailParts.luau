--!strict
--[[
	UpgradeDetailParts

	Piezas de UpgradeDetail (el panel del nivel elegido en MEJORAS):
		box       caja redondeada de color
		stats     las filas de datos del nivel, comparadas con lo equipado (x2 → x3)
		caption   el estado de arriba ("EQUIPADA", "BLOQUEADA"...) y la nota de abajo
		luckLine  en las cañas, la línea con la suerte del nivel elegido (Menus/LuckLine)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LuckOdds = require(ReplicatedStorage.Shared.LuckOdds)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Style = require(script.Parent.Parent.Interface.Style)
local LuckLine = require(script.Parent.Parent.Menus.LuckLine)

local SOFT = Color3.fromRGB(255, 236, 200)

local UpgradeDetailParts = {}

function UpgradeDetailParts.box(parent: Instance, name: string, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

-- Vuelve a escribir las filas de `stats` para el nivel de `spec`.
function UpgradeDetailParts.stats(stats: Frame, spec: any)
	for _, child in stats:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local now = Upgrades.stats(spec.category, spec.currentDef)
	for index, stat in Upgrades.stats(spec.category, spec.def) do
		local before = now[index] and now[index].value
		local compare = spec.level > spec.owned and before ~= nil and before ~= stat.value
		local row = Style.text(stats, "Dato", 24, SOFT, 2)
		row.LayoutOrder = index
		row.Size = UDim2.fromScale(1, 0.48)
		row.RichText = true
		row.Text = if compare
			then `{stat.label}: {before} → <font color="#7CFF6B">{stat.value}</font>`
			else `{stat.label}: {stat.value}`
	end
end

function UpgradeDetailParts.caption(spec: any, isNext: boolean, status: TextLabel, note: TextLabel)
	if spec.level == spec.owned then
		status.Text = if spec.owned == spec.count then "¡NIVEL MÁXIMO!" else "EQUIPADA"
		note.Text = "La estás usando"
	elseif spec.level < spec.owned then
		status.Text, note.Text = "YA LA TIENES", "Tienes una mejor"
	elseif isNext then
		status.Text = "SIGUIENTE MEJORA"
	else
		status.Text, note.Text = "BLOQUEADA", `Compra antes el Nivel {spec.owned + 1}`
	end
end

-- Contenedor de la línea de suerte; devuelve cómo repintarla para el nivel elegido.
function UpgradeDetailParts.luckLine(panel: Frame): (Frame, (spec: any) -> ())
	local box = Instance.new("Frame")
	box.Name = "Suerte"
	box.BackgroundTransparency = 1
	box.Parent = panel
	local function set(spec: any)
		box.Visible = spec.category == "Rod"
		box:ClearAllChildren() -- el nombre de la caña cambia con el nivel: se monta de nuevo
		if box.Visible then
			local level: number = spec.level
			LuckLine.mount(box, spec.def.name, function()
				return LuckOdds.withRod(Players.LocalPlayer, level)
			end)
		end
	end
	return box, set
end

return UpgradeDetailParts
