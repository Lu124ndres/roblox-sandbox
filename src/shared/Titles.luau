--!strict
--[[
	Titles

	Qué título le toca a un poder (Config.Social.titles): el más alto que ya
	alcanzó. El servidor lo calcula con el poder MÁXIMO del jugador (no baja
	al renacer) y lo publica en el atributo Titulo (ProfilePublish); los
	clientes lo leen para el cartel sobre la cabeza y el aviso de título nuevo.
]]

local Config = require(script.Parent.Config)

local TITLES = Config.Social.titles

local Titles = {}

Titles.COUNT = #TITLES

function Titles.index(power: number): number
	local index = 1
	for i, title in TITLES do
		if power >= title.power then
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
