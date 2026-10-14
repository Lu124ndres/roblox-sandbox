--!strict
--[[
	Notices

	Carteles de los avisos del servidor (remote Notice): pez nuevo en la
	colección, colección completa, misión del tutorial cumplida, logro,
	recompensa diaria, compras con Robux (las propias y las de otros para todos)
	y los peces legendarios o mejores que saca alguien del servidor. Solo muestra; los premios ya los dio el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local GiantName = require(script.Parent.Parent.GiantName)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)

local COLORS = UIConfig.Colors
local RETENTION = Config.Retention

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
	notice.OnClientEvent:Connect(function(kind: unknown, a: unknown, b: unknown)
		if kind == "newFish" and type(a) == "string" then
			local fish = FishCatalog.get(a)
			local rarity = FishCatalog.rarity(a)
			if fish then
				task.delay(1.2, function() -- después del salto del pez
					toasts.banner(
						`¡Nuevo en tu colección: {fish.displayName}!`,
						UIConfig.RarityColors[rarity.id]
					)
					if type(b) == "number" and b > 0 then
						Sounds.play("Coins")
						toasts.show(
							`+{NumberFormat.short(b)} monedas por descubrirlo`,
							COLORS.Coins
						)
					end
				end)
			end
		elseif kind == "collection" and type(a) == "number" then
			Sounds.play("LegendaryCatch")
			toasts.banner(`¡Colección completa! +{NumberFormat.short(a)} monedas`, COLORS.Coins)
		elseif kind == "tutorial" and type(a) == "number" then
			Sounds.play("RareCatch")
			local done = a >= #RETENTION.tutorial
			local coins = (if type(b) == "number" then b else 0)
				+ (if done then RETENTION.tutorialBonus else 0)
			toasts.banner(
				if done
					then `¡Tutorial completo! +{coins} monedas`
					else `¡Misión cumplida! +{coins} monedas`,
				COLORS.Success
			)
		elseif kind == "badge" and type(a) == "string" then
			local badge = RETENTION.badges[a]
			if badge then
				Sounds.play("LegendaryCatch")
				toasts.banner(`Logro: {badge.name}`, COLORS.Power)
			end
		elseif kind == "daily" and type(a) == "number" and type(b) == "number" then
			Sounds.play("Coins")
			toasts.banner(`Día {a} de racha: +{NumberFormat.short(b)} monedas`, COLORS.Coins)
		elseif kind == "boost" and type(a) == "string" and type(b) == "number" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} subió el entrenamiento de todos a x{b}!`, COLORS.Robux)
		elseif kind == "choose" and type(a) == "string" and type(b) == "string" then
			Sounds.play("StageUp")
			toasts.banner(`¡{a} eligió el siguiente monstruo: {giantName(b)}!`, COLORS.Robux)
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
		elseif kind == "event" and type(a) == "string" then
			for _, event in Events.kinds do
				if event.id == a then
					Sounds.play("StageUp")
					toasts.banner(
						`{event.name} {event.text} por {Events.durationMinutes} min`,
						event.color
					)
				end
			end
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
			toasts.banner(`¡Regalo por jugar! {b}`, COLORS.Coins)
		elseif kind == "rare" and type(a) == "string" and type(b) == "string" then
			local fish = FishCatalog.get(b)
			local rarity = FishCatalog.rarity(b)
			if fish then
				Sounds.play("LegendaryCatch")
				toasts.banner(
					`¡{a} sacó un {fish.displayName} {string.upper(rarity.displayName)}!`,
					UIConfig.RarityColors[rarity.id]
				)
			end
		elseif kind == "purchase" and type(a) == "string" then
			Sounds.play("Coins")
			toasts.banner(a, COLORS.Robux)
		end
	end)
end

return Notices
