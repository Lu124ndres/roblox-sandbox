--!strict
--[[
	PerCatchFlash

	Cuando los peces por pique de un jugador pasan un hito (2, 5, 10, 20, 50,
	100, 200, 500, 1K…: con la fuerza suben a cada rato, así que se celebran
	los saltos grandes), su personaje da un destello azul de 1 segundo que ven
	todos cerca: cuerpo iluminado (Highlight), columna de luz, aro en el suelo,
	chispas, luz azul y el número sobre la cabeza. No al entrar ni al cargar
	el guardado; al dueño le suena y avisa.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local Distance = require(script.Parent.Distance)
local Style = require(script.Parent.Parent.Interface.Style)

local ATTR = Protocol.PlayerAttributes
local BLUE = Color3.fromRGB(70, 170, 255)
local WHITE_BLUE = Color3.fromRGB(190, 235, 255)
local SECONDS, MAX_DISTANCE = 1, 220 -- duración y distancia máxima a la que se dibuja

local PerCatchFlash = {}

local function part(name: string, size: Vector3, cframe: CFrame): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Color = BLUE
	item.Material = Enum.Material.Neon
	item.Anchored = true
	item.CanCollide = false
	item.CanQuery = false
	item.CanTouch = false
	item.CastShadow = false
	item.Parent = Workspace
	Debris:AddItem(item, SECONDS + 0.2)
	return item
end

-- `hold`: segundos a toda intensidad antes de empezar a apagarse.
local function tween(item: Instance, seconds: number, goal: { [string]: any }, hold: number?)
	local info = TweenInfo.new(
		seconds - (hold or 0),
		Enum.EasingStyle.Quad,
		if hold then Enum.EasingDirection.In else Enum.EasingDirection.Out,
		0,
		false,
		hold or 0
	)
	TweenService:Create(item, info, goal):Play()
end

local function label(root: BasePart, perCatch: number)
	local board = Instance.new("BillboardGui")
	board.Name = "MasPeces"
	board.Size = UDim2.fromOffset(240, 60)
	board.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.Adornee = root
	board.Parent = root
	local text = Style.text(board, "Texto", 60, WHITE_BLUE, 3)
	text.Size = UDim2.fromScale(1, 1)
	text.Text = `¡{NumberFormat.short(perCatch)}+ PECES POR PIQUE!`
	local stroke = text:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = Color3.fromRGB(10, 40, 90)
	tween(board, SECONDS * 1.3, { StudsOffsetWorldSpace = Vector3.new(0, 7, 0) })
	tween(text, SECONDS * 1.3, { TextTransparency = 1 }, 0.6)
	tween(stroke, SECONDS * 1.3, { Transparency = 1 }, 0.6)
	Debris:AddItem(board, SECONDS * 1.3 + 0.1)
end

local function flash(character: Model, perCatch: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	if Distance.fromCamera(root.Position) > MAX_DISTANCE then
		return
	end
	local feet = root.Position - Vector3.new(0, 3, 0)

	-- Cuerpo azul que se apaga.
	local glow = Instance.new("Highlight")
	glow.FillColor = BLUE
	glow.OutlineColor = WHITE_BLUE
	glow.FillTransparency = 0.15
	glow.OutlineTransparency = 0
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = character
	tween(glow, SECONDS, { FillTransparency = 1, OutlineTransparency = 1 }, 0.4)
	Debris:AddItem(glow, SECONDS + 0.1)

	-- Columna de luz que sube y se adelgaza.
	local beam = part(
		"Columna",
		Vector3.new(0.5, 6, 6),
		CFrame.new(feet) * CFrame.Angles(0, 0, math.rad(90))
	)
	beam.Shape = Enum.PartType.Cylinder
	beam.Transparency = 0.25
	tween(beam, SECONDS, {
		Size = Vector3.new(26, 0.4, 0.4),
		CFrame = CFrame.new(feet + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
	})

	local ring = part(
		"Aro",
		Vector3.new(0.2, 3, 3),
		CFrame.new(feet + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	)
	ring.Shape = Enum.PartType.Cylinder
	ring.Transparency = 0.2
	tween(ring, SECONDS * 0.7, { Size = Vector3.new(0.2, 16, 16), Transparency = 1 })

	local burst = Instance.new("ParticleEmitter")
	burst.Texture = Assets.Particles.Sparkle
	burst.Color = ColorSequence.new(WHITE_BLUE, BLUE)
	burst.LightEmission = 1
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	burst.Lifetime = NumberRange.new(0.5, 0.9)
	burst.Speed = NumberRange.new(10, 18)
	burst.SpreadAngle = Vector2.new(35, 35)
	burst.Acceleration = Vector3.new(0, -12, 0)
	burst.Drag = 2
	burst.Enabled = false
	burst.Parent = root
	burst:Emit(28)
	Debris:AddItem(burst, SECONDS + 0.5)
	local light = Instance.new("PointLight")
	light.Color = BLUE
	light.Range = 18
	light.Brightness = 6
	light.Parent = root
	tween(light, SECONDS, { Brightness = 0 }, 0.3)
	Debris:AddItem(light, SECONDS + 0.1)

	label(root, perCatch)
end

local function watch(player: Player, toasts: Toasts.Toasts)
	local known: number? = nil
	local function check()
		if player:GetAttribute(ATTR.DataLoaded) ~= true then
			return -- mientras carga el guardado el poder salta: no cuenta
		end
		local perCatch = NumberFormat.milestone(FishingPower.playerFishPerCatch(player))
		local before = known
		known = perCatch
		if before == nil or perCatch <= before then
			return
		end
		local character = player.Character
		if character then
			flash(character, perCatch)
		end
		if player == Players.LocalPlayer then
			Sounds.play("StageUp", nil, 1.3)
			toasts.banner(
				`¡Ahora sacas más de {NumberFormat.short(perCatch)} peces por pique!`,
				BLUE
			)
		end
	end
	player:GetAttributeChangedSignal(ATTR.Power):Connect(check)
	player:GetAttributeChangedSignal("Rod"):Connect(check) -- la caña y la canasta también cuentan
	player:GetAttributeChangedSignal("Basket"):Connect(check)
	player:GetAttributeChangedSignal(ATTR.DataLoaded):Connect(check)
	check()
end

function PerCatchFlash.start(toasts: Toasts.Toasts)
	Players.PlayerAdded:Connect(function(player: Player)
		watch(player, toasts)
	end)
	for _, player in Players:GetPlayers() do
		watch(player, toasts)
	end
end

return PerCatchFlash
