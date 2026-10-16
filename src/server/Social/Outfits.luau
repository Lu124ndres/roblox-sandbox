--!strict
--[[
	Outfits

	Todos los jugadores se ven como marineros (no con su avatar): el juego
	no carga la apariencia (StarterPlayer.LoadCharacterAppearance = false).
	Si el traje de malla está en ServerStorage (Shared.Trajes) se usa ese
	(MeshOutfit); si no, se viste con piezas soldadas que todos ven:
		Marinero       el uniforme de SailorParts, con el tono de piel del
		               avatar del jugador
		ReyDelMar      almirante de los mares (PassLooks + corona y capa de
		DiosDelVolcan  OutfitParts), un poco más grandes para que resalten
	El traje de pase sale de Config.Monetization.passes[...].outfit; si tiene
	los dos, se ve el más caro, salvo que elija otro en una vitrina (atributo
	TrajeElegido). Se viste al aparecer, al comprar un pase y al elegir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local MeshOutfit = require(script.Parent.MeshOutfit)
local OutfitKit = require(script.Parent.OutfitKit)
local OutfitParts = require(script.Parent.OutfitParts)
local PassLooks = require(script.Parent.PassLooks)
local SailorParts = require(script.Parent.SailorParts)

local PASSES = Config.Monetization.passes
local FOLDER = "Traje"
local SAILOR = "Marinero"
local rgb = OutfitKit.rgb
-- Tonos de piel de reserva (si no se puede leer el del avatar).
local SKINS = {
	rgb(255, 220, 177),
	rgb(234, 184, 146),
	rgb(204, 142, 105),
	rgb(160, 102, 72),
	rgb(120, 76, 52),
}

type Colors = { head: Color3?, torso: Color3, arms: Color3?, legs: Color3 }
-- Colores del cuerpo por traje (nil = el tono de piel del jugador).
local BODY: { [string]: Colors } = {
	[SAILOR] = { torso = SailorParts.WHITE, legs = SailorParts.NAVY },
	ReyDelMar = { torso = rgb(24, 48, 120), legs = rgb(245, 245, 240) },
	DiosDelVolcan = {
		head = rgb(58, 48, 48),
		torso = rgb(32, 26, 28),
		arms = rgb(58, 48, 48),
		legs = rgb(36, 30, 30),
	},
}
local SCALE: { [string]: number } = { ReyDelMar = 1.1, DiosDelVolcan = 1.15 }

local Outfits = {}

local skins: { [number]: Color3 } = {}

local function skinOf(player: Player): Color3
	local known = skins[player.UserId]
	if known then
		return known
	end
	local fallback = SKINS[player.UserId % #SKINS + 1]
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	local skin = if ok and description then description.HeadColor else fallback
	skins[player.UserId] = skin
	return skin
end

-- El que eligió en una vitrina (si lo tiene), o el del pase más caro, o marinero.
local function outfitFor(player: Player): string
	local chosen = player:GetAttribute(Trajes.CHOSEN)
	local best, price = SAILOR, -1
	for key, pass in PASSES do
		if pass.outfit and Perks.hasPass(player, key) then
			if pass.outfit == chosen then
				return pass.outfit
			elseif pass.robux > price then
				best, price = pass.outfit, pass.robux
			end
		end
	end
	return if chosen == SAILOR then SAILOR else best
end

-- Quita lo que traiga del avatar (por si la apariencia llegó a cargar).
local function strip(character: Model)
	for _, item in character:GetChildren() do
		if
			item:IsA("Accessory")
			or item:IsA("Clothing")
			or item:IsA("ShirtGraphic")
			or item:IsA("BodyColors")
		then
			item:Destroy()
		end
	end
end

local function paint(character: Model, outfit: string, skin: Color3)
	local colors = BODY[outfit] or BODY[SAILOR]
	local body = Instance.new("BodyColors")
	body.HeadColor3 = colors.head or skin
	body.TorsoColor3 = colors.torso
	body.LeftArmColor3 = colors.arms or skin
	body.RightArmColor3 = colors.arms or skin
	body.LeftLegColor3 = colors.legs
	body.RightLegColor3 = colors.legs
	body.Parent = character
	local head = character:FindFirstChild("Head")
	local face = head and head:FindFirstChildOfClass("Decal")
	if face then -- el Dios del Volcán tiene ojos de fuego en vez de cara
		face.Transparency = if outfit == "DiosDelVolcan" then 1 else 0
	end
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local outfit = outfitFor(player)
	local old = character:FindFirstChild(FOLDER)
	if old and old:GetAttribute("Outfit") == outfit then
		return
	end
	if old then
		old:Destroy()
	end
	if math.abs(character:GetScale() - 1) > 0.001 then
		pcall(character.ScaleTo, character, 1)
	end
	if MeshOutfit.available(outfit) then
		strip(character)
		if MeshOutfit.build(character, outfit) then
			return
		end
	end
	local rig = OutfitKit.rig(character)
	if not rig then
		return
	end
	strip(character)
	paint(character, outfit, skinOf(player))
	local model = Instance.new("Model")
	model.Name = FOLDER
	model:SetAttribute("Outfit", outfit)
	if outfit == SAILOR then
		SailorParts.build(model, rig)
	else
		PassLooks.build(outfit, model, rig)
		OutfitParts.build(outfit, model, rig.head, rig.torso)
	end
	model.Parent = character
	local scale = SCALE[outfit]
	if scale then
		pcall(character.ScaleTo, character, scale)
	end
end

local function watch(player: Player)
	task.spawn(skinOf, player) -- se pide una vez, antes de que aparezca
	player.CharacterAdded:Connect(function(character: Model)
		character:WaitForChild("Head", 10)
		character:WaitForChild("Humanoid", 10)
		task.wait(0.2) -- que terminen de armarse las partes del cuerpo
		dress(player)
	end)
	player.AttributeChanged:Connect(function(attribute: string)
		if
			string.sub(attribute, 1, #Protocol.PlayerAttributes.PassPrefix)
				== Protocol.PlayerAttributes.PassPrefix
			or attribute == Trajes.CHOSEN
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
	Players.PlayerRemoving:Connect(function(player: Player)
		skins[player.UserId] = nil
	end)
end

return Outfits
