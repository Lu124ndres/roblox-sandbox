--!strict
--[[
	Admin/AdminWorld

	Órdenes del panel que cambian el servidor (no a un jugador). Cada una
	recibe (valor, nombre del admin, admin) y devuelve el texto del aviso; el
	admin es nil cuando llega desde otro servidor (Admin/AdminGlobal), así que
	nada depende de que esté aquí.
		giant     "id" o "id:etapa": si está comiendo, ese monstruo ya en esa
		          etapa (1..4); si no, será el siguiente en llegar
		fill      fracción 0..1 de la barra del monstruo
		skipRest  termina el descanso del volcán
		restTime  +1 min de descanso (como el producto RestTime)
		event     "id" o "id:minutos": lanza ya ese evento (Config/Events)
		abuse     minutos: el evento AdminAbuse (x10 todo)
		stopEvent termina el evento activo
		time      hora 0..24: el cielo de todos se queda en esa hora (Workspace.HoraFija,
		          la lee Ambient/SkyCycle); "auto" vuelve al ciclo de día y noche
		boost     nivel: entrenamiento del servidor (como el producto ServerBoost<n>)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local EventScheduler = require(script.Parent.Parent.Social.EventScheduler)
local GiantCycle = require(script.Parent.Parent.GiantCycle)
local GiantService = require(script.Parent.Parent.GiantService)
local RestTime = require(script.Parent.Parent.Monetization.RestTime)
local ServerBoost = require(script.Parent.Parent.Monetization.ServerBoost)
local AdminPlayer = require(script.Parent.AdminPlayer)

export type Handler = (value: unknown, by: string, admin: Player?) -> string

local STAGES = #Config.Giants.stageThresholds
local FIXED_HOUR = "HoraFija" -- atributo de Workspace (Ambient/SkyCycle)
local MAX_EVENT_MINUTES = 120
local ABUSE = "AdminAbuse"

local function find(id: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == id then
			return def
		end
	end
	return nil
end

local function startEvent(id: string, minutes: number?): string
	assert(EventScheduler.force(id, minutes), "ese evento no existe")
	return if minutes then `Evento {id} por {minutes} min` else `Evento {id} en camino`
end

local HANDLERS: { [string]: Handler } = {
	giant = function(value)
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
	fill = function(value, _by, admin)
		local done = GiantService.fill(AdminPlayer.number(value, 0, 1), admin)
		return if done then "Barra llenada" else "Ahora no está comiendo"
	end,
	skipRest = function()
		GiantCycle.skipRest()
		return "Descanso terminado"
	end,
	restTime = function(_value, by)
		RestTime.addAs(by)
		return "+1 min de descanso"
	end,
	event = function(value)
		assert(type(value) == "string", "falta el evento")
		local id, minutesText = string.match(value, "^([%w_]+):?(%d*)$")
		assert(id, "falta el evento")
		local minutes = tonumber(minutesText)
		return startEvent(id, if minutes then math.clamp(minutes, 1, MAX_EVENT_MINUTES) else nil)
	end,
	abuse = function(value)
		return startEvent(ABUSE, math.floor(AdminPlayer.number(value, 1, MAX_EVENT_MINUTES)))
	end,
	stopEvent = function()
		EventScheduler.stop()
		return "Evento terminado"
	end,
	time = function(value)
		if value == "auto" then
			Workspace:SetAttribute(FIXED_HOUR, nil)
			return "Ciclo de día y noche normal"
		end
		local hour = AdminPlayer.number(value, 0, 24) % 24
		Workspace:SetAttribute(FIXED_HOUR, hour)
		local minutes = math.round(hour * 60) % (24 * 60)
		return `Hora fija: {string.format("%d:%02d", minutes // 60, minutes % 60)}`
	end,
	boost = function(value, by)
		local level =
			math.floor(AdminPlayer.number(value, 1, #Config.Monetization.serverBoost.robux))
		ServerBoost.addAs(by, level)
		return `Entrenamiento del servidor x{2 ^ level}`
	end,
}

return table.freeze({ HANDLERS = HANDLERS })
