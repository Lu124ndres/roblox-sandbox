--!strict
--[[
	TextCase

	string.upper solo cambia letras ASCII: "Más allá" quedaba "MáS ALLá".
	TextCase.upper también pasa a mayúscula las vocales con tilde, la ü y la ñ.
]]

local ACCENTS: { [string]: string } = {
	["á"] = "Á",
	["é"] = "É",
	["í"] = "Í",
	["ó"] = "Ó",
	["ú"] = "Ú",
	["ü"] = "Ü",
	["ñ"] = "Ñ",
}

local TextCase = {}

function TextCase.upper(text: string): string
	local result = string.upper(text)
	for lower, upper in ACCENTS do
		result = string.gsub(result, lower, upper)
	end
	return result
end

return TextCase
