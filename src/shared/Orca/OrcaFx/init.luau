--!strict
--[[
	OrcaFx

	Sonidos y efectos de la orca, con los colores del modelo (dorado de la
	armadura, turquesa de las marcas, coral de la corona, cristal de la aleta):
		- nadando: burbujas turquesa, estela de espuma, la aleta de cristal
		  brilla y cada tanto un llamado con la voz de su etapa (Trails);
		- al salir a respirar: chorro por el espiráculo;
		- al saltar: salpicadura al salir y ola grande al caer, con destellos
		  dorados, coral y turquesa y temblor de cámara cerca;
		- en los trucos: coletazos, aletazos, rugidos, cascadas (Events);
		- al comer: llamado y salpicadura al asomarse, ondas alrededor y
		  destellos dorados en la boca; con cada pez, su animación especial
		  (Comida: chasquidos, chorros, cantos, olas; la Orca fantasma con
		  su toque espectral, Fantasma).
	Lee OrcaMotion.state cada cuadro y detecta los cambios (cruzar el agua,
	empezar a comer...). Los sonidos y salpicaduras son los del juego (hooks),
	así respetan el volumen, el alcance y el modo rápido.
]]

local WorldLayout = require(script.Parent.Parent.WorldLayout)
local OrcaMotion = require(script.Parent.OrcaMotion)
local Rig = require(script.Parent.OrcaMotion.Rig)
local Comida = require(script.Comida)
local Events = require(script.Events)
local Fantasma = require(script.Fantasma)
local Trails = require(script.Trails)

local WATER = WorldLayout.waterLevel
local BASE_HEIGHT = 16.5 -- etapa 1: tamaño 1 de los efectos
local CALL_MIN, CALL_MAX = 18, 35 -- segundos entre llamados mientras nada
local RING_SECONDS = 1.1 -- ondas mientras come
local COLORS = Trails.Colors

export type Hooks = Events.Hooks
export type Fx = {
	step: (dt: number) -> (),
	destroy: () -> (),
}

local OrcaFx = {}

function OrcaFx.new(motion: OrcaMotion.Motion, hooks: Hooks): Fx
	local trails: Trails.Trails? = nil
	local trailsFor: Rig.Rig? = nil
	local ghost: Fantasma.Fantasma? = nil
	local lastRel, lastBreath, wasFeeding = 0, 0, false
	local ringIn, callIn = 0, math.random(CALL_MIN, CALL_MAX)

	-- Destellos con los colores de la orca.
	local function burst(position: Vector3, scale: number)
		hooks.sparkle(position, COLORS.Gold, math.floor(12 * scale))
		hooks.sparkle(position, COLORS.Coral, math.floor(8 * scale))
		hooks.sparkle(position, COLORS.Teal, math.floor(10 * scale))
	end

	-- Cruzar la superficie rápido: sale de un salto o cae al agua.
	local function crossings(rel: number, height: number, scale: number)
		local state = motion.state
		local water = motion.water()
		if lastRel < 0 and rel >= 0 and state.vy > height * 0.5 then
			hooks.play("BigSplash", water, 1.25)
			hooks.splash(water, 2.2 * scale)
			hooks.sparkle(water + Vector3.new(0, height * 0.2, 0), COLORS.Crystal, 16)
		elseif lastRel > 0 and rel <= 0 and state.vy < -height * 0.5 then
			hooks.play("BigSplash", water, 0.85)
			hooks.splash(water, 4 * scale)
			for k = 1, 3 do
				hooks.ring(water, height * (0.5 + k * 0.4), 1 + k * 0.3)
			end
			burst(water + Vector3.new(0, height * 0.3, 0), scale)
			hooks.shake(water, 0.45, 0.9)
		end
	end

	local function step(dt: number)
		local state = motion.state
		if state.rig ~= trailsFor then
			if trails then
				Trails.destroy(trails)
			end
			if ghost then
				Fantasma.destroy(ghost)
			end
			trailsFor = state.rig
			trails = if state.rig then Trails.attach(state.rig) else nil
			ghost = if state.rig and state.ghost then Fantasma.attach(state.rig) else nil
		end
		if trails then
			Trails.update(trails, state, hooks.fxScale(), not state.hidden)
		end
		local height = state.height
		if ghost then
			Fantasma.update(ghost, dt, height, hooks.fxScale())
		end
		local rel = state.center.Y - WATER
		if state.hidden then
			table.clear(state.events)
			lastRel, wasFeeding = rel, false
			return
		end
		local scale = math.sqrt(height / BASE_HEIGHT)
		crossings(rel, height, scale)
		for _, event in state.events do
			if not Comida.play(event, motion, hooks, ghost) then
				Events.play(event, motion, hooks)
			end
		end
		table.clear(state.events)

		-- Vuelve a la superficie a respirar: chorro por el espiráculo.
		if state.breath < lastBreath and not state.trick and state.feeding < 0.3 then
			local blowhole = motion.top()
			hooks.spout(blowhole, math.max(1, height / 15))
			hooks.play("Spout", blowhole, math.clamp(1.2 / scale, 0.6, 1.2))
		end

		local feeding = state.feeding > 0.5
		if feeding and not wasFeeding then
			hooks.play("OrcaCall", motion.mouth(), state.voice)
			hooks.splash(motion.water(), 1.6 * scale)
		end
		if feeding then
			ringIn -= dt
			if ringIn <= 0 then
				ringIn = RING_SECONDS
				hooks.ring(motion.water(), height * 0.7, 1.4)
			end
		elseif not state.trick then
			callIn -= dt
			if callIn <= 0 then
				callIn = math.random(CALL_MIN, CALL_MAX)
				hooks.play("OrcaCall", motion.top(), state.voice * (0.9 + math.random() * 0.25))
			end
		end
		lastRel, lastBreath, wasFeeding = rel, state.breath, feeding
	end

	return {
		step = step,
		destroy = function()
			if trails then
				Trails.destroy(trails)
				trails = nil
			end
			if ghost then
				Fantasma.destroy(ghost)
				ghost = nil
			end
		end,
	}
end

return table.freeze(OrcaFx)
