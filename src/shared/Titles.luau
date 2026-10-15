--!strict
--[[
	Titles

	Qué título le toca a un jugador por sus monstruos llenados (kills,
	Config.Social.titles): el más alto que ya alcanzó. El servidor lo publica
	en el atributo Titulo (ProfilePublish); los clientes lo leen para el
	cartel sobre la cabeza, el aviso de título nuevo y la siguiente meta.
]]

local Config = require(script.Parent.Config)

local TITLES = Config.Social.titles

local Titles = {}

Titles.COUNT = #TITLES

function Titles.index(kills: number): number
	local index = 1
	for i, title in TITLES do
		if kills >= title.kills then
			index = i
		end
	end
	return index
end

function Titles.name(index: number): string
	local title = TITLES[math.clamp(index, 1, #TITLES)]
	return title.name
end

return Titles
