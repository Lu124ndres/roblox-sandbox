--!strict
--[[
	NoticesMore

	Más carteles del remote Notice (Notices le pasa los que no conoce): hito
	de la colección (cada 6 especies), una sección del Índice completa (con
	su suerte), el monstruo que se cansó de esperar y
	se fue (con la kill igual para quien le dio algo) y el premio de la
	ruleta (después de que la ventana termina de girar, con el ícono de la
	casilla), los giros guardados que gana por jugar o con el diario, otro
	jugador que sacó la caña suprema y el premio de una misión reclamada.
	Solo muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Collection = require(ReplicatedStorage.Shared.Collection)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)

local COLORS = UIConfig.Colors

local NoticesMore = {}

-- true si era uno de estos avisos.
function NoticesMore.handle(toasts: Toasts.Toasts, kind: unknown, a: unknown, b: unknown): boolean
	if kind == "collectionStep" and type(a) == "number" and type(b) == "number" then
		Sounds.play("LegendaryCatch")
		local nextStep = Collection.nextMilestone(a)
		toasts.banner(
			`+{NumberFormat.short(b)} monedas`,
			COLORS.Coins,
			"chest",
			if nextStep
				then `¡{a} ESPECIES! PRÓXIMO PREMIO: {nextStep}`
				else `¡{a} ESPECIES EN TU COLECCIÓN!`
		)
		return true
	elseif kind == "sectionLuck" and type(a) == "string" and type(b) == "number" then
		Sounds.play("LegendaryCatch")
		local rarity = FishCatalog.rarityById(a)
		toasts.banner(
			`+{math.round(b * 100)}% de suerte para siempre`,
			UIConfig.RarityColors[a] or COLORS.Success,
			"luck",
			`¡SECCIÓN {TextCase.upper(if rarity then rarity.displayName else a)} COMPLETA!`
		)
		return true
	elseif kind == "giantLeft" and type(a) == "string" then -- sin fanfarria (pedido del usuario el 2026-10-23)
		toasts.banner(
			if b == true then "¡Te llevas el banquete igual!" else "Dale de comer al siguiente",
			if b == true then COLORS.Success else COLORS.Warning,
			"skull",
			`¡{TextCase.upper(a)} SE CANSÓ DE ESPERAR Y SE FUE!`
		)
		return true
	elseif kind == "spin" and type(b) == "string" then
		local prize = if type(a) == "number" then SPIN.prizes[a] else nil
		local supreme = prize ~= nil and prize.kind == "rod"
		task.delay(SPIN.spinSeconds, function()
			Sounds.play("LegendaryCatch")
			toasts.banner(
				b,
				if supreme then COLORS.Robux else COLORS.Coins,
				if prize then prize.icon else "chest",
				if supreme then "¡¡CAÑA SUPREMA!!" else "¡RULETA!"
			)
		end)
		return true
	elseif kind == "superRod" and type(a) == "string" then
		Sounds.play("LegendaryCatch")
		toasts.banner(
			`¡{a} sacó la {SPIN.superRod.name} en la ruleta! (0.01%)`,
			COLORS.Robux,
			"superRod",
			"¡¡CAÑA SUPREMA!!"
		)
		return true
	elseif kind == "spinsGained" and type(a) == "number" then
		Sounds.play("Coins")
		local spins = if a == 1 then "+1 giro" else `+{a} giros`
		toasts.banner(
			if b == "play"
				then `¡{spins} de ruleta por jugar!`
				else `¡{spins} de ruleta por tu racha!`,
			COLORS.Coins,
			"ticket",
			"¡GIRO GRATIS!"
		)
		return true
	elseif kind == "questClaimed" and type(a) == "string" and type(b) == "string" then
		Sounds.play("Coins")
		toasts.banner(b, COLORS.Coins, "coin", `¡RECLAMADA! {TextCase.upper(a)}`)
		return true
	end
	return false
end

return NoticesMore
