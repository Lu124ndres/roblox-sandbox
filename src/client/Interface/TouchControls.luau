--!strict
--[[
	TouchControls

	Dónde dibuja Roblox sus controles táctiles (PlayerGui.TouchGui), para que el
	HUD no los tape:
		thumbstickTop   borde de arriba del joystick (abajo a la izquierda)
		jumpTop         borde de arriba del botón de saltar (abajo a la derecha)
	En píxeles absolutos (los de AbsolutePosition del HUD); nil si ese control no
	se ve (PC, mando, o todavía no apareció). Se leen del TouchGui real y no de
	medidas fijas: Roblox los cambia de tamaño según la pantalla.
	`onChange` avisa cuando aparecen, se mueven o se ocultan.
]]

local Players = game:GetService("Players")

local TouchControls = {}

local listeners: { () -> () } = {}
local watched: { RBXScriptConnection } = {}
local pending = false

local function shown(object: GuiObject?): boolean
	if not object then
		return false
	end
	local gui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if not gui or not gui.Enabled then
		return false
	end
	local current: Instance? = object
	while current and current:IsA("GuiObject") do
		if not current.Visible then
			return false
		end
		current = current.Parent
	end
	return object.AbsoluteSize.Y > 0
end

local function find(name: string): GuiObject?
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local found = touchGui and touchGui:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") then found else nil
end

local function top(object: GuiObject?): number?
	return if object and shown(object) then object.AbsolutePosition.Y else nil
end

function TouchControls.jumpTop(): number?
	return top(find("JumpButton"))
end

function TouchControls.thumbstickTop(): number?
	-- Joystick dinámico (el de siempre): su aro de reposo. Clásico: el marco es el aro.
	return top(find("ThumbstickStart") or find("ThumbstickFrame"))
end

local function notify()
	if pending then
		return
	end
	pending = true
	task.defer(function()
		pending = false
		for _, listener in listeners do
			task.spawn(listener)
		end
	end)
end

local function watch(object: Instance)
	if object:IsA("GuiObject") then
		table.insert(watched, object:GetPropertyChangedSignal("AbsolutePosition"):Connect(notify))
		table.insert(watched, object:GetPropertyChangedSignal("AbsoluteSize"):Connect(notify))
		table.insert(watched, object:GetPropertyChangedSignal("Visible"):Connect(notify))
	end
end

-- Sigue al TouchGui: Roblox lo crea al aparecer el personaje y lo rehace al cambiar de control.
local function follow(touchGui: Instance)
	for _, connection in watched do
		connection:Disconnect()
	end
	table.clear(watched)
	if touchGui:IsA("ScreenGui") then
		table.insert(watched, touchGui:GetPropertyChangedSignal("Enabled"):Connect(notify))
	end
	for _, name in { "TouchControlFrame", "JumpButton", "ThumbstickStart", "ThumbstickFrame" } do
		local object = touchGui:FindFirstChild(name, true)
		if object then
			watch(object)
		end
	end
	notify()
end

function TouchControls.onChange(listener: () -> ())
	table.insert(listeners, listener)
end

function TouchControls.start(playerGui: Instance)
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if touchGui then
		follow(touchGui)
	end
	playerGui.ChildAdded:Connect(function(child: Instance)
		if child.Name == "TouchGui" then
			follow(child)
		end
	end)
	-- Las piezas del TouchGui llegan de a poco (el joystick se arma después del salto).
	playerGui.DescendantAdded:Connect(function(descendant: Instance)
		local touchGui2 = descendant:FindFirstAncestor("TouchGui")
		if touchGui2 and touchGui2.Parent == playerGui then
			follow(touchGui2)
		end
	end)
	playerGui.ChildRemoved:Connect(function(child: Instance)
		if child.Name == "TouchGui" then
			notify()
		end
	end)
end

return TouchControls
