--!strict
--[[
	TutorialGuide

	Guía del primer minuto: una placa de piedra (Interface/Kit) con la misión
	actual (Config.Retention.tutorial, el título en dorado) y su avance, y una
	línea recta de flechas amarillas flotando que sale del jugador y apunta al
	destino, en tramos rectos (GuidePath y GuideArrow: al volcán, primero a la
	entrada del puente y después por el puente) hasta el destino (el
	muelle más cercano, la puerta del volcán, un estanque o la tienda). Al
	llegar, las flechas se van; nada queda puesto en el mapa. Desaparece al
	terminar. El avance lo decide el servidor (atributos Tutorial y
	TutorialCount).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Ui = require(script.Parent.Parent.Ui)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local GuidePath = require(script.Parent.GuidePath)

local ATTR = Protocol.PlayerAttributes
local STEPS = Config.Retention.tutorial
local PLATE_SLICE = 0.3 -- borde de la placa más fino que en las ventanas
local ARRIVE = 12 -- studs del destino a los que la flecha se va

local TutorialGuide = {}

local function polar(angle: number, radius: number, y: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
end

-- A dónde tiene que ir el jugador para la misión `id`.
local function targetFor(id: string, position: Vector3): Vector3
	if id == "pescar" then
		local best, bestDistance = Vector3.zero, math.huge
		for _, angle in WorldLayout.pierAngles do
			local tip = polar(
				angle,
				WorldLayout.pierStartRadius + WorldLayout.pierLength - 6,
				WorldLayout.deckHeight
			)
			local distance = (tip - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = tip, distance
			end
		end
		return best
	elseif id == "alimentar" then
		local start, finish = WorldZones.bridgeEnds()
		local onTheWay = WorldZones.isOnBridge(position)
			or WorldZones.distanceToCrater(position) < WorldLayout.craterBaseRadius
		return if onTheWay then finish else start
	elseif id == "entrenar" then
		return WorldZones.pondCenter(1)
	end
	return polar(WorldLayout.shopAngle, WorldLayout.shopRadius, WorldLayout.plateauHeight)
end

function TutorialGuide.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	-- En PC, en la columna izquierda debajo de las estadísticas. En pantallas
	-- táctiles, abajo al centro: a la izquierda estorbaría al joystick.
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local panel = Ui.panel("Mision", if touchOnly then screen else Layout.left())
	panel.LayoutOrder = 20
	panel.Size = UDim2.fromOffset(230, 70)
	panel.Visible = false
	Kit.skin(panel, "panel").SliceScale = PLATE_SLICE
	if touchOnly then
		-- Un poco a la izquierda del centro: a la derecha abajo van Pescar y ¡TIRA!.
		panel.AnchorPoint = Vector2.new(0.5, 1)
		panel.Position = UDim2.new(0.5, -40, 1, -8)
		Layout.scaleWith(panel)
	end
	local title = Style.text(panel, "Titulo", UIConfig.TextSizes.Small, nil, 2)
	Kit.gold(title)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(10, 6)
	title.Size = UDim2.new(1, -20, 0, 18)
	local text = Ui.label("Texto", panel, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Position = UDim2.fromOffset(10, 25)
	text.Size = UDim2.new(1, -20, 0, 40)

	local route = GuidePath.new()

	local function step(): number
		local value = player:GetAttribute(ATTR.Tutorial)
		return (if type(value) == "number" then value else 0) + 1
	end

	local function refresh()
		local index = step()
		local current = STEPS[index]
		local loaded = player:GetAttribute(ATTR.DataLoaded) == true
		panel.Visible = loaded and current ~= nil
		if not current then
			return
		end
		local count = player:GetAttribute(ATTR.TutorialCount)
		local progress = if current.goal > 1
			then ` ({if type(count) == "number" then count else 0}/{current.goal})`
			else ""
		title.Text = `Misión {index}/{#STEPS}`
		-- Las tres primeras se hacen con el botón de acción: se dice cuál.
		local key = if index <= 3 and InputHints.mode() ~= "touch"
			then ` ({InputHints.action()})`
			else ""
		text.Text = current.text .. key .. progress
	end
	for _, attribute in { ATTR.Tutorial, ATTR.TutorialCount, ATTR.DataLoaded } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	InputHints.onChange(refresh)
	refresh()

	RunService.Heartbeat:Connect(function(dt: number)
		local current = STEPS[step()]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not current or not panel.Visible or not (root and root:IsA("BasePart")) then
			route.hide()
			return
		end
		local position = root.Position
		local target = targetFor(current.id, position)
		if (target - position).Magnitude < ARRIVE then
			route.hide()
			return
		end
		route.update(position, target, os.clock(), dt)
	end)
end

return TutorialGuide
