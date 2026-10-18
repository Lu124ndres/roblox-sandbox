--!strict
--[[
	Zorro/Mirada

	Hacia dónde mira la cabeza: suma lookYaw y lookPitch a la pose para mirar al
	jugador de este cliente (ctx.lookAt) o a lo que pida la conducta. Pose.apply
	reparte el giro entre Cuello1, Cuello2 y Cabeza. Pendiente de la ola 3.
]]

local Tipos = require(script.Parent.Tipos)

export type Pose = { [string]: number }

local Mirada = {}

function Mirada.add(_pose: Pose, _ctx: Tipos.Contexto) end

return table.freeze(Mirada)
