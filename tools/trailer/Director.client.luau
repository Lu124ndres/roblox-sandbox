--!strict
--[[
	Director (tráiler, cliente)

	Sigue Workspace.TrailerEscena (lo cambia Director.server): en cada escena
	pone al jugador en su lugar (corte seco, sin fundidos), mueve la cámara
	(Camara), muestra la frase (Textos) y hace lo que haría el jugador: pescar,
	cruzar el puente, alimentar, entrenar, abrir MEJORAS. La interfaz del juego
	se oculta salvo en MEJORAS, para que no abrume. Solo corre en Studio; se
	mete a mano con tools/trailer/preparar.lua y se borra después.
		Workspace.TrailerIdioma   "es" (por defecto) o "en"
		escena "destello"         pantalla magenta: marca el principio y el fin
		                          del video para recortarlo (grabar.py)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Camara = require(script.Camara)
local Textos = require(script.Textos)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera :: Camera
local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
local GIANT = "ZorroDeAgua"

local FRASES = {
	es = {
		pesca = "¡PESCA EN LA ISLA!",
		puente = "¡LLÉVALOS AL VOLCÁN!",
		alimenta = "¡ALIMENTA AL GIGANTE!",
		entrena = "¡HAZTE MÁS FUERTE!",
		amigos = "¡JUEGA CON AMIGOS!",
		crece = "¡Y HAZLO EVOLUCIONAR!",
		titulo = "ALIMENTA A\nLOS GIGANTES",
	},
	en = {
		pesca = "CATCH FISH!",
		puente = "BRING THEM TO THE VOLCANO!",
		alimenta = "FEED THE GIANT!",
		entrena = "GET STRONGER!",
		amigos = "PLAY WITH FRIENDS!",
		crece = "AND WATCH IT EVOLVE!",
		titulo = "FEED THE\nGIANTS",
	},
}

-- Interfaz del tráiler: el destello magenta, el fundido final y las frases.
local gui = Instance.new("ScreenGui")
gui.Name = "Trailer"
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
flash.BorderSizePixel = 0
flash.Visible = false
flash.ZIndex = 10
flash.Parent = gui
local fade = Instance.new("Frame")
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BorderSizePixel = 0
fade.BackgroundTransparency = 1
fade.ZIndex = 9
fade.Parent = gui

-- La interfaz del juego y los carteles 3D (el nombre sobre el jugador, los de los
-- estanques) se apagan mientras dura el video, y se devuelven al final.
local hidden: { [LayerCollector]: boolean } = {}
local showGame = false
local function hide(layer: LayerCollector, visible: boolean)
	if hidden[layer] == nil then
		hidden[layer] = layer.Enabled
	end
	layer.Enabled = visible
end
local function applyHud()
	for _, child in player.PlayerGui:GetDescendants() do
		if child:IsA("ScreenGui") and child ~= gui then
			hide(child, showGame and child.Name == "Juego")
		elseif child:IsA("BillboardGui") then
			hide(child, false)
		end
	end
	for _, child in Workspace:GetDescendants() do
		if child:IsA("BillboardGui") then
			hide(child, false)
		end
	end
end
local function restoreHud()
	for layer, enabled in hidden do
		if layer.Parent then
			layer.Enabled = enabled
		end
	end
	table.clear(hidden)
end
player.PlayerGui.ChildAdded:Connect(function(child)
	if next(hidden) ~= nil and child:IsA("ScreenGui") then
		task.defer(applyHud)
	end
end)

local escena, inicio = "", os.clock()

local function idioma(): string
	return if Workspace:GetAttribute("TrailerIdioma") == "en" then "en" else "es"
end

local function frase(name: string)
	local text = FRASES[idioma()][name]
	if not text then
		return
	end
	if name == "titulo" then
		Textos.mostrar(gui, text, { y = 0.8, alto = 0.14, dorado = true })
	else
		Textos.mostrar(gui, text, { y = 0.16, alto = 0.105, dura = 2.4 })
	end
end

-- Pesca sola: lanza, recoge cuando pica y vuelve a lanzar.
local fishing = remotes:WaitForChild(Protocol.Remotes.FishingUpdate) :: RemoteEvent
local cast = remotes:WaitForChild(Protocol.Remotes.CastRequest) :: RemoteEvent
local reel = remotes:WaitForChild(Protocol.Remotes.ReelIn) :: RemoteEvent
local feed = remotes:WaitForChild(Protocol.Remotes.FeedRequest) :: RemoteEvent
fishing.OnClientEvent:Connect(function(state: unknown)
	if escena ~= "pesca" then
		return
	end
	if state == "bite" then
		task.spawn(function()
			for _ = 1, 20 do
				reel:FireServer()
				task.wait(0.11)
				if player:GetAttribute(Protocol.PlayerAttributes.FishingState) ~= "bite" then
					break
				end
			end
		end)
	elseif state == "caught" or state == "escaped" then
		task.delay(0.5, function()
			if escena == "pesca" then
				cast:FireServer()
			end
		end)
	end
end)

local function character(): (Model?, Humanoid?)
	local model = player.Character
	return model, model and model:FindFirstChildOfClass("Humanoid")
end

local function ground(x: number, z: number): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = Workspace:Raycast(Vector3.new(x, 220, z), Vector3.new(0, -440, 0), params)
	return Vector3.new(x, (if hit then hit.Position.Y else WorldLayout.plateauHeight) + 3, z)
end

local function place(position: Vector3, lookAt: Vector3)
	local model, humanoid = character()
	if not model then
		return
	end
	model:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))
	if humanoid then
		humanoid:MoveTo(position)
	end
end

-- Un punto del paseo del cráter (entre el acantilado y la pared), a `degrees` de la
-- puerta, mirando al gigante.
local RING_RADIUS = WorldLayout.craterCliffRadius + WorldLayout.craterWalkWidth * 0.45
local function onRing(degrees: number): Vector3
	local door = WorldZones.craterDoor()
	local offset = (Vector3.new(door.X, 0, door.Z) - WorldZones.craterCenter).Unit
	local a = math.rad(degrees)
	local turned = Vector3.new(
		offset.X * math.cos(a) - offset.Z * math.sin(a),
		0,
		offset.X * math.sin(a) + offset.Z * math.cos(a)
	)
	local spot = WorldZones.craterCenter + turned * RING_RADIUS
	-- El rayo baja desde poco más arriba del paseo (más alto pegaría en el techo de la cueva).
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local top = WorldLayout.craterDeckHeight + 30
	local hit = Workspace:Raycast(Vector3.new(spot.X, top, spot.Z), Vector3.new(0, -60, 0), params)
	local floor = if hit then hit.Position.Y else WorldLayout.craterDeckHeight
	return Vector3.new(spot.X, floor + 3, spot.Z)
end

-- El aviso va en una pieza hija del estanque (CentroEntrenar); el índice, en el estanque.
local function pondOf(prompt: Instance): number?
	local pond = prompt:FindFirstAncestor(Protocol.Map.TrainingPond)
	local index = pond and pond:GetAttribute(Protocol.Map.PondIndexAttribute)
	return if type(index) == "number" then index else nil
end

local function trainAtPond(index: number)
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and pondOf(descendant) == index then
			descendant:InputHoldBegin()
			task.wait(0.15)
			descendant:InputHoldEnd()
			return
		end
	end
end

local function giant(): Model?
	local model = Workspace:FindFirstChild(GIANT)
	return if model and model:IsA("Model") then model else nil
end

local function onScene()
	local previous = escena
	escena = Workspace:GetAttribute("TrailerEscena") :: string
	inicio = os.clock()
	if previous == "alimenta" or previous == "amigos" then
		feed:FireServer(false)
	end
	flash.Visible = escena == "destello"
	if escena == "listo" then
		Textos.limpiar()
		fade.BackgroundTransparency = 1
		camera.CameraType = Enum.CameraType.Custom
		showGame = false
		restoreHud()
		return
	end
	if escena == "destello" or escena == "" then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	showGame = false
	applyHud()
	Textos.limpiar()
	frase(escena)

	local craterCenter = WorldZones.craterCenter
	if escena == "pesca" then
		local angle = math.rad(WorldLayout.spawnAngle)
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local spot = outward * (WorldLayout.shoreRadius - Config.Retention.tutorialShoreInset)
		local position = ground(spot.X, spot.Z)
		place(position, position + outward)
		task.wait(0.6)
		cast:FireServer()
	elseif escena == "puente" then
		local bridgeStart, gate = WorldZones.bridgeEnds()
		place(ground(bridgeStart.X, bridgeStart.Z + 10), gate)
		local _, humanoid = character()
		if humanoid then
			humanoid:MoveTo(gate)
		end
	elseif escena == "alimenta" then
		place(onRing(-22), craterCenter)
		Camara.reset(giant())
		task.wait(0.4)
		feed:FireServer(true)
	elseif escena == "entrena" then
		local pond = WorldZones.pondCenter(1)
		place(ground(pond.X, pond.Z - 17), pond)
		task.wait(0.6)
		trainAtPond(1)
	elseif escena == "mejoras" then
		place(ground(WorldLayout.shopRadius - 14, 0), Vector3.new(WorldLayout.shopRadius, 0, 0))
		local juego = player.PlayerGui:FindFirstChild("Juego")
		local window = juego and juego:FindFirstChild("Mejoras")
		local opener = window and window:FindFirstChild("Abrir")
		if opener and opener:IsA("BindableEvent") then
			opener:Fire()
		end
		task.wait(0.45) -- la ventana ya se abrió: se ve sola, sin el resto del menú armándose
		if escena == "mejoras" then
			showGame = true
			applyHud()
		end
	elseif escena == "amigos" then
		-- Los amigos los pone el servidor alrededor de este punto antes del corte.
		local spot = Workspace:GetAttribute("TrailerPunto")
		place(if typeof(spot) == "Vector3" then spot else onRing(18), craterCenter)
		Camara.reset(giant())
		task.wait(0.4)
		feed:FireServer(true)
	elseif escena == "crece" then
		place(onRing(0), craterCenter)
		task.wait(0.1)
		Camara.reset(giant())
	elseif escena == "fin" then
		TweenService
			:Create(fade, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 })
			:Play()
	end
end
Workspace:GetAttributeChangedSignal("TrailerEscena"):Connect(onScene)

local lastFrame = os.clock()
RunService:BindToRenderStep("TrailerCamara", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	local dt = now - lastFrame
	lastFrame = now
	if escena == "" or escena == "destello" or escena == "listo" then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local cf, fov = Camara.para(escena, now - inicio, dt, root, giant())
	if cf then
		camera.CFrame = cf
		camera.FieldOfView = fov
	end
end)
