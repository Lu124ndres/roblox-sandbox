--!strict
--[[
	ShopService

	Tienda de la cabaña. El cliente pide comprar una categoría (BuyUpgrade);
	el servidor decide todo: siempre se compra el SIGUIENTE nivel, al precio
	de Config.Shop, si alcanzan las monedas. Responde con ShopResult.

	También abre MEJORAS con E en el mostrador de la cabaña (OpenShop) y
	aplica la velocidad de las botas a cada personaje que aparece. En los
	pasos del tutorial de ir lejos (al volcán, al estanque) camina al menos a
	Config.Retention.tutorialWalkSpeed, así la primera comida llega pronto.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)
local Analytics = require(script.Parent.Analytics)

local PROMPT_DISTANCE = 12
local REQUEST_COOLDOWN = 0.3 -- segundos entre compras del mismo jugador

local ShopService = {}

local lastRequestAt: { [Player]: number } = {}

-- ¿Está en un paso del tutorial de ir lejos?
local function inFastStep(player: Player): boolean
	local save = PlayerData.read(player)
	local step = save and Config.Retention.tutorial[save.tutorial + 1]
	return step ~= nil and table.find(Config.Retention.tutorialFastSteps, step.id) ~= nil
end

-- Velocidad de las botas compradas (el puente la sube aparte, en el cliente).
local function applyWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local boots = Upgrades.current(player, "Boots").value
		humanoid.WalkSpeed = if inFastStep(player)
			then math.max(boots, Config.Retention.tutorialWalkSpeed)
			else boots
	end
end

local function reply(player: Player, status: Protocol.ShopStatus, category: unknown, level: number)
	Remotes.ShopResult:FireClient(player, status, category, level)
end

local function onBuy(player: Player, category: unknown)
	local now = os.clock()
	if now - (lastRequestAt[player] or 0) < REQUEST_COOLDOWN then
		return
	end
	lastRequestAt[player] = now
	if not Upgrades.isCategory(category) or not PlayerData.isLoaded(player) then
		reply(player, "invalid", category, 0)
		return
	end
	local kind: Upgrades.Category = if category == "Rod"
		then "Rod"
		elseif category == "Basket" then "Basket"
		else "Boots"
	local level = Upgrades.level(player, kind)
	local nextDef = Upgrades.list(kind)[level + 1]
	if not nextDef then
		reply(player, "max", kind, level)
		return
	end
	if not PlayerData.spendCoins(player, nextDef.price, `tienda:{kind}`) then
		reply(player, "poor", kind, level)
		return
	end
	PlayerData.setUpgrade(player, kind, level + 1)
	Analytics.upgrade(player, kind, level + 1)
	if kind == "Boots" then
		applyWalkSpeed(player)
	end
	reply(player, "ok", kind, level + 1)
	Milestones.bought(player)
end

local function track(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		character:WaitForChild("Humanoid", 10)
		applyWalkSpeed(player)
	end)
	-- Al cargar, cuando cambian las botas (también si se compraron con Robux) y al
	-- pasar de paso del tutorial (entra o sale de los pasos de ir lejos).
	local ATTR = Protocol.PlayerAttributes
	for _, attribute in { ATTR.DataLoaded, ATTR.Boots, ATTR.Tutorial } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			applyWalkSpeed(player)
		end)
	end
end

function ShopService.init(map: Instance)
	Remotes.BuyUpgrade.OnServerEvent:Connect(RateLimit.wrap("BuyUpgrade", 4, 6, onBuy))
	local counter = map:FindFirstChild(Protocol.Map.ShopCounter, true)
	assert(counter and counter:IsA("BasePart"), "ShopService: falta el mostrador de la cabaña")
	local prompt =
		Proximity.makePrompt(counter, "Mejoras", "Cañas, canastas y botas", PROMPT_DISTANCE)
	prompt.Triggered:Connect(function(player: Player)
		Remotes.OpenShop:FireClient(player)
	end)
	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequestAt[player] = nil
	end)
end

return ShopService
