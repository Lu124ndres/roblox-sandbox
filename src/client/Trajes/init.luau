--!strict
--[[
	Trajes (cliente)

	Anima los trajes de malla de todos los personajes y de las vitrinas
	(Shared.Trajes): cada cliente mueve los huesos de todos copiando su
	cuerpo escondido, así todo el servidor ve las mismas animaciones. Se
	actualiza después de la física (ya están la animación de Roblox y la
	pose de la caña) y solo cerca de la cámara.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Trajes = require(ReplicatedStorage.Shared.Trajes)
local FxQuality = require(script.Parent.Settings.FxQuality)
local Rig = require(script.Rig)
local Vitrinas = require(script.Vitrinas)

local RANGE = 220 -- studs: más lejos los trajes se quedan quietos
local BIND_WAIT = 5

type Entry = { rig: Rig.Rig, root: BasePart?, anchor: BasePart }

local TrajesClient = {}

local entries: { [Instance]: Entry } = {}

local function release(holder: Instance)
	local entry = entries[holder]
	if entry then
		entries[holder] = nil
		Rig.unbind(entry.rig)
	end
end

-- holder: el Model "Traje" del personaje, o el de la vitrina.
local function bind(holder: Instance, key: string, character: Model?)
	release(holder)
	local mesh = Trajes.mesh(holder)
	if not mesh then
		return
	end
	if character and not mesh:WaitForChild(Trajes.WELD, BIND_WAIT) then
		return
	end
	if not holder.Parent then
		return
	end
	local rig = Rig.bind(mesh, key, character, FxQuality.scaleEmitter)
	if rig then
		entries[holder] = { rig = rig, root = rig.root, anchor = rig.root or mesh }
		holder.AncestryChanged:Connect(function()
			if not holder:IsDescendantOf(Workspace) then
				release(holder)
			end
		end)
	end
end

local function watchCharacter(character: Model)
	local function onChild(child: Instance)
		if child.Name == Trajes.FOLDER and child:IsA("Model") then
			local key = child:GetAttribute("Outfit")
			if type(key) == "string" then
				task.spawn(bind, child, key, character)
			end
		end
	end
	character.ChildAdded:Connect(onChild)
	for _, child in character:GetChildren() do
		onChild(child)
	end
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
end

local function step()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	for holder, entry in entries do
		local anchor = entry.anchor
		if (anchor.Position - eye).Magnitude <= RANGE then
			local root = entry.root
			local velocity = if root then root.AssemblyLinearVelocity else Vector3.zero
			Rig.step(entry.rig, {
				now = now,
				speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude,
				display = root == nil,
			})
		elseif not holder.Parent then
			release(holder)
		end
	end
end

function TrajesClient.start()
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	Vitrinas.start(function(holder: Instance, key: string)
		task.spawn(bind, holder, key, nil)
	end)
	RunService.PostSimulation:Connect(step)
end

return TrajesClient
