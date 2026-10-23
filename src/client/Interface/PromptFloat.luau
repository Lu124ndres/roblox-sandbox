--!strict
--[[
	PromptFloat

	El cartel de PromptView cuando flota sobre el objeto (BillboardGui): en PC y
	mando siempre, y en táctil los prompts con el atributo Flotante (los
	estanques de entrenamiento: una placa en el centro de cada estanque, pedido
	del usuario, en vez de la de abajo junto a Saltar).
	Mide lo mismo en píxeles a cualquier distancia y se achica con el HUD
	(Layout.scale), pero en táctil no baja de TOUCH_MIN_SCALE para que se pueda
	tocar. La placa se arma a su tamaño completo dentro de `frame` y un UIScale
	la encaja en el cartel.
	Los de los estanques (`onWater`) van bajitos, sobre el agua y debajo del
	cartel del estanque (Training/PondSigns), y sin AlwaysOnTop: con él, a 3 studs,
	quedaban encima de ese cartel y en Studio ni se veían en las capturas.
	Además miden lo mismo en el mundo (WATER_WIDTH_STUDS), no en la pantalla:
	con medida en píxeles, al alejar la cámara el estanque se achicaba y el
	botón no, y parecía crecer (pedido del usuario, 2026-10-22, en celular).
]]

local Device = require(script.Parent.Device)
local Layout = require(script.Parent.Layout)

local TOUCH_MIN_SCALE = 0.6
local LIFT_STUDS = 3 -- cuánto sobre el objeto
local WATER_LIFT_STUDS = 1.5 -- los de los estanques: apenas sobre el agua
local WATER_WIDTH_STUDS = 7 -- ancho de la placa de los estanques (el estanque mide 12.5)

local PromptFloat = {}

-- Dónde se ancla el cartel: la pieza o el Attachment que tiene el prompt.
local function adornee(prompt: ProximityPrompt): Instance?
	local parent = prompt.Parent
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment") or parent:IsA("Model")) then
		return parent
	end
	return nil
end

-- `size`: medida de la placa antes de escalar. Devuelve el cartel y el marco donde va.
function PromptFloat.make(
	prompt: ProximityPrompt,
	size: Vector2,
	onWater: boolean
): (BillboardGui, Frame)
	local scale = Layout.scale()
	if Device.touch() then
		scale = math.max(scale, TOUCH_MIN_SCALE)
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "AvisoAccion"
	gui.Adornee = adornee(prompt)
	gui.AlwaysOnTop = not onWater
	gui.Size = if onWater
		then UDim2.fromScale(WATER_WIDTH_STUDS, WATER_WIDTH_STUDS * size.Y / size.X)
		else UDim2.fromOffset(size.X * scale, size.Y * scale)
	gui.StudsOffsetWorldSpace = Vector3.new(0, if onWater then WATER_LIFT_STUDS else LIFT_STUDS, 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Name = "Marco"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.Parent = gui
	local fit = Instance.new("UIScale")
	fit.Scale = scale
	fit.Parent = frame
	if onWater then
		-- El cartel cambia de tamaño en pantalla con la distancia: la placa lo sigue.
		local function refit()
			fit.Scale = math.max(gui.AbsoluteSize.X / size.X, 0.01)
		end
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
		refit()
	end
	return gui, frame
end

return PromptFloat
