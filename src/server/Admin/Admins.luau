--!strict
--[[
	Admin/Admins

	Quiénes son administradores, por UserId. No depende de nada para que cualquier
	módulo del servidor lo pueda pedir sin ciclos: AdminService (el panel), Passes y
	ProfilePublish (los pases de prueba solo cuentan para un admin).
]]

-- UserId de los administradores (lu124ndres).
local ADMINS: { [number]: boolean } = {
	[147364237] = true,
}

local Admins = {}

function Admins.is(player: Player): boolean
	return ADMINS[player.UserId] == true
end

-- Por UserId, para lo que no tiene al jugador a mano (las llaves de los rankings).
function Admins.isId(userId: number): boolean
	return ADMINS[userId] == true
end

return table.freeze(Admins)
