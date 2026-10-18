--!strict
--[[
	Trajes/Vitrinas

	Las vitrinas de los trajes de pase (server/Social/Showcase): avisa para
	animar el traje en exhibición (su pose de vitrina la pone su estilo), lo
	hace flotar y mecerse apenas, gira los rayos de detrás, hace latir los aros
	de luz y el botón del pedestal, cambia el texto de la E según el jugador
	(Comprar, Ponerte o Quitarte) y, si no tiene el pase, abre la compra.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local Purchases = require(script.Parent.Parent.Menus.Purchases)

local SWAY = 0.12 -- radianes a cada lado
local SWAY_SPEED = 0.45
local BOB = 0.35 -- studs que sube y baja al flotar
local BOB_SPEED = 1.3
local RAYS_SPEED = 10 -- grados por segundo
local NEAR = 150
local TEXT_SECONDS = 0.5

-- Gira sobre sus pies: el marco del traje (Trajes.measure), no el pivote del Model.
type Spin = { model: Model, frame: CFrame, offset: CFrame }

local Vitrinas = {}

local spins: { Spin } = {}
local rays: { ImageLabel } = {}
local lights: { BasePart } = {} -- aros y botón que laten

local function decorate(vitrina: Instance)
	local aura = vitrina:WaitForChild("Aura", 10)
	local billboard = aura and aura:FindFirstChild("Rayos")
	local image = billboard and billboard:FindFirstChild("Rayos")
	if image and image:IsA("ImageLabel") then
		table.insert(rays, image)
	end
	local rings = vitrina:FindFirstChild("Aros")
	for _, ring in if rings then rings:GetChildren() else {} do
		if ring:IsA("BasePart") and ring.Name == "Aro" then
			table.insert(lights, ring)
		end
	end
	local button = vitrina:FindFirstChild("Boton")
	if button and button:IsA("BasePart") then
		table.insert(lights, button)
	end
end

local function wearing(outfit: string): boolean
	local character = Players.LocalPlayer.Character
	local current = character and character:FindFirstChild(Trajes.FOLDER)
	return current ~= nil and current:GetAttribute("Outfit") == outfit
end

local function setup(vitrina: Instance, onDisplay: (Instance, string) -> ())
	local pass, outfit = vitrina:GetAttribute("Pase"), vitrina:GetAttribute("Outfit")
	if type(pass) ~= "string" or type(outfit) ~= "string" then
		return
	end
	local shown = vitrina:WaitForChild("Muestra", 10)
	if shown and shown:IsA("Model") then
		local mesh = Trajes.mesh(shown)
		if mesh then
			local frame = Trajes.measure(mesh)
			table.insert(
				spins,
				{ model = shown, frame = frame, offset = frame:ToObjectSpace(shown:GetPivot()) }
			)
		end
		onDisplay(shown, outfit)
	end
	decorate(vitrina)
	local base = vitrina:WaitForChild("Pedestal", 10)
	local prompt = base and base:WaitForChild("Comprar", 10)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end
	local player = Players.LocalPlayer
	prompt.Triggered:Connect(function()
		if not Perks.hasPass(player, pass) then
			Purchases.promptPass(pass)
		end
	end)
	task.spawn(function()
		while prompt.Parent do
			prompt.ActionText = if not Perks.hasPass(player, pass)
				then "Comprar"
				elseif wearing(outfit) then "Quitarte"
				else "Ponerte"
			task.wait(TEXT_SECONDS)
		end
	end)
end

function Vitrinas.start(onDisplay: (holder: Instance, key: string) -> ())
	task.spawn(function()
		local folder = Workspace:WaitForChild("Vitrinas", 60)
		if not folder then
			return
		end
		folder.ChildAdded:Connect(function(child: Instance)
			setup(child, onDisplay)
		end)
		for _, child in folder:GetChildren() do
			task.spawn(setup, child, onDisplay)
		end
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local now = os.clock()
		local angle = SWAY * math.sin(now * SWAY_SPEED)
		local lift = CFrame.new(0, BOB * math.sin(now * BOB_SPEED), 0)
		for _, spin in spins do
			if
				(spin.frame.Position - camera.CFrame.Position).Magnitude < NEAR
				and spin.model.Parent
			then
				spin.model:PivotTo(spin.frame * lift * CFrame.Angles(0, angle, 0) * spin.offset)
			end
		end
		for _, image in rays do
			image.Rotation = (image.Rotation + RAYS_SPEED * dt) % 360
		end
		local glow = 0.2 + 0.2 * math.sin(now * 2.4)
		for _, part in lights do
			part.Transparency = glow
		end
	end)
end

return table.freeze(Vitrinas)
