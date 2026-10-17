--!strict
--[[
	GiantAttacks

	El Salpicón del gigante furioso, del lado del cliente:
		1. GiantAttack (a todos): aparece un círculo rojo en el piso con un
		   relleno que crece durante todo el aviso (telegraphSeconds). Grande y
		   claro para móvil y ping alto. Suena un llamado grave.
		2. Al terminar el aviso cae una columna de agua con salpicadura,
		   estruendo y sacudida de cámara para quien esté cerca.
		3. GiantHit (solo al golpeado): el cliente aplica el empujón lejos del
		   gigante. Nunca se pierde nada que se llevaba (si le picaba un pez,
		   ese pez se escapa).
	Si el círculo cae sobre el jugador local, además ve un cartel y una
	cuenta regresiva grande.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local GroundFx = require(script.Parent.Parent.Effects.GroundFx)
local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)
local GiantName = require(script.Parent.Parent.GiantName)
local Toasts = require(script.Parent.Parent.Toasts)

local ANGER = Config.Giants.anger
local DANGER = UIConfig.Colors.Furious
local UP = CFrame.Angles(0, 0, math.rad(90)) -- un cilindro acostado de lado queda como disco

local GiantAttacks = {}

local function disc(name: string, position: Vector3, diameter: number, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, diameter, diameter)
	part.CFrame = CFrame.new(position) * UP
	part.Color = DANGER
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = Workspace
	return part
end

-- Encuentra el piso bajo el punto marcado para que el círculo no flote.
local function groundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local characters = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	params.FilterDescendantsInstances = characters
	local hit = Workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
	return if hit then hit.Position + Vector3.new(0, 0.12, 0) else position
end

local function telegraph(position: Vector3, radius: number, seconds: number)
	local ground = groundAt(position)
	local outer = disc("AvisoSalpicon", ground, radius * 2, 0.55)
	local inner = disc("Carga", ground + Vector3.new(0, 0.05, 0), 0.5, 0.25)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Linear)
	TweenService:Create(inner, info, { Size = Vector3.new(0.2, radius * 2, radius * 2) }):Play()
	-- El borde parpadea cada vez más rápido.
	task.spawn(function()
		local finish = os.clock() + seconds
		while os.clock() < finish do
			local left = finish - os.clock()
			outer.Transparency = if outer.Transparency > 0.4 then 0.15 else 0.55
			task.wait(math.clamp(left / 6, 0.06, 0.25))
		end
	end)
	Sounds.play("OrcaCall", ground, 0.5)
	Debris:AddItem(outer, seconds + 0.1)
	Debris:AddItem(inner, seconds + 0.1)

	task.delay(seconds, function()
		GroundFx.impact(ground, 5, radius * 1.3)
		if not CraterMode.isSand() then
			Fx.spout(ground, 2.2)
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local distance = (root.Position - ground).Magnitude
			if distance < radius * 3 then
				CameraShake.shake(1.2 * (1 - distance / (radius * 3)) + 0.2, 0.6)
			end
		end
	end)
end

-- Si el círculo cae sobre el jugador local: cartel y cuenta regresiva grande.
local function warnIfInside(
	screen: ScreenGui,
	toasts: Toasts.Toasts,
	position: Vector3,
	radius: number,
	seconds: number
)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local offset = character:GetPivot().Position - position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > radius + 4 then
		return
	end
	toasts.banner("¡Salpicón! ¡Sal del círculo rojo!", DANGER)
	local label = Instance.new("TextLabel")
	label.Name = "CuentaAtaque"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.42)
	label.Size = UDim2.fromScale(0.2, 0.2)
	label.BackgroundTransparency = 1
	label.FontFace = UIConfig.Fonts.Title
	label.TextScaled = true
	label.TextColor3 = DANGER
	label.TextStrokeColor3 = UIConfig.Colors.TextStroke
	label.TextStrokeTransparency = 0
	label.Parent = screen
	task.spawn(function()
		for left = math.ceil(seconds), 1, -1 do
			label.Text = tostring(left)
			label.TextTransparency = 0
			TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 0.6 }):Play()
			task.wait(seconds / math.ceil(seconds))
		end
		label:Destroy()
	end)
end

local function knockback(from: Vector3)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end
	local away = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z)
	local direction = if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = direction * ANGER.knockbackSpeed + Vector3.new(0, 45, 0)
	CameraShake.shake(1.4, 0.5)
end

function GiantAttacks.start(screen: ScreenGui, toasts: Toasts.Toasts)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local attackEvent = remotes:WaitForChild(Protocol.Remotes.GiantAttack) :: RemoteEvent
	local hitEvent = remotes:WaitForChild(Protocol.Remotes.GiantHit) :: RemoteEvent

	attackEvent.OnClientEvent:Connect(function(position: unknown, radius: unknown, seconds: unknown)
		if
			typeof(position) ~= "Vector3"
			or type(radius) ~= "number"
			or type(seconds) ~= "number"
		then
			return
		end
		telegraph(position, radius, seconds)
		warnIfInside(screen, toasts, position, radius, seconds)
	end)
	hitEvent.OnClientEvent:Connect(function(from: unknown)
		if typeof(from) ~= "Vector3" then
			return
		end
		knockback(from)
		toasts.show(
			`¡Salpicón! Dale de comer a {GiantName.current()} para calmar su furia`,
			DANGER
		)
	end)
end

return GiantAttacks
