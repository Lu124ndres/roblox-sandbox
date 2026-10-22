--!strict
--[[
	Notices

	Carteles de los avisos del servidor (remote Notice): pez nuevo en la
	colección, colección completa, misión del tutorial cumplida, logro,
	recompensa diaria, compras con Robux (las propias y las de otros para todos)
	y los peces legendarios o mejores que saca alguien del servidor (más en
	NoticesMore). Solo muestra; los premios ya los dio el servidor.
	Durante el tutorial no se tapa la guía: los peces nuevos y los logros se
	guardan y salen al terminarlo (uno cada HELD_GAP), y cada paso cumplido
	lo muestra la línea de objetivo (TutorialBanner), no un cartel.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local GiantName = require(script.Parent.Parent.GiantName)
local NoticesMore = require(script.Parent.NoticesMore)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)

local COLORS = UIConfig.Colors
local RETENTION = Config.Retention
local ATTR = Protocol.PlayerAttributes
local HELD_GAP = 1.6 -- segundos entre los carteles guardados durante el tutorial

local Notices = {}

local function giantName(giantId: string): string
	for _, def in Config.Giants.chain do
		if def.id == giantId then
			return def.displayName
		end
	end
	return giantId
end

function Notices.start(toasts: Toasts.Toasts)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	local player = Players.LocalPlayer
	local held: { () -> () } = {}

	local function inTutorial(): boolean
		local step = player:GetAttribute(ATTR.Tutorial)
		return player:GetAttribute(ATTR.DataLoaded) == true
			and (if type(step) == "number" then step else 0) < #RETENTION.tutorial
	end

	-- Muestra ahora o, en pleno tutorial, al terminarlo.
	local function whenFree(show: () -> ())
		if inTutorial() then
			table.insert(held, show)
		else
			show()
		end
	end

	player:GetAttributeChangedSignal(ATTR.Tutorial):Connect(function()
		if inTutorial() or #held == 0 then
			return
		end
		local queue = table.clone(held)
		table.clear(held)
		for k, show in queue do
			task.delay(HELD_GAP * k, show)
		end
	end)

	notice.OnClientEvent:Connect(function(kind: unknown, a: unknown, b: unknown)
		if kind == "newFish" and type(a) == "string" then
			local fish = FishCatalog.get(a)
			local rarity = FishCatalog.rarity(a)
			if fish then
				local pause = if inTutorial() then 0 else 1.2 -- después del salto del pez
				task.delay(pause, whenFree, function()
					local caption = "¡NUEVO EN TU COLECCIÓN!"
					if type(b) == "number" and b > 0 then
						Sounds.play("Coins")
						caption = `¡NUEVO EN TU COLECCIÓN!  +{NumberFormat.short(b)} monedas`
					end
					toasts.banner(
						fish.displayName,
						UIConfig.RarityColors[rarity.id],
						"fish",
						caption
					)
				end)
			end
		elseif kind == "collection" and type(a) == "number" then
			Sounds.play("LegendaryCatch")
			toasts.banner(
				`+{NumberFormat.short(a)} monedas`,
				COLORS.Coins,
				"chest",
				"¡COLECCIÓN COMPLETA!"
			)
		elseif kind == "tutorial" and type(a) == "number" then
			Sounds.play("RareCatch")
			if a >= #RETENTION.tutorial then
				local coins = (if type(b) == "number" then b else 0) + RETENTION.tutorialBonus
				toasts.banner(`¡Tutorial completo! +{coins} monedas`, COLORS.Success)
			end
		elseif kind == "badge" and type(a) == "string" then
			local badge = RETENTION.badges[a]
			if badge then
				whenFree(function()
					Sounds.play("LegendaryCatch")
					toasts.banner(badge.name, COLORS.Power, "crown", "¡LOGRO DESBLOQUEADO!")
				end)
			end
		elseif kind == "daily" and type(a) == "number" and type(b) == "number" then
			Sounds.play("Coins")
			toasts.banner(
				`+{NumberFormat.short(b)} monedas`,
				COLORS.Coins,
				"gift",
				`DÍA {a} DE RACHA`
			)
		elseif kind == "boost" and type(a) == "string" and type(b) == "number" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} subió el entrenamiento de todos a x{b}!`, COLORS.Robux)
		elseif kind == "choose" and type(a) == "string" and type(b) == "string" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} eligió el siguiente monstruo: {giantName(b)}!`, COLORS.Robux)
		elseif kind == "restTime" and type(a) == "string" and type(b) == "number" then
			Sounds.play("StageUp")
			toasts.banner(
				`¡{a} compró +{math.floor(b / 60)} min de descanso para todos!`,
				COLORS.Robux
			)
		elseif kind == "fill" and type(a) == "string" and type(b) == "number" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} llenó {b}% de {GiantName.current(false)}!`, COLORS.Robux)
		elseif kind == "code" and a == "ok" and type(b) == "string" then
			Sounds.play("LegendaryCatch")
			toasts.banner(`¡Código canjeado! {b}`, COLORS.Coins)
		elseif kind == "group" and type(a) == "string" then
			local texts = {
				ok = `¡Gracias por unirte! {if type(b) == "string" then b else ""}`,
				notMember = "Primero únete al grupo",
				wait = "Todavía no se cumplen los minutos",
				claimed = "Ya reclamaste este regalo",
				off = "El regalo del grupo todavía no está listo",
			}
			Sounds.play(if a == "ok" then "LegendaryCatch" else "Click")
			toasts.banner(texts[a] or "", if a == "ok" then COLORS.Coins else COLORS.Warning)
		elseif kind == "event" then
			return -- lo anuncia en grande EventIntro
		elseif kind == "quest" and type(a) == "string" and type(b) == "string" then
			Sounds.play("LegendaryCatch")
			toasts.banner(`¡Misión cumplida! {a}: {b}`, COLORS.Success)
		elseif kind == "rebirth" and type(a) == "string" and type(b) == "number" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} renació! ({b})`, COLORS.Power)
		elseif kind == "admin" and type(a) == "string" then
			toasts.show(a, COLORS.Power)
		elseif kind == "playtime" and type(b) == "string" then
			Sounds.play("LegendaryCatch")
			toasts.banner(b, COLORS.Coins, "giftPink", "¡REGALO POR JUGAR!")
		elseif kind == "rare" and type(a) == "string" and type(b) == "string" then
			local fish = FishCatalog.get(b)
			local rarity = FishCatalog.rarity(b)
			if fish then
				Sounds.play("LegendaryCatch")
				toasts.banner(
					`¡{a} sacó un {fish.displayName} {TextCase.upper(rarity.displayName)}!`,
					UIConfig.RarityColors[rarity.id]
				)
			end
		elseif kind == "purchase" and type(a) == "string" then
			Sounds.play("Coins")
			toasts.banner(a, COLORS.Robux)
		else
			NoticesMore.handle(toasts, kind, a, b)
		end
	end)
end

return Notices
