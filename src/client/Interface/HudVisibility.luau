--!strict
--[[
	HudVisibility

	Varias cosas quieren ocultar las mismas partes del HUD por motivos
	distintos: HudFocus (en táctil, con una ventana abierta) y TutorialHud
	(mientras dura el tutorial). Cada una dice su motivo y la parte se ve solo
	si nadie la está ocultando, así no se pisan (si una la mostrara, taparía lo
	que la otra escondió).
		set(object, reason, hidden)
]]

local HudVisibility = {}

local reasons: { [GuiObject]: { [string]: true } } = {}

function HudVisibility.set(object: GuiObject, reason: string, hidden: boolean)
	local list = reasons[object] or {}
	reasons[object] = list
	list[reason] = if hidden then true else nil
	object.Visible = next(list) == nil
end

return HudVisibility
