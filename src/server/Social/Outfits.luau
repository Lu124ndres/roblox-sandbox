--!strict
--[[
	Outfits

	Trajes de los pases (Config.Monetization.passes[...].outfit), hechos de
	piezas soldadas al personaje para que todos los vean:
		ReyDelMar      corona dorada con gema azul y capa azul
		DiosDelVolcan  corona de rayos de fuego que arde, capa negra con
		               borde de lava y chispas alrededor
	Se ponen al aparecer el personaje y en cuanto se compra el pase. Las
	piezas no chocan, no pesan y los rayos las ignoran. Si tiene los dos
	pases, se ve el más caro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local OutfitParts = require(script.Parent.OutfitParts)

local PASSES = Config.Monetization.passes
local FOLDER = "Traje"

local Outfits = {}

-- El traje del pase más caro que tiene (nil si ninguno).
local function outfitFor(player: Player): string?
	local best: string?, price = nil, -1
	for key, pass in PASSES do
		if pass.outfit and pass.robux > price and Perks.hasPass(player, key) then
			best, price = pass.outfit, pass.robux
		end
	end
	return best
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild(FOLDER)
	local outfit = outfitFor(player)
	if old and old:GetAttribute("Outfit") == outfit then
		return
	end
	if old then
		old:Destroy()
	end
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if
		not outfit
		or not (head and head:IsA("BasePart"))
		or not (torso and torso:IsA("BasePart"))
	then
		return
	end
	local model = Instance.new("Model")
	model.Name = FOLDER
	model:SetAttribute("Outfit", outfit)
	OutfitParts.build(outfit, model, head, torso)
	model.Parent = character
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		character:WaitForChild("Head", 10)
		task.wait(0.5) -- que carguen ropa y accesorios antes de medir la cabeza
		dress(player)
	end)
	player.AttributeChanged:Connect(function(attribute: string)
		if
			string.sub(attribute, 1, #Protocol.PlayerAttributes.PassPrefix)
			== Protocol.PlayerAttributes.PassPrefix
		then
			dress(player)
		end
	end)
	if player.Character then
		task.spawn(dress, player)
	end
end

function Outfits.init()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return Outfits
