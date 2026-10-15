--!strict
--[[
	NumberFormat

	Números cortos para la interfaz: 950, 1.2K, 34K, 2.5M, 1.1B. El poder de
	pesca crece rápido y un número de 9 cifras no cabe en un móvil.
]]

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

function NumberFormat.short(value: number): string
	local sign = if value < 0 then "-" else ""
	local amount = math.abs(value)
	local index = 1
	while amount >= 1000 and index < #SUFFIXES do
		amount /= 1000
		index += 1
	end
	if index == 1 then
		return sign .. tostring(math.floor(amount))
	end
	local text = if amount >= 100
		then string.format("%d", math.floor(amount))
		else string.format("%.1f", amount)
	text = string.gsub(text, "%.0$", "")
	return sign .. text .. SUFFIXES[index]
end

-- Hito más alto de la serie 1-2-5 (1, 2, 5, 10, 20, 50, 100…) que ya alcanzó `count`.
function NumberFormat.milestone(count: number): number
	local best, step = 1, 1
	while step <= count do
		for _, factor in { 1, 2, 5 } do
			if step * factor <= count then
				best = step * factor
			end
		end
		step *= 10
	end
	return best
end

-- 920,741 con comas mientras quepa (menos de un millón); después, corto (54.2M).
function NumberFormat.big(value: number): string
	if math.abs(value) >= 1e6 then
		return NumberFormat.short(value)
	end
	local text = tostring(math.floor(math.abs(value)))
	local formatted = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
	formatted = string.gsub(formatted, "^,", "")
	return (if value < 0 then "-" else "") .. formatted
end

return NumberFormat
