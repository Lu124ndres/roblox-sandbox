--!strict
-- Prueba temporal: director del tráiler (solo en Studio). Sigue el atributo
-- TrailerEscena que pone el servidor: cámara, textos grandes, pesca y amigos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
if not RunService:IsStudio() then
	return
end
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local BasketBuilder = require(script.Parent.Effects.BasketBuilder)
local Camara = require(script.Parent.PruebaTrailerCamara)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera :: Camera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local TEXTOS: { [number]: string } = {
	[1] = "¡PESCA EN LA ORILLA!",
	[2] = "¡LLENA TU CANASTA!",
	[3] = "¡LLÉVALOS AL VOLCÁN!",
	[4] = "¡ALIMENTA AL GIGANTE!",
	[5] = "¡HAZLO CRECER!",
	[6] = "¡JUEGA CON AMIGOS!",
	[7] = "¡NO DEJES QUE SE ENOJE!",
	[8] = "¡ENTRENA EN EL VOLCÁN!",
	[9] = "GIGANTES DEL VOLCÁN",
}

local gui = Instance.new("ScreenGui")
gui.Name = "Trailer"
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
flash.Visible = false
flash.Parent = gui
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.2)
label.Size = UDim2.fromScale(0.9, 0.16)
label.BackgroundTransparency = 1
label.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Text = ""
local stroke = Instance.new("UIStroke")
stroke.Thickness = 7
stroke.Color = Color3.fromRGB(20, 20, 30)
stroke.Parent = label
local pop = Instance.new("UIScale")
pop.Parent = label
label.Parent = gui

local brillo = Instance.new("ColorCorrectionEffect")
brillo.Name = "TrailerBrillo"
brillo.Brightness = 0.1
brillo.Contrast = 0.12
brillo.Saturation = 0.25
brillo.Enabled = false
brillo.Parent = game:GetService("Lighting")

local escena, inicio = -1, os.clock()
local function mostrar(texto: string?)
	label.Text = texto or ""
	label.Rotation = math.random(-4, 4)
	label.TextColor3 = if escena == 9 then Color3.fromRGB(255, 214, 64) else Color3.new(1, 1, 1)
	label.Position = UDim2.fromScale(0.5, if escena == 9 then 0.45 else 0.2)
	pop.Scale = 0.3
	TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Pesca sola durante la escena 1.
local fishing = remotes:WaitForChild("FishingUpdate") :: RemoteEvent
local cast = remotes:WaitForChild("CastRequest") :: RemoteEvent
local reel = remotes:WaitForChild("ReelIn") :: RemoteEvent
fishing.OnClientEvent:Connect(function(state: unknown)
	if escena ~= 1 then
		return
	end
	if state == "bite" then
		task.wait(0.25)
		reel:FireServer()
	elseif state == "caught" or state == "escaped" then
		task.wait(1)
		cast:FireServer()
	end
end)

local amigos: { Model } = {}
local function crearAmigos(root: BasePart)
	local toCenter = Vector3.new(
		WorldZones.craterCenter.X - root.Position.X,
		0,
		WorldZones.craterCenter.Z - root.Position.Z
	).Unit
	local side = Vector3.new(-toCenter.Z, 0, toCenter.X)
	local colores = {
		BrickColor.new("Bright red"),
		BrickColor.new("Bright blue"),
		BrickColor.new("Lime green"),
		BrickColor.new("Bright yellow"),
		BrickColor.new("Hot pink"),
	}
	for i = 1, 5 do
		local desc = Instance.new("HumanoidDescription")
		desc.TorsoColor = colores[i].Color
		desc.HeadColor = Color3.fromRGB(255, 204, 153)
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if ok and model then
			local offset = side * ((i - 3) * 5) - toCenter * (math.abs(i - 3) * 2)
			local pos = root.Position + offset
			model:PivotTo(CFrame.lookAt(pos, pos + toCenter))
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.Anchored = true
			end
			model.Parent = Workspace
			BasketBuilder.build(model, i + 1)
			table.insert(amigos, model)
		end
	end
end

Workspace:GetAttributeChangedSignal("TrailerEscena"):Connect(function()
	escena = Workspace:GetAttribute("TrailerEscena") :: number
	inicio = os.clock()
	local root = player.Character
		and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	flash.Visible = escena == 0
	camera.CameraType = Enum.CameraType.Scriptable
	mostrar(TEXTOS[escena])
	local daily = player.PlayerGui:FindFirstChild("Juego")
		and player.PlayerGui.Juego:FindFirstChild("Diario")
	if daily and daily:IsA("GuiObject") then
		daily.Visible = false
	end
	if escena == 1 then
		task.wait(0.6)
		cast:FireServer()
	elseif escena == 3 and root then
		local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
		local _, bridgeEnd = WorldZones.bridgeEnds()
		if humanoid then
			humanoid:MoveTo(bridgeEnd)
		end
	elseif escena == 4 then
		task.wait(0.5)
		local feed = remotes:WaitForChild("FeedRequest") :: RemoteEvent
		feed:FireServer()
	elseif escena == 6 and root then
		crearAmigos(root)
	elseif escena == 8 then
		for _, model in amigos do
			model:Destroy()
		end
	elseif escena == 10 then
		camera.CameraType = Enum.CameraType.Custom
	end
end)

RunService.RenderStepped:Connect(function()
	if escena < 1 or escena >= 10 then
		return
	end
	local root = player.Character
		and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	camera.FieldOfView = if escena == 4 then 40 elseif escena == 5 or escena == 7 then 55 else 70
	brillo.Enabled = escena >= 4 and escena <= 9
	local cf = Camara.para(escena, os.clock() - inicio, root)
	if cf then
		camera.CFrame = cf
	end
end)
