--!strict
--[[
	Zorro/Colas/Prueba

	Para probar las colas con execute_luau en Play, con el modelo ya preparado
	(ReplicatedStorage.ModelosGigantes.ZorroDeAguaE4: pivote en la base, Y arriba):
	simula a 60 cuadros por segundo SIN escribir huesos y devuelve lo peor que vio:
		maxJoint  rad: la junta más doblada (tope 0.785)
		minGap    rad: lo más cerca que quedaron dos vecinas en el abanico
		minTip    alto de la punta más baja sobre el piso (en altos de la cadera)
		maxJump   rad: el mayor cambio de una junta de un cuadro al otro (saltos)
		minRoom   lo más que tuvo que acercar una cola al reposo por un choque
		final     Colas.leer al terminar (los giros de cada tramo)
	simular(model, plan, seconds, detail?)  plan(u) da el Intent y el BodyInfo a
	                                       los u segundos
	escenas: reposo, giro, giroRapido, salto, lucirse, sentado, dormir, correr,
	sacudida, comer, latigazo. todas(model) corre cada una y devuelve el resumen.
	Ejemplo:
		local Prueba = require(game.ReplicatedStorage.Shared.Zorro.Colas.Prueba)
		local model = game.ReplicatedStorage.ModelosGigantes.ZorroDeAguaE4
		for name, r in Prueba.todas(model) do
			print(name, r.maxJoint, r.minGap, r.minTip, r.maxJump, r.minRoom)
		end
]]

local Colas = require(script.Parent)
local Etapas = require(script.Parent.Parent.Etapas)
local Rig = require(script.Parent.Parent.Rig)

export type Plan = (u: number) -> (Colas.Intent, Colas.BodyInfo)
export type Resultado = {
	maxJoint: number,
	minGap: number,
	minTip: number,
	maxJump: number,
	minRoom: number,
	final: Colas.Lectura?,
}
type Escena = { seconds: number, plan: Plan }

local FPS = 60
local START = 1000 -- hora ficticia de inicio (la onda solo depende de la hora)

local function still(giro: number?, avance: number?, subida: number?, sacudida: number?)
	return { giro = giro or 0, avance = avance or 0, subida = subida or 0, sacudida = sacudida or 0 }
end
local function inside(u: number, a: number, b: number): number
	return if u >= a and u <= b then 1 else 0
end

local ESCENAS: { [string]: Escena } = {
	reposo = {
		seconds = 6,
		plan = function(_u)
			return {}, still()
		end,
	},
	giro = {
		seconds = 4,
		plan = function(u)
			return {}, still(0.8 * inside(u, 0.5, 2))
		end,
	},
	giroRapido = {
		seconds = 3,
		plan = function(u)
			return { meneo = 0.6 }, still(2.5 * inside(u, 0.5, 1.5))
		end,
	},
	salto = {
		seconds = 3,
		plan = function(u)
			-- dy = 0.35 · sin(π (u - 0.5) / 0.97) en el aire: su derivada es la subida.
			local air = inside(u, 0.5, 1.47)
			return {},
				still(0, 0, air * 0.35 * math.pi / 0.97 * math.cos(math.pi * (u - 0.5) / 0.97))
		end,
	},
	lucirse = {
		seconds = 5,
		plan = function(u)
			return { abanico = 1.4 * inside(u, 0.5, 3.5), alto = 0.5 * inside(u, 0.5, 3.5) },
				still()
		end,
	},
	sentado = {
		seconds = 5,
		plan = function(u)
			return { envolver = inside(u, 0.5, 5) }, still()
		end,
	},
	dormir = {
		seconds = 6,
		plan = function(u)
			return { enroscar = inside(u, 0.5, 6), calma = 0.3 }, still()
		end,
	},
	correr = {
		seconds = 4,
		plan = function(u)
			return {}, still(0.6, 1.5 * inside(u, 0.5, 4))
		end,
	},
	sacudida = {
		seconds = 3,
		plan = function(u)
			return { meneo = 1.2 * inside(u, 0.3, 1.8) }, still(0, 0, 0, inside(u, 0.3, 1.8))
		end,
	},
	comer = {
		seconds = 4,
		plan = function(u)
			return { meneo = 0.8, gusto = math.clamp(u / 3, 0, 1), alto = 0.15 }, still()
		end,
	},
	latigazo = {
		seconds = 3,
		plan = function(_u)
			return { latigazo = START + 0.5 }, still()
		end,
	},
}

local Prueba = {}

Prueba.escenas = ESCENAS

function Prueba.simular(model: Model, plan: Plan, seconds: number, detail: boolean?): Resultado?
	local rig = Rig.bind(model)
	local c = rig and Colas.new(rig, Etapas.forModel(model.Name))
	if not c then
		return nil
	end
	c.dry = true
	local out: Resultado =
		{ maxJoint = 0, minGap = math.huge, minTip = math.huge, maxJump = 0, minRoom = 1 }
	local before: { [string]: { fan: number, fold: number } }? = nil
	local dt = 1 / FPS
	for frame = 0, math.ceil(seconds * FPS) do
		local u = frame * dt
		local intent, body = plan(u)
		Colas.step(c, intent, body, START + u, dt, detail ~= false)
		local read = Colas.leer(c)
		out.maxJoint = math.max(out.maxJoint, read.maxJoint)
		out.minGap = math.min(out.minGap, read.minGap)
		out.minTip = math.min(out.minTip, read.minTip)
		for _, room in read.room do
			out.minRoom = math.min(out.minRoom, room)
		end
		if before then
			for name, now in read.bones do
				local last = before[name]
				local jump = math.max(math.abs(now.fan - last.fan), math.abs(now.fold - last.fold))
				out.maxJump = math.max(out.maxJump, jump)
			end
		end
		before = read.bones
		out.final = read
	end
	return out
end

function Prueba.todas(model: Model, detail: boolean?): { [string]: Resultado }
	local out = {}
	for name, escena in ESCENAS do
		out[name] = Prueba.simular(model, escena.plan, escena.seconds, detail)
	end
	return out
end

return table.freeze(Prueba)
