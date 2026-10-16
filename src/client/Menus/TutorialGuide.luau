--!strict
--[[
	TutorialGuide

	Guía del primer minuto: un panel a la derecha con la misión actual
	(Config.Retention.tutorial) y su avance, y un marcador en el mundo que
	flota sobre el destino (el muelle más cercano, el puente y la puerta del
	volcán, un estanque o la tienda) con la distancia. Desaparece al
	terminar. El avance lo decide el servidor (atributos Tutorial y
	TutorialCount).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Ui = require(script.Parent.Parent.Ui)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local ATTR = Protocol.PlayerAttributes
local STEPS = Config.Retention.tutorial

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
	Style.border(panel, 3)
	if touchOnly then
		-- Un poco a la izquierda del centro: a la derecha abajo van Pescar y ¡TIRA!.
		panel.AnchorPoint = Vector2.new(0.5, 1)
		panel.Position = UDim2.new(0.5, -40, 1, -8)
		Layout.scaleWith(panel)
	end
	local title = Ui.label("Titulo", panel, UIConfig.Fonts.Title, UIConfig.TextSizes.Small)
	title.TextColor3 = COLORS.Coins
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 18)
	local text = Ui.label("Texto", panel, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Position = UDim2.fromOffset(8, 23)
	text.Size = UDim2.new(1, -16, 0, 44)

	-- Marcador en el mundo: flecha que flota sobre el destino, siempre visible.
	local anchor = Instance.new("Attachment")
	anchor.Name = "DestinoTutorial"
	anchor.Parent = Workspace.Terrain
	local marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromOffset(90, 58)
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.Adornee = anchor
	marker.Enabled = false
	marker.Parent = anchor
	local arrow = Ui.label("Flecha", marker, UIConfig.Fonts.Title, 48)
	arrow.Text = "▼"
	arrow.TextColor3 = COLORS.Coins
	arrow.Size = UDim2.fromScale(1, 0.65)
	local distance = Ui.label("Distancia", marker, UIConfig.Fonts.Title, UIConfig.TextSizes.Small)
	distance.Position = UDim2.fromScale(0, 0.65)
	distance.Size = UDim2.fromScale(1, 0.35)

	local function step(): number
		local value = player:GetAttribute(ATTR.Tutorial)
		return (if type(value) == "number" then value else 0) + 1
	end

	local function refresh()
		local index = step()
		local current = STEPS[index]
		local loaded = player:GetAttribute(ATTR.DataLoaded) == true
		panel.Visible = loaded and current ~= nil
		marker.Enabled = panel.Visible
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

	RunService.Heartbeat:Connect(function()
		local current = STEPS[step()]
		local character = player.Character
		if not current or not marker.Enabled or not character then
			return
		end
		local position = character:GetPivot().Position
		local target = targetFor(current.id, position)
		anchor.WorldPosition = target + Vector3.new(0, 7 + math.sin(os.clock() * 3) * 0.8, 0)
		distance.Text = `{math.floor((target - position).Magnitude)} m`
	end)
end

return TutorialGuide
