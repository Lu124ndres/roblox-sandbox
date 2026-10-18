--!strict
--[[
	Zorro/Cara

	La cara del zorro: el único que escribe Parpado{l} y OrejaPunta{l} (huesos de
	detalle: si el modelo no los tiene, Rig.turn los salta). Solo corre con detalle
	(cámara cerca y sin modo rápido). Pendiente de la ola 3: parpadeo sincronizado,
	gestos por emoción (claves emo*) y la punta de las orejas con inercia.
]]

local Rig = require(script.Parent.Rig)
local Tipos = require(script.Parent.Tipos)

export type Pose = { [string]: number }

local Cara = {}

function Cara.apply(_rig: Rig.Rig, _p: Pose, _ctx: Tipos.Contexto) end

return table.freeze(Cara)
