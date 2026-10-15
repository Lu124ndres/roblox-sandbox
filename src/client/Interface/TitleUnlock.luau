--!strict
--[[
	TitleUnlock

	Aviso grande cuando el jugador sube de título (atributo Titulo, que pone
	el servidor por su poder máximo): "¡Nuevo título: Coloso Abisal!" con el
	color del título y un sonido. Solo cuando sube, y no al entrar (cuando
	cargan los datos el título salta del 1 al suyo).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Titles = require(ReplicatedStorage.Shared.Titles)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local OverheadLook = require(script.Parent.OverheadLook)

local ATTR = Protocol.PlayerAttributes

local TitleUnlock = {}

function TitleUnlock.start(toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	task.spawn(function()
		while player:GetAttribute(ATTR.DataLoaded) ~= true do
			player:GetAttributeChangedSignal(ATTR.DataLoaded):Wait()
		end
		task.wait(1) -- que llegue el título guardado antes de empezar a comparar
		local value = player:GetAttribute(ATTR.Title)
		local shown = if type(value) == "number" then value else 1
		player:GetAttributeChangedSignal(ATTR.Title):Connect(function()
			local now = player:GetAttribute(ATTR.Title)
			if type(now) == "number" and now > shown then
				shown = now
				Sounds.play("StageUp")
				toasts.banner(`¡Nuevo título: {Titles.name(now)}!`, OverheadLook.mainColor(now))
			end
		end)
	end)
end

return TitleUnlock
