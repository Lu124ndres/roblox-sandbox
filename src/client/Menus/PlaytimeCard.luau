--!strict
--[[
	PlaytimeCard

	Una tarjeta de la ventana de regalos por jugar (PlaytimeWindow), como los
	"Premios" de los simuladores: arriba el premio en dorado, al centro el ícono
	grande sobre rayos y abajo una placa con el tiempo que falta.
		esperando  casilla volcánica teñida suave del color del premio, placa de
		           piedra roja con la cuenta regresiva
		listo      marco de lava, placa verde que late con ¡RECLAMAR!
		cobrado    casilla gris apagada, sin rayos, hueco tallado con ¡RECLAMADO!
	`wide` arma la franja ancha del premio final: ícono a la izquierda, premio
	al centro con "PREMIO FINAL" y la placa del tiempo grande a la derecha.
]]

local TweenService = game:GetService("TweenService")

local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local WHITE = Color3.new(1, 1, 1)
local SOFT = 0.45 -- cuánto se tiñe la casilla del color del premio (0 = nada)
local FINAL_SOFT = 0.7 -- la franja final, más viva
local CLAIMED_TINT = Color3.fromRGB(120, 122, 132)
local CARD_SLICE = 0.36
local PLATE_SLICE = 0.3
local DIM = 0.45 -- transparencia del texto y el ícono de los cobrados
local PULSE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

export type State = "claimed" | "ready" | "waiting"

export type Card = {
	button: TextButton,
	setReward: (main: string, sub: string) -> (),
	setState: (state: State) -> (),
	setTime: (text: string) -> (),
}

-- Posición y tamaño (en escala) de cada pieza: tarjeta chica o franja final.
type Box = { x: number, y: number, w: number, h: number }
local LAYOUTS: { [string]: { [string]: Box } } = {
	card = {
		main = { x = 0.05, y = 0.04, w = 0.9, h = 0.2 },
		sub = { x = 0.05, y = 0.23, w = 0.9, h = 0.11 },
		icon = { x = 0.5, y = 0.54, w = 0.5, h = 0.36 },
		plate = { x = 0.5, y = 0.96, w = 0.86, h = 0.25 },
	},
	wide = {
		title = { x = 0.34, y = 0.08, w = 0.32, h = 0.2 },
		main = { x = 0.34, y = 0.28, w = 0.32, h = 0.34 },
		sub = { x = 0.34, y = 0.64, w = 0.32, h = 0.2 },
		icon = { x = 0.17, y = 0.5, w = 0.3, h = 0.86 },
		plate = { x = 0.835, y = 0.5, w = 0.29, h = 0.62 },
	},
}

local PlaytimeCard = {}

local function place(object: GuiObject, box: Box, anchor: Vector2?)
	object.AnchorPoint = anchor or Vector2.zero
	object.Position = UDim2.fromScale(box.x, box.y)
	object.Size = UDim2.fromScale(box.w, box.h)
end

local function dim(object: GuiObject, on: boolean)
	local amount = if on then DIM else 0
	if object:IsA("TextLabel") then
		object.TextTransparency = amount
	elseif object:IsA("ImageLabel") or object:IsA("ViewportFrame") then
		object.ImageTransparency = amount
	end
end

-- `icon` y `color`: el dibujo y el tinte del premio (monedas, poder, cofre).
function PlaytimeCard.new(
	parent: Instance,
	name: string,
	icon: string,
	color: Color3,
	wide: boolean
): Card
	local layout = LAYOUTS[if wide then "wide" else "card"]
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Parent = parent
	-- Rayos que giran (ShopParts.sunburst); la piel se cambia luego por la casilla.
	ShopParts.sunburst(button, color)
	local rays = button:FindFirstChild("Rayos") :: GuiObject?
	if rays then
		rays.ZIndex = 1 -- encima de la piel, debajo del ícono
		rays.Position = UDim2.fromScale(layout.icon.x, 0.5)
	end

	local picture = Icons.view(button, icon)
	place(picture, layout.icon, Vector2.new(0.5, 0.5))
	picture.ZIndex = 2
	local main = Style.text(button, "Premio", if wide then 46 else 30, nil, 3)
	place(main, layout.main)
	main.ZIndex = 3
	Kit.gold(main)
	local sub = Style.text(button, "Detalle", if wide then 22 else 17, nil, 2)
	place(sub, layout.sub)
	sub.ZIndex = 3
	local title: TextLabel? = nil
	if wide then
		local label = Style.text(button, "Titulo", 24, PALETTE.Timer, 2.5)
		label.Text = "¡PREMIO FINAL!"
		place(label, layout.title)
		label.ZIndex = 3
		title = label
		Kit.crystals(button, 46)
	end

	-- La placa del tiempo (o de ¡RECLAMAR!).
	local plate = Instance.new("Frame")
	plate.Name = "Tiempo"
	plate.BackgroundTransparency = 1
	place(plate, layout.plate, Vector2.new(0.5, if wide then 0.5 else 1))
	plate.ZIndex = 3
	plate.Parent = button
	local beat = Instance.new("UIScale")
	beat.Parent = plate
	local time = Style.text(plate, "Texto", if wide then 48 else 28, nil, 2.5)
	time.Position = UDim2.fromScale(0.06, 0.14)
	time.Size = UDim2.fromScale(0.88, 0.72)
	time.ZIndex = 4

	local soft = WHITE:Lerp(color, if wide then FINAL_SOFT else SOFT)
	local pulse: Tween? = nil
	local function setState(state: State)
		local skin = Kit.skin(button, if state == "ready" then "lava" else "casilla")
		skin.SliceScale = CARD_SLICE
		if state ~= "ready" then -- la casilla, teñida a mano: suave, no el tinte entero
			skin.ImageColor3 = if state == "claimed" then CLAIMED_TINT else soft
		end
		if rays then
			rays.Visible = state ~= "claimed"
		end
		local plateSkin = if state == "claimed"
			then Kit.skin(plate, "hondo")
			else Kit.skin(
				plate,
				"boton",
				if state == "ready" then PALETTE.Buy else PALETTE.Close
			)
		plateSkin.SliceScale = PLATE_SLICE
		time.TextColor3 = if state == "claimed" then PALETTE.Buy else WHITE
		for _, object in { picture, main, sub, title } :: { GuiObject? } do
			if object then
				dim(object, state == "claimed")
			end
		end
		if pulse then
			pulse:Cancel()
			pulse = nil
			beat.Scale = 1
		end
		if state == "ready" then
			local tween = TweenService:Create(beat, PULSE, { Scale = 1.08 })
			tween:Play()
			pulse = tween
		end
	end

	return {
		button = button,
		setReward = function(text: string, detail: string)
			main.Text = text
			sub.Text = detail
		end,
		setState = setState,
		setTime = function(text: string)
			time.Text = text
		end,
	}
end

return PlaytimeCard
