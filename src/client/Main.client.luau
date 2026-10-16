--!strict
--[[
	Punto de entrada del cliente. Monta la interfaz, el gigante, la pesca y
	el entrenamiento visibles de todos los jugadores, la vida del mar, las
	bandadas y el ambiente de cada zona; cada módulo documenta su propia
	responsabilidad.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local AbyssRescue = require(script.Parent.Ambient.AbyssRescue)
local AfkNotice = require(script.Parent.Ambient.AfkNotice)
local BridgeBoost = require(script.Parent.Ambient.BridgeBoost)
local Flock = require(script.Parent.Ambient.Flock)
local HabitatFx = require(script.Parent.Ambient.HabitatFx)
local Lighthouse = require(script.Parent.Ambient.Lighthouse)
local SeaLife = require(script.Parent.Ambient.SeaLife)
local SkyCycle = require(script.Parent.Ambient.SkyCycle)
local SpinStand = require(script.Parent.Ambient.SpinStand)
local RestDawn = require(script.Parent.Ambient.RestDawn)
local ZoneMood = require(script.Parent.Ambient.ZoneMood)
local Music = require(script.Parent.Audio.Music)
local Sounds = require(script.Parent.Audio.Sounds)
local FeedFeedback = require(script.Parent.FeedFeedback)
local FeedController = require(script.Parent.Feeding.FeedController)
local FishingController = require(script.Parent.Fishing.FishingController)
local FishingVisuals = require(script.Parent.Fishing.FishingVisuals)
local FishBasket = require(script.Parent.Effects.FishBasket)
local GiantName = require(script.Parent.GiantName)
local AngerMeter = require(script.Parent.Giant.AngerMeter)
local CycleView = require(script.Parent.Giant.CycleView)
local GiantAttacks = require(script.Parent.Giant.GiantAttacks)
local GiantView = require(script.Parent.Giant.GiantView)
local Hud = require(script.Parent.Hud)
local DailyWindow = require(script.Parent.Menus.DailyWindow)
local SpinWindow = require(script.Parent.Menus.SpinWindow)
local PlaytimeWindow = require(script.Parent.Menus.PlaytimeWindow)
local PerCatchFlash = require(script.Parent.Effects.PerCatchFlash)
local AdminPanel = require(script.Parent.Menus.AdminPanel)
local GamepadNav = require(script.Parent.Menus.GamepadNav)
local RestChips = require(script.Parent.Interface.RestChips)
local RouletteView = require(script.Parent.Giant.RouletteView)
local FishDex = require(script.Parent.Menus.FishDex)
local Notices = require(script.Parent.Menus.Notices)
local BoostTimer = require(script.Parent.Menus.BoostTimer)
local EventTimer = require(script.Parent.Menus.EventTimer)
local QuestsWindow = require(script.Parent.Menus.QuestsWindow)
local StarterOffer = require(script.Parent.Menus.StarterOffer)
local RebirthWindow = require(script.Parent.Menus.RebirthWindow)
local Purchases = require(script.Parent.Menus.Purchases)
local RankingBoards = require(script.Parent.Menus.RankingBoards)
local RobuxShop = require(script.Parent.Menus.RobuxShop)
local SettingsWindow = require(script.Parent.Menus.SettingsWindow)
local TutorialGuide = require(script.Parent.Menus.TutorialGuide)
local HungerBar = require(script.Parent.HungerBar)
local Toasts = require(script.Parent.Toasts)
local TitleUnlock = require(script.Parent.Interface.TitleUnlock)
local ShareLine = require(script.Parent.Interface.ShareLine)
local EvolveView = require(script.Parent.Interface.EvolveView)
local NextGoal = require(script.Parent.Menus.NextGoal)
local PondFx = require(script.Parent.Training.PondFx)
local PondSigns = require(script.Parent.Training.PondSigns)
local ShopController = require(script.Parent.Shop.ShopController)
local ClientSettings = require(script.Parent.Settings.ClientSettings)
local FxQuality = require(script.Parent.Settings.FxQuality)
local TrainingController = require(script.Parent.Training.TrainingController)
local PowerGainFx = require(script.Parent.Effects.PowerGainFx)
local Ui = require(script.Parent.Ui)
local CoreGuiSetup = require(script.Parent.Interface.CoreGuiSetup)
local FillChips = require(script.Parent.Interface.FillChips)
local Layout = require(script.Parent.Interface.Layout)
local QuickBuys = require(script.Parent.Interface.QuickBuys)
local FriendBoostLabel = require(script.Parent.Interface.FriendBoostLabel)
local Overhead = require(script.Parent.Interface.Overhead)
local TrajesClient = require(script.Parent.Trajes)
local CodesWindow = require(script.Parent.Menus.CodesWindow)
local GroupWindow = require(script.Parent.Menus.GroupWindow)

local EFFECTS = UIConfig.Effects

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

ClientSettings.start()
CoreGuiSetup.start()

local screen = Ui.screen("Juego", playerGui, 1)
Layout.mount(screen, playerGui)
local toasts = Toasts.mount(screen)
if player.MembershipType == Enum.MembershipType.Premium then
	local bonus = require(ReplicatedStorage.Shared.Config).Social.premiumMultiplier
	task.delay(8, toasts.show, `Premium: x{bonus} poder y monedas`, UIConfig.Colors.Coins)
end

local hungerPanel = HungerBar.mount(screen, function(stage: number)
	local color = UIConfig.HungerStageColors[stage]
	Sounds.play("StageUp")
	toasts.banner(`¡{GiantName.current(true)} evolucionó!`, color)
end, function()
	Sounds.play("StageUp")
	toasts.banner(`¡{GiantName.current(true)} se llenó!`, UIConfig.Colors.Feeding)
end)
AngerMeter.mount(hungerPanel, toasts)
FillChips.mount(hungerPanel)
RestChips.mount(hungerPanel)
ShareLine.mount(hungerPanel)
EvolveView.mount(hungerPanel)
RouletteView.start(screen)
Toasts.placeBelow(hungerPanel)
local coinLabel = Hud.mount(screen, player)
FishingController.start(screen, toasts)
FeedFeedback.start(toasts, screen, coinLabel)
FeedController.start(screen, toasts)
ShopController.start(screen, player, toasts)
FishDex.start(screen)
DailyWindow.start(screen)
SpinWindow.start(screen)
SpinStand.start(SpinWindow.open)
PlaytimeWindow.start(screen)
PerCatchFlash.start(toasts)
task.spawn(AdminPanel.start, screen)
SettingsWindow.start(screen)
Purchases.start(toasts)
RobuxShop.start(screen)
QuickBuys.start()
QuestsWindow.start(screen)
RebirthWindow.start(screen)
StarterOffer.start(screen)
CodesWindow.start(screen)
GroupWindow.start(screen)
FriendBoostLabel.start(screen)
BoostTimer.start(screen)
EventTimer.start()
TutorialGuide.start(screen)
NextGoal.start(screen)
Notices.start(toasts)
RankingBoards.start()
PowerGainFx.mount(screen)
TrainingController.start(toasts)
PondSigns.start()
PondFx.start()
AbyssRescue.start(screen)
BridgeBoost.start()
GiantAttacks.start(screen, toasts)
AfkNotice.start(toasts)
CycleView.start(toasts)

FishingVisuals.start()
FishBasket.start()
GiantView.start()
ZoneMood.start()
RestDawn.start()
SkyCycle.start()
Lighthouse.start()
SeaLife.start()
HabitatFx.start()
Music.start()
Overhead.start()
GamepadNav.start() -- mando: Y menú, B atrás, la marca entra a las ventanas
TrajesClient.start()
TitleUnlock.start(toasts)
FxQuality.start()

-- Gaviotas sobre la isla y murciélagos sobre el cráter.
Flock.start({
	name = "Gaviotas",
	center = Vector3.new(0, EFFECTS.SeagullHeight, 0),
	count = EFFECTS.SeagullCount,
	radius = EFFECTS.SeagullRadius,
	bodyColor = Color3.fromRGB(248, 250, 252),
	wingColor = Color3.fromRGB(150, 158, 170),
	beakColor = Color3.fromRGB(255, 196, 84),
	size = 1,
	flapSpeed = 9,
	orbitSeconds = 26,
	sound = "Seagull",
})
Flock.start({
	name = "Murcielagos",
	center = WorldZones.craterCenter + Vector3.new(0, WorldLayout.craterRimHeight + 30, 0),
	count = EFFECTS.BatCount,
	radius = WorldLayout.craterLakeRadius * 0.7,
	bodyColor = Color3.fromRGB(28, 22, 30),
	wingColor = Color3.fromRGB(40, 30, 44),
	beakColor = Color3.fromRGB(255, 50, 40),
	size = 0.9,
	flapSpeed = 18,
	orbitSeconds = 18,
	sound = nil,
})
