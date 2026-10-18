--!strict
--[[
	StoneSkin

	Viste de piedra (Interface/Kit) un cuadro que ya tenía el borde negro del
	estilo anterior (Style.border), sin perder ese borde: se esconde, porque la
	piedra trae su canto, pero sigue ahí. Si alguien lo pinta de otro color
	(el día de hoy en el premio diario, la tarjeta elegida en MEJORAS) se vuelve
	a ver, siguiendo la esquina redonda de la piedra.
]]

local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local STONE_CORNER = 10 -- radio de la esquina de la piedra en pantalla (boton.png a 0.42)

local StoneSkin = {}

-- El borde se ve solo cuando no es el negro de siempre.
local function highlightOnly(stroke: UIStroke)
	if stroke:GetAttribute("Resalte") then
		return
	end
	stroke:SetAttribute("Resalte", true)
	local function show()
		stroke.Transparency = if stroke.Color == Style.OUTLINE then 1 else 0
	end
	show()
	stroke:GetPropertyChangedSignal("Color"):Connect(show)
end

function StoneSkin.dress(frame: GuiObject, piece: Kit.Piece, tint: Color3?): ImageLabel
	local strokes: { UIStroke } = {}
	for _, child in frame:GetChildren() do
		if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
			child.Parent = nil -- Kit.skin borra los bordes: se aparta y se devuelve
			table.insert(strokes, child)
		end
	end
	local skin = Kit.skin(frame, piece, tint)
	if #strokes > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, STONE_CORNER)
		corner.Parent = frame
	end
	for _, stroke in strokes do
		stroke.Parent = frame
		highlightOnly(stroke)
	end
	return skin
end

return StoneSkin
