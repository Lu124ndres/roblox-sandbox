--!strict
--[[
	TutorialHud

	Mientras dura el tutorial, la interfaz muestra solo el tutorial (pedido del
	usuario: «quita todo lo demás, solo deja el tutorial»): se ocultan las
	columnas del menú y de estadísticas, los botones de arriba, el panel del
	gigante, los potenciadores y los atajos de Robux. Lo que hace falta para
	jugar sigue: los botones de acción (Pescar, Alimentar), los avisos de los
	ProximityPrompt, la barra de recoger y la tarjeta de captura.
	En el paso de comprar aparece solo MEJORAS: el botón real se saca de su
	columna (oculta) a un marco propio en el mismo lugar y, al terminar, vuelve
	a su fila. Al terminar el tutorial todo vuelve a la normalidad.
		set(active, lifted)  active: ocultar el HUD; lifted: el botón a mostrar
]]

local HudVisibility = require(script.Parent.Parent.Interface.HudVisibility)
local Layout = require(script.Parent.Parent.Interface.Layout)

local REASON = "tutorial"
local OTHERS = { "Hambre", "Impulsos", "AtajosRobux" } -- hijos de la pantalla del HUD
local LIFT_Z = 5 -- debajo del velo de HudFocus (9) y de las ventanas (10)

export type TutorialHud = { set: (active: boolean, lifted: GuiObject?) -> () }

local TutorialHud = {}

function TutorialHud.new(screen: ScreenGui): TutorialHud
	local parts: { GuiObject } = { Layout.stats(), Layout.menu(), Layout.topBar() }
	for _, name in OTHERS do
		local object = screen:FindFirstChild(name)
		if object and object:IsA("GuiObject") then
			table.insert(parts, object)
		end
	end

	local holder = Instance.new("Frame")
	holder.Name = "BotonTutorial"
	holder.BackgroundTransparency = 1
	holder.ZIndex = LIFT_Z
	holder.Visible = false
	holder.Parent = screen
	local holderScale = Instance.new("UIScale")
	holderScale.Parent = holder

	-- El botón que está afuera de su fila y dónde va al devolverlo.
	local liftedButton: GuiObject? = nil
	local home: Instance? = nil
	local homePosition = UDim2.new()

	local function place(button: GuiObject, origin: Vector2)
		local width = button.Size.X.Offset
		holderScale.Scale = if width > 0 then button.AbsoluteSize.X / width else 1
		holder.Position = UDim2.fromOffset(origin.X, origin.Y)
		holder.Size = UDim2.fromOffset(button.Size.X.Offset, button.Size.Y.Offset)
	end

	local function drop()
		local button = liftedButton
		if button and home then
			button.Position = homePosition
			button.Parent = home
		end
		liftedButton, home = nil, nil
		holder.Visible = false
	end

	local function lift(button: GuiObject)
		if liftedButton == button then
			return
		end
		drop()
		-- Dónde está ahora en la pantalla (la columna lo sigue ubicando aunque esté oculta).
		local origin = button.AbsolutePosition - screen.AbsolutePosition
		place(button, origin)
		liftedButton, home, homePosition = button, button.Parent, button.Position
		button.Position = UDim2.new()
		button.Parent = holder
		holder.Visible = true
	end

	-- Si cambia la pantalla, vuelve a su fila un momento para tomar su lugar nuevo.
	local wanted: GuiObject? = nil
	Layout.onScaleChanged(function()
		local button = liftedButton
		if not button then
			return
		end
		drop()
		task.wait() -- la columna lo reubica
		if wanted == button then
			lift(button)
		end
	end)

	local function set(active: boolean, lifted: GuiObject?)
		wanted = if active then lifted else nil
		for _, part in parts do
			HudVisibility.set(part, REASON, active)
		end
		if active and lifted then
			lift(lifted)
		else
			drop()
		end
	end

	return { set = set }
end

return TutorialHud
