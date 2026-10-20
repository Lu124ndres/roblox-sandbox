--!strict
--[[
	Showcase

	Vitrinas de los trajes de pase en la zona de entrenamiento, del lado de
	los estanques para principiantes (WorldLayout.showcaseAngle), mirando al
	centro del jardín: el escenario en el color del
	traje (Social/ShowcaseStage: pedestal hexagonal con aros de luz, haz,
	rayos, aura y cartel con precio, nombre y ventajas), el traje de malla en
	grande flotando en su pose (lo animan los clientes: client/Trajes/Vitrinas)
	y E para comprarlo. La compra la abre el cliente (Purchases);
	si ya tiene el pase, E aquí se lo pone o se lo quita (vuelve a Marinero,
	atributo TrajeElegido, que lee Outfits).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Proximity = require(script.Parent.Parent.Proximity)
local RateLimit = require(script.Parent.Parent.RateLimit)
local OutfitChoice = require(script.Parent.OutfitChoice)
local ShowcaseAura = require(script.Parent.ShowcaseAura)
local ShowcaseSign = require(script.Parent.ShowcaseSign)
local ShowcaseStage = require(script.Parent.ShowcaseStage)

local L = WorldLayout
local PASSES = Config.Monetization.passes
local DISPLAY_HEIGHT = 12 -- alto del traje en la vitrina (studs)
local HOVER = 1.2 -- el traje flota sobre el pedestal (studs)
local PROMPT_DISTANCE = 16

local Showcase = {}

local limiter = RateLimit.new("Vitrina", 1, 2)

-- El traje en grande, parado sobre el pedestal y mirando hacia `look`.
local function display(outfit: string, top: Vector3, look: Vector3): Model?
	local template = ServerStorage:FindFirstChild(Trajes.templateName(outfit))
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	local mesh = Trajes.mesh(model)
	if not mesh then
		model:Destroy()
		return nil
	end
	local _, _, height = Trajes.measure(mesh)
	model:ScaleTo(model:GetScale() * DISPLAY_HEIGHT / height)
	local frame = Trajes.measure(mesh)
	local target = CFrame.lookAt(top, top + look)
	model:PivotTo(target * frame:ToObjectSpace(model:GetPivot()))
	model.WorldPivot = target -- gira sobre sus pies (client/Trajes/Vitrinas)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	model.Name = "Muestra"
	model:SetAttribute("Outfit", outfit)
	return model
end

local function onTriggered(player: Player, passKey: string)
	if limiter(player) then
		OutfitChoice.toggle(player, passKey) -- sin el pase, el cliente abre la compra
	end
end

local function build(folder: Folder, passKey: string, side: number)
	local outfit = PASSES[passKey].outfit :: string
	local angle = math.rad(L.showcaseAngle)
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local tangent = Vector3.new(-out.Z, 0, out.X)
	local ground = out * L.showcaseRadius
		+ tangent * L.showcaseSide * side
		+ Vector3.new(0, L.plateauHeight, 0)
	local model = Instance.new("Model")
	model.Name = passKey
	model:SetAttribute("Pase", passKey)
	model:SetAttribute("Outfit", outfit)
	local look = ShowcaseStage.LOOKS[outfit]
	local top, button, base = ShowcaseStage.pedestal(model, ground, look)
	-- Mira al centro del jardín: quien cruza hacia los estanques para principiantes la ve de frente.
	local toward = Vector3.new(-ground.X, 0, -ground.Z).Unit
	local feet = top + Vector3.new(0, HOVER, 0)
	local shown = display(outfit, feet, toward)
	if shown then
		shown.Parent = model
	end
	ShowcaseStage.beam(button, HOVER, look)
	ShowcaseAura.build(model, feet, DISPLAY_HEIGHT, look)
	ShowcaseSign.build(base, passKey, DISPLAY_HEIGHT + HOVER + 1, look)
	local prompt = Proximity.makePrompt(base, "Comprar", PASSES[passKey].name, PROMPT_DISTANCE)
	prompt.Name = "Comprar"
	prompt.Triggered:Connect(function(player: Player)
		onTriggered(player, passKey)
	end)
	model.Parent = folder
end

function Showcase.init()
	local folder = Instance.new("Folder")
	folder.Name = "Vitrinas"
	local side = -1
	for _, passKey in Config.Monetization.passOrder do
		if PASSES[passKey].outfit then
			build(folder, passKey, side)
			side = -side
		end
	end
	folder.Parent = Workspace
end

return table.freeze(Showcase)
