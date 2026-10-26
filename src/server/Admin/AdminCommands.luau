--!strict
--[[
	AdminCommands

	Reparte las órdenes del panel de administrador (AdminService ya comprobó
	quién las manda): run(admin, objetivo, nombre, valor) devuelve el texto
	del aviso. Tres alcances:
		jugador       AdminPlayer, AdminShop y AdminModeration: (objetivo, valor, admin)
		este servidor AdminWorld y AdminFun: (valor, nombre del admin, admin)
		todos         el nombre empieza con "g:" (ej. "g:announce"): Admin/AdminGlobal
		              la manda a todos los servidores
]]

local AdminFun = require(script.Parent.AdminFun)
local AdminGlobal = require(script.Parent.AdminGlobal)
local AdminModeration = require(script.Parent.AdminModeration)
local AdminPlayer = require(script.Parent.AdminPlayer)
local AdminShop = require(script.Parent.AdminShop)
local AdminWorld = require(script.Parent.AdminWorld)

local GLOBAL_PREFIX = "g:"

local PERSONAL: { [string]: AdminPlayer.Handler } = {}
for _, group in { AdminPlayer.HANDLERS, AdminShop.HANDLERS, AdminModeration.HANDLERS } do
	for name, handler in group do
		PERSONAL[name] = handler
	end
end
local SERVER: { [string]: AdminWorld.Handler } = table.clone(AdminWorld.HANDLERS)
for name, handler in AdminFun.HANDLERS do
	SERVER[name] = handler
end

local AdminCommands = {}

-- true si la orden cambia a un jugador (el aviso dice a quién).
function AdminCommands.isPersonal(name: string): boolean
	return PERSONAL[name] ~= nil
end

function AdminCommands.run(admin: Player, target: Player, name: string, value: unknown): string
	if string.sub(name, 1, #GLOBAL_PREFIX) == GLOBAL_PREFIX then
		local global = string.sub(name, #GLOBAL_PREFIX + 1)
		assert(AdminGlobal.has(global), `orden desconocida: {name}`)
		return AdminGlobal.send(admin, global, value)
	end
	local personal = PERSONAL[name]
	if personal then
		return personal(target, value, admin)
	end
	local server = SERVER[name]
	assert(server, `orden desconocida: {name}`)
	return server(value, admin.DisplayName, admin)
end

return table.freeze(AdminCommands)
