--!strict
--[[
	NoticesMore

	Más carteles del remote Notice (Notices le pasa los que no conoce): hito
	de la colección (cada 6 especies), el monstruo que se cansó de esperar y
	se fue (con la kill igual para quien le dio algo) y el premio de la
	ruleta gratis (después de que la ventana termina de girar). Solo muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Collection = require(ReplicatedStorage.Shared.Collection)
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
	elseif kind == "giantLeft" and type(a) == "string" then
		Sounds.play("StageUp")
		toasts.banner(
			if b == true then "¡Te llevas la kill igual!" else "Dale de comer al siguiente",
			if b == true then COLORS.Success else COLORS.Warning,
			"skull",
			`¡{TextCase.upper(a)} SE CANSÓ DE ESPERAR Y SE FUE!`
		)
		return true
	elseif kind == "spin" and type(b) == "string" then
		task.delay(SPIN.spinSeconds, function()
			Sounds.play("LegendaryCatch")
			toasts.banner(b, COLORS.Coins, "chest", "¡RULETA GRATIS!")
		end)
		return true
	end
	return false
end

return NoticesMore
