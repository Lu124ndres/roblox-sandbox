--!strict
--[[
	GamepadHints

	Con mando, cada botón del menú que abre una flecha (GamepadNav) lleva en
	la esquina de arriba a la izquierda una tecla de piedra con la cruz del
	D-pad y el brazo de esa flecha en blanco, como en las guías de Xbox
	(Roblox da la misma cruz para las cuatro y no se sabe cuál es). El regalo
	gratis lleva el botón Y tal cual lo da Roblox (InputHints.badge sin
	tecla), en la esquina derecha de su placa (a la izquierda lo tapa el
	dibujo del regalo). En PC y táctil no se ven. En los botones del menú, a
	la derecha va el punto rojo de aviso.
	Pedido del usuario el 2026-10-23.
]]

local Kit = require(script.Parent.Parent.Interface.Kit)
local InputHints = require(script.Parent.Parent.Interface.InputHints)

local rgb = Color3.fromRGB
local CROSS = rgb(38, 38, 42) -- la cruz, oscura como la del mando
local LIT = rgb(255, 255, 255) -- el brazo de la flecha que se aprieta
local KEY_SLICE = 0.14 -- canto de la tecla de piedra (como InputHints.badge)
local ARM = 0.3 -- grosor de cada brazo de la cruz (fracción de la tecla)
-- Dónde queda el brazo encendido de cada flecha (centro, dentro de la tecla).
local ARMS: { [Enum.KeyCode]: Vector2 } = {
	[Enum.KeyCode.DPadUp] = Vector2.new(0.5, 0.29),
	[Enum.KeyCode.DPadDown] = Vector2.new(0.5, 0.71),
	[Enum.KeyCode.DPadLeft] = Vector2.new(0.29, 0.5),
	[Enum.KeyCode.DPadRight] = Vector2.new(0.71, 0.5),
}

local GamepadHints = {}

local function bar(parent: Instance, center: Vector2, size: Vector2, color: Color3, z: number)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(center.X, center.Y)
	frame.Size = UDim2.fromScale(size.X, size.Y)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = frame
	frame.Parent = parent
end

-- La cruz del D-pad con el brazo de `pad` encendido, sobre una tecla de piedra.
local function arrowKey(button: GuiObject, pad: Enum.KeyCode): Frame
	local key = Instance.new("Frame")
	key.Name = "Flecha"
	key.AnchorPoint = Vector2.new(0.5, 0.5)
	key.SizeConstraint = Enum.SizeConstraint.RelativeYY
	key.ZIndex = button.ZIndex + 2
	Kit.skin(key, "boton", Kit.STONE).SliceScale = KEY_SLICE
	local z = key.ZIndex + 1
	bar(key, Vector2.new(0.5, 0.5), Vector2.new(ARM, 0.74), CROSS, z)
	bar(key, Vector2.new(0.5, 0.5), Vector2.new(0.74, ARM), CROSS, z)
	local lit = ARMS[pad]
	local vertical = lit.X == 0.5
	bar(
		key,
		lit,
		if vertical then Vector2.new(ARM - 0.08, 0.26) else Vector2.new(0.26, ARM - 0.08),
		LIT,
		z + 1
	)
	local function paint(mode: InputHints.Mode)
		key.Visible = mode == "gamepad"
	end
	InputHints.onChange(paint)
	paint(InputHints.mode())
	key.Parent = button
	return key
end

local function place(hint: Frame, size: number, corner: Vector2)
	hint.SizeConstraint = Enum.SizeConstraint.RelativeYY
	hint.Size = UDim2.fromScale(size, size)
	hint.Position = UDim2.fromScale(corner.X, corner.Y)
end

-- arrows: qué botón grande (por su texto, "Boton<texto>") abre cada flecha.
function GamepadHints.attach(playerGui: PlayerGui, arrows: { [Enum.KeyCode]: string })
	for pad, text in arrows do
		local button = playerGui:FindFirstChild(`Boton{text}`, true)
		if button and button:IsA("GuiObject") then
			place(arrowKey(button, pad), 0.36, Vector2.new(0.17, 0.17))
		end
	end
	local gift = playerGui:FindFirstChild("RegalosTiempo", true)
	local giftButton = gift and gift:FindFirstChild("Boton")
	if giftButton and giftButton:IsA("GuiObject") then
		-- La placa es ancha y baja: la Y va en su esquina de arriba a la derecha.
		place(
			InputHints.badge(giftButton, nil, Enum.KeyCode.ButtonY),
			0.62,
			Vector2.new(0.96, 0.12)
		)
	end
end

return table.freeze(GamepadHints)
