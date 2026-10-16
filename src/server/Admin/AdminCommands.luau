--!strict
--[[
	AdminCommands

	Reparte las órdenes del panel de administrador (AdminService ya comprobó
	quién las manda): run(admin, objetivo, nombre, valor) devuelve el texto
	del aviso. Las de un jugador están en AdminPlayer (se aplican al objetivo,
	que puede ser el mismo admin u otro jugador) y las del servidor en AdminWorld.
]]

local AdminPlayer = require(script.Parent.AdminPlayer)
local AdminWorld = require(script.Parent.AdminWorld)

local HANDLERS: { [string]: AdminPlayer.Handler } = {}
for name, handler in AdminPlayer.HANDLERS do
	HANDLERS[name] = handler
end
for name, handler in AdminWorld.HANDLERS do
	HANDLERS[name] = handler
end

local AdminCommands = {}

-- true si la orden cambia a un jugador (el aviso dice a quién).
function AdminCommands.isPersonal(name: string): boolean
	return AdminPlayer.HANDLERS[name] ~= nil
end

function AdminCommands.run(admin: Player, target: Player, name: string, value: unknown): string
	local handler = HANDLERS[name]
	assert(handler, `orden desconocida: {name}`)
	return handler(target, value, admin)
end

return table.freeze(AdminCommands)
