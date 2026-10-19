--!strict
--[[
	Analytics

	Telemetría del servidor con AnalyticsService, para ajustar el balance y ver
	dónde abandonan los jugadores. Nada sale del cliente. Los 10 eventos
	(aprobados el 2026-10-19; ver docs/decisiones.md):
		1. Embudo de inicio (LogOnboardingFunnelStepEvent): 1 cargó (solo nuevos),
		   2 primer pez, 3-6 cada paso del tutorial, 7 primera kill.
		2. Fin de sesión (Analytics/Sesion).
		3. Monstruo lleno: minutos, quiénes aportaron, jugadores, comida.
		4. Monstruo que se fue sin llenar: etapa, progreso, jugadores.
		5. Renacer (LogProgressionCompleteEvent) y los minutos jugados en total.
		6. Economía de monedas, sumada por origen y destino (Analytics/Economia).
		7. Mejora comprada: categoría, nivel y minutos de sesión.
		8. Estanque abierto: por kills o por Robux.
		9. Compra con Robux (productos y pases).
		10. Premio diario y ruleta.
	PlayerData avisa monedas, peces y kills por Analytics/Bus (sin ciclo de
	require); el resto de los módulos llama a las funciones de abajo.
	Los eventos del monstruo son del servidor, pero Roblox pide un jugador:
	se mandan con uno de los que aportaron (o cualquiera del servidor).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local PlayerData = require(script.Parent.PlayerData)
local SaveSchema = require(script.Parent.Save.SaveSchema)
local Bus = require(script.Bus)
local Economia = require(script.Economia)
local Envio = require(script.Envio)
local Monstruo = require(script.Monstruo)
local Sesion = require(script.Sesion)

local FUNNEL =
	{ "Cargo", "PrimerPez", "Tutorial1", "Tutorial2", "Tutorial3", "Tutorial4", "PrimeraKill" }
local PONDS = Config.Progression.ponds

local Analytics = {}

local sent: { [Player]: { [number]: boolean } } = {} -- pasos del embudo ya mandados

local function funnel(player: Player, step: number)
	local done = sent[player]
	if not done then
		done = {}
		sent[player] = done
	end
	if not done[step] and FUNNEL[step] then
		done[step] = true
		Envio.funnel(player, step, FUNNEL[step])
	end
end

local function loaded(player: Player)
	local save = PlayerData.read(player)
	if not save then
		return
	end
	Sesion.start(player, save)
	if save.tutorial == 0 and save.stats.fishCaught == 0 then
		funnel(player, 1) -- solo los nuevos: el embudo mide el primer minuto
	end
end

local function watch(player: Player)
	local attribute = Protocol.PlayerAttributes.DataLoaded
	if player:GetAttribute(attribute) == true then
		loaded(player)
	end
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if player:GetAttribute(attribute) == true then
			loaded(player)
		end
	end)
end

-- Estanques que se abrieron al pasar de `before` a `after` kills.
local function pondsOpened(player: Player, before: number, after: number)
	for index, pond in PONDS do
		local need = pond.requiredKills
		if not pond.robuxOnly and need > 0 and need > before and need <= after then
			Envio.custom(player, "EstanqueAbierto", index, { "kills" })
		end
	end
end

function Analytics.init()
	Sesion.init()
	Bus.coins = Economia.source
	Bus.spend = Economia.sink
	Bus.catch = function(player: Player, fishId: string, _added: number, caughtBefore: number)
		Sesion.catch(player, fishId)
		if caughtBefore == 0 then
			funnel(player, 2)
		end
	end
	Bus.kill = function(player: Player, before: number, after: number)
		if before == 0 then
			funnel(player, 7)
		end
		pondsOpened(player, before, after)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		Sesion.finish(player)
		Economia.forget(player)
		sent[player] = nil
	end)
	Monstruo.start()
end

-- index: el paso del tutorial que terminó (1..4).
function Analytics.tutorial(player: Player, index: number)
	funnel(player, 2 + index)
end

-- Antes de reiniciar: count es el renacimiento que empieza (1 = el primero).
function Analytics.rebirth(player: Player, count: number, save: SaveSchema.SaveData)
	Economia.sink(player, save.coins, "renacer")
	Envio.progression(player, "Renacer", count)
	Envio.custom(player, "RenacerMinutos", save.playMinutes, { tostring(math.min(count, 10)) })
end

function Analytics.upgrade(player: Player, category: string, level: number)
	Envio.custom(
		player,
		"Mejora",
		math.round(Sesion.minutes(player)),
		{ category, tostring(level) }
	)
end

function Analytics.pondBought(player: Player, index: number)
	Envio.custom(player, "EstanqueAbierto", index, { "robux" })
end

function Analytics.robux(player: Player, key: string, robux: number, gift: boolean)
	Economia.robux(player, key, robux)
	Envio.custom(player, "Compra", robux, { key, if gift then "regalo" else "propia" })
end

function Analytics.daily(player: Player, streak: number)
	Envio.custom(player, "Diario", streak)
end

function Analytics.spin(player: Player, slot: number, free: boolean)
	Envio.custom(player, "Ruleta", slot, { if free then "gratis" else "guardado" })
end

-- El monstruo se llenó o se fue (tired). paid: userIds de los que cobraron la kill.
Analytics.giantDone = Monstruo.done

return Analytics
