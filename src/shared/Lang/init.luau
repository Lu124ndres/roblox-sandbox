--!strict
--[[
	Lang

	Traduce al inglés los textos del juego, que están escritos en español. Lo usa
	client/Lang/AutoTranslate sobre todo lo que aparece en pantalla, así los módulos
	de interfaz siguen escribiendo en español y no saben nada de idiomas.

	Las entradas viven en Lang/Dict/*.luau como ["texto en español"] = "English".
	- Se buscan sin importar mayúsculas: "PESCAR" usa la entrada de "Pescar" y la
	  respuesta sale en MAYÚSCULAS si el original lo estaba.
	- Una entrada con {} es una plantilla: "{} monedas" = "{} coins". Cada {} toma
	  cualquier pedazo y ese pedazo se traduce también (así "¡Pescaste un {}!" traduce
	  el nombre del pez). En inglés se pueden reordenar con {1}, {2}...
	- %d, %s, %02d y parecidos en la clave cuentan como {} (textos de string.format).
	- En texto enriquecido, si la frase entera no está, se traduce cada pedazo entre
	  etiquetas por separado.
]]

local TextCase = require(script.Parent.TextCase)

type Rule = { pattern: string, literal: number, out: string }

local exact: { [string]: string } = {}
local rules: { Rule } = {}
local memo: { [string]: string } = {}
local memoSize = 0
local MEMO_MAX = 3000 -- los contadores cambian cada segundo; se vacía al llenarse

local Lang = {}

local function normalize(text: string): string
	return TextCase.upper(text)
end

-- %d, %02d, %.1f, %s de string.format pasan a {}
local function unformat(text: string): string
	return (string.gsub(text, "%%[%-%d%.]*[dsfi]", "{}"))
end

local function escape(text: string): string
	return (string.gsub(text, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function addEntry(spanish: string, english: string)
	local key = normalize(unformat(spanish))
	local out = unformat(english)
	if not string.find(key, "{}", 1, true) then
		exact[key] = out
		return
	end
	local literal = #string.gsub(key, "{}", "")
	-- cada {} guarda dónde empieza y termina; TextCase.upper no cambia los bytes, así que
	-- las posiciones sirven para recortar el pedazo del texto original con sus minúsculas
	local pattern = "^" .. string.gsub(escape(key), "{}", "().-()") .. "$"
	table.insert(rules, { pattern = pattern, literal = literal, out = out })
end

for _, module in script.Dict:GetChildren() do
	if module:IsA("ModuleScript") then
		for spanish, english in require(module) :: { [string]: string } do
			addEntry(spanish, english)
		end
	end
end
-- Las plantillas con más texto fijo van primero: "{} monedas por pez" gana a "{} monedas"
table.sort(rules, function(a: Rule, b: Rule)
	return a.literal > b.literal
end)

local translate: (string) -> string?

-- Arma la salida de una plantilla: {} en orden, o {1} {2} si el inglés los reordena
local function fill(out: string, captures: { string }): string
	local nextIndex = 0
	return (
		string.gsub(out, "{(%d*)}", function(index: string): string
			local i = tonumber(index)
			if not i then
				nextIndex += 1
				i = nextIndex
			end
			local piece = captures[i] or ""
			return translate(piece) or piece
		end)
	)
end

local function matchCase(original: string, english: string): string
	if string.find(original, "%a") and normalize(original) == original then
		return string.upper(english)
	end
	-- «La Orca tiene hambre» empieza en mayúscula: «The Orca...», no «the Orca...»
	if string.find(original, "^%u") and string.find(english, "^%l") then
		return string.upper(string.sub(english, 1, 1)) .. string.sub(english, 2)
	end
	return english
end

-- La traducción de un texto sin espacios de los bordes, o nil si no hay entrada
local function lookup(core: string): string?
	if not string.find(core, "[%a\128-\255]") then
		return nil -- números, signos y emojis quedan igual
	end
	local key = normalize(core)
	local found = exact[key]
	if found then
		return matchCase(core, found)
	end
	-- Si varias plantillas encajan, gana la que deja menos pedazos con letras sin traducir
	-- («EXTRA · {}» sobre «{} monstruo» en «EXTRA · Ayuda a llenar 1 monstruo»); a igual
	-- cuenta, la de más texto fijo (el orden de rules). Los nombres de jugador no se
	-- traducen nunca, así que cuentan igual para todas.
	local best: string?, bestMissing = nil, math.huge
	for _, rule in rules do
		local marks = { string.match(key, rule.pattern) } :: { number }
		if #marks > 0 then
			local captures, missing = {}, 0
			for i = 1, #marks, 2 do
				local piece = string.sub(core, marks[i], marks[i + 1] - 1)
				table.insert(captures, piece)
				if string.find(piece, "%a") and not translate(piece) then
					missing += 1
				end
			end
			if missing < bestMissing then
				best, bestMissing = fill(rule.out, captures), missing
				if missing == 0 then
					break
				end
			end
		end
	end
	return if best then matchCase(core, best) else nil
end

translate = function(text: string): string?
	local lead, core, trail = string.match(text, "^(%s*)(.-)(%s*)$")
	if not core or core == "" then
		return nil
	end
	local result = lookup(core)
	if not result and string.find(core, "\n", 1, true) then
		-- varias líneas: cada una por su lado
		local lines, changed = {}, false
		for line in string.gmatch(core .. "\n", "(.-)\n") do
			local done = translate(line)
			changed = changed or done ~= nil
			table.insert(lines, done or line)
		end
		result = if changed then table.concat(lines, "\n") else nil
	end
	if not result and string.find(core, "<", 1, true) then
		-- texto enriquecido: cada pedazo entre etiquetas por su lado
		local changed = false
		result = string.gsub(core, "([^<>]+)(<?)", function(piece: string, tag: string): string
			local done = translate(piece)
			changed = changed or done ~= nil
			return (done or piece) .. tag
		end)
		if not changed then
			result = nil
		end
	end
	return if result then (lead :: string) .. result .. (trail :: string) else nil
end

-- El texto en inglés, o el mismo texto si no hay traducción
function Lang.toEnglish(text: string): string
	local cached = memo[text]
	if cached then
		return cached
	end
	local result = translate(text) or text
	if memoSize >= MEMO_MAX then
		table.clear(memo)
		memoSize = 0
	end
	memo[text] = result
	memoSize += 1
	return result
end

-- true si hay traducción (para listar en Studio lo que falta)
function Lang.has(text: string): boolean
	return translate(text) ~= nil
end

-- "es-mx" y "es-es" juegan en español; cualquier otro idioma, en inglés
function Lang.isSpanish(localeId: string): boolean
	return string.sub(string.lower(localeId), 1, 2) == "es"
end

return Lang
