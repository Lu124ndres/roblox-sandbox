--!strict
--[[
	AutoTranslate

	Si el jugador no tiene Roblox en español, pasa al inglés cada texto que aparece:
	la interfaz (PlayerGui), los carteles del mundo (BillboardGui y SurfaceGui) y los
	avisos de interacción (ProximityPrompt). Los módulos de interfaz siguen escribiendo
	en español; aquí se cambia el texto apenas se escribe.

	El atributo "Idioma" del jugador ("es" o "en") manda sobre el idioma de la cuenta:
	lo pone la opción de Ajustes y sirve para probar en Studio.

	En Studio guarda los textos sin traducción en `AutoTranslate.missing` para
	completar el diccionario (Lang/Dict).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lang = require(ReplicatedStorage.Shared.Lang)

local LANG_ATTR = "Idioma"
local TEXT_PROPS = { "Text", "PlaceholderText" }
local PROMPT_PROPS = { "ActionText", "ObjectText" }

local AutoTranslate = {}
AutoTranslate.missing = {} :: { [string]: boolean }

local active = false
local watched: { [Instance]: { RBXScriptConnection } } = {}
local written: { [Instance]: { [string]: string } } = {} -- lo último que escribimos
local originals: { [Instance]: { [string]: string } } = {} -- el español que reemplazamos

local function english(): boolean
	local player = Players.LocalPlayer
	local chosen = player:GetAttribute(LANG_ATTR)
	if chosen == "es" or chosen == "en" then
		return chosen == "en"
	end
	return not Lang.isSpanish(player.LocaleId)
end

local function apply(object: Instance, prop: string)
	if not active then
		return
	end
	local current = (object :: any)[prop] :: string
	local mine = written[object]
	if current == "" or (mine and mine[prop] == current) then
		return
	end
	local translated = Lang.toEnglish(current)
	if translated == current then
		if RunService:IsStudio() and string.find(current, "%a") then
			AutoTranslate.missing[current] = true
		end
		return
	end
	written[object] = written[object] or {}
	written[object][prop] = translated
	originals[object] = originals[object] or {}
	originals[object][prop] = current;
	(object :: any)[prop] = translated
end

local function propsOf(object: Instance): { string }?
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		return { "Text" }
	elseif object:IsA("TextBox") then
		return { "PlaceholderText" }
	elseif object:IsA("ProximityPrompt") then
		return PROMPT_PROPS
	end
	return nil
end

local function watch(object: Instance)
	if watched[object] then
		return
	end
	local props = propsOf(object)
	if not props then
		return
	end
	local connections = {}
	for _, prop in props do
		apply(object, prop)
		table.insert(
			connections,
			object:GetPropertyChangedSignal(prop):Connect(function()
				apply(object, prop)
			end)
		)
	end
	table.insert(
		connections,
		object.Destroying:Connect(function()
			for _, c in watched[object] or {} do
				c:Disconnect()
			end
			watched[object] = nil
			written[object] = nil
			originals[object] = nil
		end)
	)
	watched[object] = connections
end

-- En el mundo solo cuentan los textos dentro de carteles y los avisos
local function watchWorld(object: Instance)
	if
		object:IsA("ProximityPrompt")
		or (object:IsA("GuiObject") and object:FindFirstAncestorWhichIsA("LayerCollector"))
	then
		watch(object)
	end
end

-- Al volver al español, cada texto que sigue mostrando nuestra traducción recupera el
-- original; los que su módulo ya reescribió quedan como están
local function restore()
	for object, props in written do
		for prop, translated in props do
			local spanish = originals[object] and originals[object][prop]
			if spanish and (object :: any)[prop] == translated then
				(object :: any)[prop] = spanish
			end
		end
	end
	table.clear(written)
	table.clear(originals)
end

local function refresh()
	local wanted = english()
	if wanted == active then
		return
	end
	active = wanted
	if not active then
		restore()
		return
	end
	for object in watched do
		for _, prop in propsOf(object) or TEXT_PROPS do
			apply(object, prop)
		end
	end
end

function AutoTranslate.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	active = english()
	for _, object in playerGui:GetDescendants() do
		watch(object)
	end
	playerGui.DescendantAdded:Connect(watch)
	for _, object in workspace:GetDescendants() do
		watchWorld(object)
	end
	workspace.DescendantAdded:Connect(watchWorld)
	player:GetAttributeChangedSignal(LANG_ATTR):Connect(refresh)
	player:GetPropertyChangedSignal("LocaleId"):Connect(refresh)
end

-- Para módulos que arman texto fuera de un TextLabel (por ejemplo, el chat)
function AutoTranslate.text(text: string): string
	return if active then Lang.toEnglish(text) else text
end

return AutoTranslate
