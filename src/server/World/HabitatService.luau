--!strict
--[[
	HabitatService

	El hábitat del gigante actual dentro del cráter: los props de
	ServerStorage.Habitats.<GiantId> repartidos según Config.Habitats, en
	Workspace.Habitat (HabitatPlacer coloca cada uno).

	Cambia cuando cambia el gigante (atributo Id de EstadoGigante) y ya
	mientras el cráter se llena para el siguiente (VolcanLlenando: se arma el
	de RuletaResultado), así el que llega encuentra su casa puesta. Un gigante
	sin carpeta en ServerStorage.Habitats (o sin entrada en Config) deja el
	cráter vacío.

	Los props se apoyan en el fondo de verdad (bajo el agua en la repisa). Con
	el desierto del minotauro la arena llega más arriba: cada cliente los sube
	sobre ella mientras está (client/Ambient/SandProps), como la arena misma.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local HabitatPlacer = require(script.Parent.HabitatPlacer)

local ATTRS = Protocol.GiantAttributes

local HabitatService = {}

local folder: Folder
local builtFor: string? = nil

-- Borra el hábitat anterior y arma el de giantId.
local function build(giantId: string)
	if giantId == builtFor then
		return
	end
	builtFor = giantId
	folder:ClearAllChildren()
	local library = ServerStorage:FindFirstChild("Habitats")
	local models = library and library:FindFirstChild(giantId)
	local entries = Config.Habitats.byGiant[giantId]
	if not models or not entries then
		return
	end
	local placed = 0
	for _, entry in entries do
		local template = models:FindFirstChild(entry.prop)
		if not template or not template:IsA("Model") then
			warn(`HabitatService: falta el prop {entry.prop} en ServerStorage.Habitats.{giantId}`)
			continue
		end
		if HabitatPlacer.place(template, entry, folder) then
			placed += 1
		end
	end
	folder:SetAttribute("GiantId", giantId)
	print(`HabitatService: hábitat de {giantId} con {placed} props`)
end

-- Llamar después de TerrainBuilder.build(): los props se apoyan en el terreno.
function HabitatService.init()
	folder = Instance.new("Folder")
	folder.Name = Protocol.Map.Habitat
	folder.Parent = Workspace

	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local function current()
		local id = state:GetAttribute(ATTRS.Id)
		if type(id) == "string" then
			build(id)
		end
	end
	state:GetAttributeChangedSignal(ATTRS.Id):Connect(current)
	state:GetAttributeChangedSignal(ATTRS.Refilling):Connect(function()
		local nextId = state:GetAttribute(ATTRS.RouletteResult)
		if state:GetAttribute(ATTRS.Refilling) == true and type(nextId) == "string" then
			build(nextId)
		end
	end)
	current()
end

return HabitatService
