--!strict
--[[
	BlockFish

	El pez de bloques que nada sobre la punta de la barra de carga: un dibujo de
	cuadritos (como los gigantes, todo cubos) hecho con Frames, sin imágenes, para
	que se vea desde el primer cuadro aunque todavía no haya cargado nada.
		build(parent, cell, colors) -> Frame   el pez mirando a la derecha; cell es
		                                        el lado de cada cuadrito en píxeles
]]

-- Mirando a la derecha: cola a la izquierda. O cuerpo, B panza, F aletas y cola, E ojo.
local PIXELS = {
	"....FFF....",
	"F..OOOOOO..",
	"FFOOOOOOEO.",
	"FFOOOOOOOOO",
	"FFBBBBBBBO.",
	"F..BBBBBB..",
	"....FF.....",
}

local COLOR_KEYS: { [string]: string } = {
	O = "FishBody",
	B = "FishBelly",
	F = "FishFin",
	E = "FishEye",
}

local BlockFish = {}

function BlockFish.build(parent: GuiObject, cell: number, colors: { [string]: Color3 }): Frame
	local columns = #PIXELS[1]
	local fish = Instance.new("Frame")
	fish.Name = "Pez"
	fish.BackgroundTransparency = 1
	fish.AnchorPoint = Vector2.new(0.5, 1)
	fish.Size = UDim2.fromOffset(columns * cell, #PIXELS * cell)
	fish.ZIndex = parent.ZIndex + 2
	for row, line in PIXELS do
		for column = 1, columns do
			local key = COLOR_KEYS[string.sub(line, column, column)]
			if key then
				local block = Instance.new("Frame")
				block.BorderSizePixel = 0
				block.BackgroundColor3 = colors[key]
				block.Position = UDim2.fromOffset((column - 1) * cell, (row - 1) * cell)
				-- Un píxel de más tapa las rayas entre cuadritos al escalar.
				block.Size = UDim2.fromOffset(cell + 1, cell + 1)
				block.ZIndex = fish.ZIndex
				block.Parent = fish
			end
		end
	end
	fish.Parent = parent
	return fish
end

return table.freeze(BlockFish)
