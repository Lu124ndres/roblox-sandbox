--!strict
--[[
	TutorialBanner

	La línea de objetivo del tutorial (como la de referencias/Ejemplo.mp4):
	una franja oscura y angosta abajo al centro (arriba tapaba el cartel sobre
	la cabeza del personaje y los avisos; abajo, entre los controles, está libre),
	con lo que hay que hacer y el avance en dorado («Pesca 3 peces  1/3») y,
	debajo, cómo se hace («Mantén E mirando al mar»). Es chica y no se mueve
	sola, para no molestar (pedido del usuario); el anuncio grande de cada
	paso lo hace TutorialCallout. Se anima solo cuando pasa algo:
		bump   el avance subió: un «+1» verde salta al lado y la franja late
		done   «¡LISTO! +25» en verde un momento
	Solo muestra: el paso y el avance los decide el servidor.
]]

local TweenService = game:GetService("TweenService")

local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WIDTH, HEIGHT = 440, 64
local SCALE_TOUCH = 0.75
local BOTTOM = 24 -- píxeles desde abajo
local WHITE = Color3.new(1, 1, 1)
local SOFT = Color3.fromRGB(215, 222, 230)
local DONE = Color3.fromRGB(120, 240, 130)
local GOLD_HEX = "FFD24A"
local STRIP = Color3.fromRGB(16, 14, 12)
local STRIP_SEE_THROUGH = 0.35
local POP = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RISE = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type Banner = {
	set: (title: string, progress: string, hint: string) -> (),
	bump: (amount: number) -> (),
	done: (coins: number) -> (),
	show: (visible: boolean) -> (),
}

local TutorialBanner = {}

function TutorialBanner.new(screen: ScreenGui): Banner
	local root = Instance.new("Frame")
	root.Name = "Tutorial"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -BOTTOM)
	root.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	root.BackgroundColor3 = STRIP
	root.BackgroundTransparency = STRIP_SEE_THROUGH
	root.Visible = false
	root.ZIndex = 41 -- por encima del velo del paso de comprar (TutorialSpotlight)
	root.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = root
	Layout.scaleWith(root)
	local device = Instance.new("UIScale")
	device.Scale = if Device.touch() then SCALE_TOUCH else 1
	device.Parent = root
	local pop = Instance.new("UIScale")
	pop.Parent = root

	-- Un solo texto con el avance en dorado (texto enriquecido).
	local title = Style.text(root, "Titulo", 28, WHITE, 2)
	title.RichText = true
	title.Position = UDim2.fromOffset(12, 4)
	title.Size = UDim2.new(1, -24, 0, 32)
	local hint = Style.text(root, "Como", 19, SOFT, 1.5)
	hint.Position = UDim2.fromOffset(12, 36)
	hint.Size = UDim2.new(1, -24, 0, 22)

	local function beat(scale: number)
		pop.Scale = scale
		TweenService:Create(pop, POP, { Scale = 1 }):Play()
	end

	local function set(titleText: string, progressText: string, hintText: string)
		title.Text = if progressText ~= ""
			then `{titleText}  <font color="#{GOLD_HEX}">{progressText}</font>`
			else titleText
		title.TextColor3 = WHITE
		hint.Text = hintText
	end

	-- «+N» verde que sube y se va, al lado derecho de la franja.
	local function bump(amount: number)
		local plus = Style.text(root, "Mas", 40, DONE, 3)
		plus.Text = `+{amount}`
		plus.AnchorPoint = Vector2.new(0, 0.5)
		plus.Position = UDim2.new(1, 8, 0.5, 0)
		plus.Size = UDim2.fromOffset(90, 48)
		plus.TextXAlignment = Enum.TextXAlignment.Left
		TweenService
			:Create(plus, RISE, { Position = UDim2.new(1, 8, 0.5, -36), TextTransparency = 1 })
			:Play()
		task.delay(RISE.Time, function()
			plus:Destroy()
		end)
		beat(1.12)
	end

	-- «¡LISTO! +25» en verde; quien llama vuelve a poner el paso siguiente con `set`.
	local function done(coins: number)
		title.Text = if coins > 0
			then `¡LISTO!  <font color="#{GOLD_HEX}">+{coins}</font>`
			else "¡LISTO!"
		title.TextColor3 = DONE
		hint.Text = ""
		beat(1.2)
	end

	return {
		set = set,
		bump = bump,
		done = done,
		show = function(visible: boolean)
			root.Visible = visible
		end,
	}
end

return TutorialBanner
