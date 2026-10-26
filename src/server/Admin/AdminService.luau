--!strict
--[[
	AdminService

	Panel de pruebas solo para los administradores (Admins, por UserId; vive
	en el servidor, nadie más lo ve). A ellos se les marca el atributo
	EsAdmin y el cliente muestra el panel. Cada orden llega por AdminCommand
	(nombre, valor, UserId del jugador elegido) y se vuelve a comprobar aquí
	que quien la manda sea admin. Las órdenes y sus valores: AdminCommands.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local AdminCommands = require(script.Parent.AdminCommands)
local AdminGlobal = require(script.Parent.AdminGlobal)
local Admins = require(script.Parent.Admins)

local AdminService = {}

local isAdmin = Admins.is

-- targetId: UserId del jugador elegido en el panel (nil = el mismo admin).
local function onCommand(player: Player, name: unknown, value: unknown, targetId: unknown)
	if not isAdmin(player) or type(name) ~= "string" then
		return
	end
	local target = if type(targetId) == "number"
		then Players:GetPlayerByUserId(targetId)
		else player
	local text: string
	if not target then
		text = "Ese jugador ya no está en el servidor"
	else
		local ok, result: any = pcall(AdminCommands.run, player, target, name, value)
		-- Sin la ruta del script que traen los errores de assert («Modulo:63: »).
		text = if ok
			then tostring(result)
			else `Error: {(string.gsub(tostring(result), "^.-:%d+: ", ""))}`
		if target ~= player and AdminCommands.isPersonal(name) then
			text = `{target.DisplayName}: {text}`
		end
	end
	Remotes.Notice:FireClient(player, "admin", text)
end

function AdminService.init()
	local function mark(player: Player)
		if isAdmin(player) then
			player:SetAttribute(Protocol.PlayerAttributes.IsAdmin, true)
		end
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in Players:GetPlayers() do
		mark(player)
	end
	Remotes.AdminCommand.OnServerEvent:Connect(RateLimit.wrap("AdminCommand", 10, 20, onCommand))
	AdminGlobal.init()
end

return AdminService
