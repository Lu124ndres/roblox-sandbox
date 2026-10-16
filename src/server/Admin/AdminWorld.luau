--!strict
--[[
	Admin/AdminWorld

	Órdenes del panel que cambian el servidor (no a un jugador):
		giant     "id" o "id:etapa": si está comiendo, ese monstruo ya en esa
		          etapa (1..4); si no, será el siguiente en llegar
		fill      fracción 0..1 de la barra del monstruo
		skipRest  termina el descanso del volcán
		restTime  +1 min de descanso (como el producto RestTime)
		event     id: lanza ya ese evento del servidor (Config/Events)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EventScheduler = require(script.Parent.Parent.Social.EventScheduler)
local GiantCycle = require(script.Parent.Parent.GiantCycle)
local GiantService = require(script.Parent.Parent.GiantService)
local RestTime = require(script.Parent.Parent.Monetization.RestTime)
local AdminPlayer = require(script.Parent.AdminPlayer)

local STAGES = #Config.Giants.stageThresholds

local function find(id: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == id then
			return def
		end
	end
	return nil
end

local HANDLERS: { [string]: AdminPlayer.Handler } = {
	giant = function(_target, value)
		assert(type(value) == "string", "falta el monstruo")
		local id, stageText = string.match(value, "^([%w_]+):?(%d*)$")
		local def = id and find(id)
		assert(def, "ese monstruo no existe")
		local stage = math.clamp(tonumber(stageText) or 1, 1, STAGES)
		if GiantService.getPhase() == "feeding" and not GiantService.isFull() then
			GiantService.reset(def, stage)
			return `Ahora: {def.displayName}, etapa {stage}`
		end
		GiantCycle.setNext(def)
		return `Siguiente monstruo: {def.displayName} (la etapa se elige mientras come)`
	end,
	fill = function(target, value)
		local done = GiantService.fill(AdminPlayer.number(value, 0, 1), target)
		return if done then "Barra llenada" else "Ahora no está comiendo"
	end,
	skipRest = function()
		GiantCycle.skipRest()
		return "Descanso terminado"
	end,
	restTime = function(_target, _value, admin)
		RestTime.add(admin)
		return "+1 min de descanso"
	end,
	event = function(_target, value)
		assert(type(value) == "string", "falta el evento")
		EventScheduler.force(value)
		return `Evento {value} en camino`
	end,
}

return table.freeze({ HANDLERS = HANDLERS })
