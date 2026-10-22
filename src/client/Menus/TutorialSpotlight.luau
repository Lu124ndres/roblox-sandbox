--!strict
--[[
	TutorialSpotlight

	Señala un botón de la interfaz en el tutorial (pedido del usuario: «que una
	flecha señale el ícono, se oscurezca un poco la pantalla para que vea dónde
	tiene que picar»):
		- un velo oscuro en toda la pantalla menos un hueco sobre el botón
		  (cuatro franjas alrededor de su rectángulo);
		- un marco verde que late alrededor del hueco;
		- una mano que rebota apuntándolo desde el lado que diga quien llama
		  (que no tape otro botón: dentro de MEJORAS, el de Robux está a la
		  derecha de comprar).
	El velo no atrapa toques: solo guía (los controles y la X de la ventana
	siguen andando). Sigue al botón cuadro a cuadro (las ventanas y el HUD se
	animan y cambian de escala).
		focus(target, side)  lo pone sobre `target`, con la mano a su lado
		                     `side` (nil = lo saca)
]]

local RunService = game:GetService("RunService")

local GuideArrow = require(script.Parent.GuideArrow)
local Style = require(script.Parent.Parent.Interface.Style)

local VEIL = Color3.new(0, 0, 0)
local VEIL_SEE_THROUGH = 0.45
local Z = 40 -- por encima del HUD y de las ventanas (Window usa 10)
local PAD = 6 -- píxeles de aire entre el botón y el borde del hueco
local HAND = 80
local BOUNCE = 12 -- píxeles que rebota la mano
local BOUNCE_SPEED = 6
local BEAT_SPEED = 4

export type Side = "left" | "right" | "above"
export type Spotlight = { focus: (target: GuiObject?, side: Side?) -> () }

-- La mano de cada lado (apunta hacia el botón).
local HANDS: { [Side]: string } = { left = "👉", right = "👈", above = "👇" }

local TutorialSpotlight = {}

local function frame(parent: Instance, name: string): Frame
	local part = Instance.new("Frame")
	part.Name = name
	part.BackgroundColor3 = VEIL
	part.BackgroundTransparency = VEIL_SEE_THROUGH
	part.BorderSizePixel = 0
	part.Active = false
	part.ZIndex = Z
	part.Parent = parent
	return part
end

function TutorialSpotlight.new(screen: ScreenGui): Spotlight
	-- Un marco de toda la pantalla que no se ve: con ZIndex por hermanos, es el que
	-- queda por encima del HUD y de las ventanas.
	local root = Instance.new("Frame")
	root.Name = "VeloTutorial"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Active = false
	root.ZIndex = Z
	root.Parent = screen
	local top, bottom, left, right =
		frame(root, "Arriba"),
		frame(root, "Abajo"),
		frame(root, "Izquierda"),
		frame(root, "Derecha")
	local ring = frame(root, "Marco")
	ring.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = GuideArrow.COLOR
	stroke.Thickness = 4
	stroke.Parent = ring
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = ring
	local hand = Style.text(root, "Mano", HAND, Color3.new(1, 1, 1), 0)
	hand.Size = UDim2.fromOffset(HAND, HAND)
	hand.AnchorPoint = Vector2.new(0.5, 0.5)
	hand.ZIndex = Z + 1
	local parts: { GuiObject } = { top, bottom, left, right, ring, hand }

	local target: GuiObject? = nil
	local handSide: Side = "right"
	local connection: RBXScriptConnection? = nil

	local function setVisible(on: boolean)
		for _, part in parts do
			part.Visible = on
		end
	end
	setVisible(false)

	local function draw()
		local current = target
		if not current or not current.Parent or not current:IsDescendantOf(game) then
			setVisible(false)
			return
		end
		local origin = root.AbsolutePosition
		local size = root.AbsoluteSize
		local min = current.AbsolutePosition - origin - Vector2.new(PAD, PAD)
		local max = min + current.AbsoluteSize + Vector2.new(PAD * 2, PAD * 2)
		local shown = current.Visible and current.AbsoluteSize.X > 1
		setVisible(shown)
		if not shown then
			return
		end
		top.Position, top.Size = UDim2.fromOffset(0, -100), UDim2.fromOffset(size.X, min.Y + 100)
		bottom.Position, bottom.Size =
			UDim2.fromOffset(0, max.Y), UDim2.fromOffset(size.X, size.Y - max.Y + 100)
		left.Position, left.Size =
			UDim2.fromOffset(0, min.Y), UDim2.fromOffset(min.X, max.Y - min.Y)
		right.Position, right.Size =
			UDim2.fromOffset(max.X, min.Y), UDim2.fromOffset(size.X - max.X, max.Y - min.Y)
		ring.Position, ring.Size =
			UDim2.fromOffset(min.X, min.Y), UDim2.fromOffset(max.X - min.X, max.Y - min.Y)
		local t = os.clock()
		stroke.Transparency = 0.35 + math.sin(t * BEAT_SPEED) * 0.3
		local bounce = math.abs(math.sin(t * BOUNCE_SPEED)) * BOUNCE
		local center = (min + max) / 2
		hand.Text = HANDS[handSide]
		if handSide == "left" then
			hand.Position = UDim2.fromOffset(min.X - HAND / 2 - bounce, center.Y)
		elseif handSide == "right" then
			hand.Position = UDim2.fromOffset(max.X + HAND / 2 + bounce, center.Y)
		else
			hand.Position = UDim2.fromOffset(center.X, min.Y - HAND / 2 - bounce)
		end
	end

	local function focus(newTarget: GuiObject?, side: Side?)
		target = newTarget
		handSide = side or "right"
		if newTarget and not connection then
			connection = RunService.RenderStepped:Connect(draw)
			draw()
		elseif not newTarget then
			if connection then
				connection:Disconnect()
				connection = nil
			end
			setVisible(false)
		end
	end

	return { focus = focus }
end

return TutorialSpotlight
