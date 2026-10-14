--!strict
--[[
	GiantName

	Nombre del gigante actual con su artículo ("la Orca", "el Minotauro"),
	leído del estado que replica el servidor. Lo usan los avisos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ATTR = Protocol.GiantAttributes

local GiantName = {}

-- "la Orca". Con capitalize = true: "La Orca".
function GiantName.current(capitalize: boolean?): string
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local name = stateFolder:GetAttribute(ATTR.DisplayName)
	local article = stateFolder:GetAttribute(ATTR.Article)
	local text = if type(name) == "string" and type(article) == "string"
		then `{article} {name}`
		else "el gigante"
	if capitalize then
		text = string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
	end
	return text
end

return GiantName
