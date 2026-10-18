--!strict
--[[
	Kit

	Las piezas del estilo de la interfaz (pedido del usuario: piedra volcánica
	con grietas de lava, texto dorado, MEJORAS de piedra gris con canto dorado y
	TIENDA con marco de lava). Las imágenes las hizo la IA de Canva sobre las
	referencias del usuario (assets/ui/kit_canva/, tools/ui/recortar_kit_canva.py);
	son 9-slice y SLICES son sus centros, en píxeles.
		skin(objeto, pieza, tinte?)   le pone de fondo la pieza ("panel", "hondo",
		                              "boton", "lava", "casilla") a un Frame o botón,
		                              detrás de todo. El botón ya es de piedra gris:
		                              un tinte gris lo deja así y uno de color lo pinta
		                              (claro, para que no se apague)
		gold(texto)                   texto dorado con contorno marrón oscuro
		gems(objeto, tamaño?)         una gema azul a cada lado (a media altura)
		crystals(objeto, tamaño?)     cristales oscuros a cada lado (los títulos)
		tint(piel, color)             cambia el tinte (y lo recuerda press)
		press(botón, piel)            se aclara al pasar y se oscurece al tocar
	La piel es un ImageLabel "Piedra" con ZIndex 0: el contenido va encima.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)

export type Piece = "panel" | "hondo" | "boton" | "lava" | "casilla"

local IMAGES: { [Piece]: string } = {
	panel = Assets.UI.PiedraPanel,
	hondo = Assets.UI.PiedraHondo,
	boton = Assets.UI.PiedraBoton,
	lava = Assets.UI.PiedraLava,
	casilla = Assets.UI.PiedraCasilla,
}
-- assets/ui/kit_canva/cortes.json: los cantos miden lo mismo que en el kit anterior, así los
-- SliceScale que ajustó cada pantalla siguen valiendo.
local SLICES: { [Piece]: Rect } = {
	panel = Rect.new(44, 44, 293, 231),
	hondo = Rect.new(22, 22, 323, 78),
	boton = Rect.new(34, 34, 297, 121),
	lava = Rect.new(34, 34, 288, 121),
	casilla = Rect.new(34, 34, 156, 155),
}
-- Cuánto se achica el borde en pantalla.
local SLICE_SCALE: { [Piece]: number } =
	{ panel = 0.5, hondo = 0.5, boton = 0.42, lava = 0.42, casilla = 0.42 }
local TINTED: { [Piece]: boolean } = { boton = true, casilla = true }

local rgb = Color3.fromRGB
local Kit = {}

Kit.STONE = rgb(128, 132, 144) -- tinte del botón de piedra gris (MEJORAS)
Kit.GOLD_OUTLINE = rgb(42, 22, 8)
Kit.GOLD = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 246, 170)),
	ColorSequenceKeypoint.new(0.45, rgb(255, 214, 82)),
	ColorSequenceKeypoint.new(1, rgb(222, 128, 30)),
})

-- El color que de verdad se le pone a la imagen. La piedra del botón ya es gris: un tinte
-- gris (STONE, apagado) la deja casi igual, solo un poco más oscura si el gris es oscuro, y
-- uno de color se aclara para que, multiplicado por el gris, siga vivo.
local function effective(piece: Piece, tint: Color3?): Color3
	if not tint or not TINTED[piece] then
		return tint or Color3.new(1, 1, 1)
	end
	local h, s, v = tint:ToHSV()
	if s < 0.18 then
		return Color3.fromHSV(0, 0, math.clamp(v * 1.7, 0.5, 1))
	end
	return Color3.fromHSV(h, math.min(1, s * 1.1), 1)
end

function Kit.skin(target: GuiObject, piece: Piece, tint: Color3?): ImageLabel
	local old = target:FindFirstChild("Piedra")
	if old then
		old:Destroy()
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Piedra"
	image.BackgroundTransparency = 1
	image.Image = IMAGES[piece]
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = SLICES[piece]
	image.SliceScale = SLICE_SCALE[piece]
	image.ImageColor3 = effective(piece, tint)
	image:SetAttribute("Tinte", image.ImageColor3)
	image:SetAttribute("Pieza", piece)
	image.Size = UDim2.fromScale(1, 1)
	image.ZIndex = 0
	image.Parent = target
	target.BackgroundTransparency = 1
	for _, child in target:GetChildren() do
		-- Las esquinas, bordes y degradados del estilo anterior sobran con la piedra.
		local border = child:IsA("UIStroke")
			and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
		if child:IsA("UICorner") or child:IsA("UIGradient") or border then
			child:Destroy()
		end
	end
	return image
end

function Kit.gold(label: TextLabel | TextButton)
	label.TextColor3 = Color3.new(1, 1, 1)
	local gradient = label:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Color = Kit.GOLD
	gradient.Rotation = 90
	gradient.Parent = label
	local stroke = label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = math.max(stroke.Thickness, 2)
	stroke.Parent = label
end

function Kit.gems(target: GuiObject, size: number?)
	local s = size or 34
	for _, side in { 0, 1 } do
		local gem = Instance.new("ImageLabel")
		gem.Name = "Gema"
		gem.BackgroundTransparency = 1
		gem.Image = Assets.UI.PiedraGema
		gem.AnchorPoint = Vector2.new(0.5, 0.5)
		gem.Position = UDim2.fromScale(side, 0.5)
		gem.Size = UDim2.fromOffset(s * 0.8, s)
		gem.Rotation = if side == 0 then -12 else 12
		gem.ZIndex = 8
		gem.Parent = target
	end
end

function Kit.tint(skin: ImageLabel, color: Color3)
	local piece = skin:GetAttribute("Pieza")
	local real = effective(if type(piece) == "string" then piece :: Piece else "panel", color)
	skin.ImageColor3 = real
	skin:SetAttribute("Tinte", real)
end

function Kit.crystals(target: GuiObject, size: number?)
	local s = size or 44
	for _, side in { 0, 1 } do
		local crystal = Instance.new("ImageLabel")
		crystal.Name = "Cristales"
		crystal.BackgroundTransparency = 1
		crystal.Image = Assets.UI.PiedraCristales
		crystal.AnchorPoint = Vector2.new(0.5, 0.7)
		crystal.Position = UDim2.fromScale(side, 0.5)
		crystal.Size = UDim2.fromOffset(s * 0.92, s)
		crystal.Rotation = if side == 0 then -10 else 10
		crystal.ZIndex = 8
		crystal.Parent = target
	end
end

-- El botón se aclara al pasar el mouse y se oscurece al tocarlo (la piel no tiene
-- AutoButtonColor: es una imagen).
function Kit.press(button: GuiButton, skin: ImageLabel)
	local quick = TweenInfo.new(0.08)
	local function to(k: number)
		local base = skin:GetAttribute("Tinte")
		local h, s, v = (if typeof(base) == "Color3" then base else skin.ImageColor3):ToHSV()
		TweenService
			:Create(skin, quick, { ImageColor3 = Color3.fromHSV(h, s, math.clamp(v * k, 0, 1)) })
			:Play()
	end
	button.MouseEnter:Connect(function()
		to(1.12)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.8)
	end)
	button.MouseButton1Up:Connect(function()
		to(1)
	end)
end

return table.freeze(Kit)
