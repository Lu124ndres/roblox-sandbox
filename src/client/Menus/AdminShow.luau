--!strict
--[[
	AdminShow

	Lo que los jugadores ven del panel de administrador en vivo: el anuncio
	(Notice "announce": cartel grande con la corona y el nombre del admin) y
	los fuegos artificiales (Notice "fireworks", Effects/Fireworks). El texto
	del anuncio ya viene filtrado por el servidor (Admin/AdminFun).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fireworks = require(script.Parent.Parent.Effects.Fireworks)
local Toasts = require(script.Parent.Parent.Toasts)

local ANNOUNCE_COLOR = Color3.fromRGB(255, 70, 90)

local AdminShow = {}

function AdminShow.start(toasts: Toasts.Toasts)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	notice.OnClientEvent:Connect(function(kind: unknown, a: unknown, b: unknown)
		if kind == "announce" and type(a) == "string" and type(b) == "string" then
			Sounds.play("EvolveShine")
			toasts.banner(b, ANNOUNCE_COLOR, "crown", `Admin {a}`)
		elseif kind == "fireworks" then
			Fireworks.play()
		end
	end)
end

return AdminShow
