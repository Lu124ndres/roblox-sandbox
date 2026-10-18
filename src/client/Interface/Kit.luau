--!strict
--[[
	Kit

	Las piezas del estilo "piedra" de la interfaz (pedido del usuario: piedra
	oscura tallada, texto dorado, marco de lava para lo importante y gemas
	azules de adorno). Las imágenes son 9-slice de assets/ui/kit_piedra/
	(tools/ui/generar_kit_piedra.py); SLICES son sus centros, en píxeles.
		skin(objeto, pieza, tinte?)   le pone de fondo la pieza ("panel", "hondo",
		                              "boton", "lava") a un Frame o botón, detrás de
		                              todo; el botón se tiñe con `tinte`
		gold(texto)                   texto dorado con contorno marrón oscuro
		gems(objeto, tamaño?)         una gema a cada lado (a media altura)
		tint(piel, color)             cambia el tinte (y lo recuerda press)
		press(botón, piel)            se aclara al pasar y se oscurece al tocar
	La piel es un ImageLabel "Piedra" con ZIndex 0: el contenido va encima.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)

export type Piece = "panel" | "hondo" | "boton" | "lava"

local IMAGES: { [Piece]: string } = {
	panel = Assets.UI.PiedraPanel,
	hondo = Assets.UI.PiedraHondo,
	boton = Assets.UI.PiedraBoton,
	lava = Assets.UI.PiedraLava,
}
local SLICES: { [Piece]: Rect } = {
	panel = Rect.new(44, 44, 212, 212),
	hondo = Rect.new(22, 22, 106, 106),
	boton = Rect.new(34, 34, 222, 94),
	lava = Rect.new(34, 34, 222, 94),
}
-- Cuánto se achica el borde en pantalla (las imágenes están al doble).
local SLICE_SCALE: { [Piece]: number } = { panel = 0.5, hondo = 0.5, boton = 0.42, lava = 0.42 }

local rgb = Color3.fromRGB
local Kit = {}

Kit.STONE = rgb(128, 132, 144) -- tinte del botón de piedra gris (MEJORAS)
Kit.GOLD_OUTLINE = rgb(42, 22, 8)
Kit.GOLD = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 246, 170)),
	ColorSequenceKeypoint.new(0.45, rgb(255, 214, 82)),
	ColorSequenceKeypoint.new(1, rgb(222, 128, 30)),
})

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
	image.ImageColor3 = tint or Color3.new(1, 1, 1)
	image:SetAttribute("Tinte", image.ImageColor3)
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
	skin.ImageColor3 = color
	skin:SetAttribute("Tinte", color)
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
