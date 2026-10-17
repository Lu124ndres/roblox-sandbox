--!strict
--[[
	Dragon/Fx

	Lee DragonMotion.state cada cuadro y lo convierte en efectos y "cues"
	(momentos con sonido o efecto que dibuja el cliente, hooks.cue):
		fuego     el chorro de llamas (Fuego) mientras state.fire; con el evento
		          fireSky apunta al cielo (y arde FIRE_SKY segundos aunque el
		          comportamiento no encienda state.fire). Cues fireStart/fireEnd.
		eventos   cada evento del dragón (roar, whoosh, flap, takeoff, land, fold,
		          stretch, preen, sleep, wake, fireSky, evolve... y los que vengan)
		          pasa tal cual como cue: el cliente sabe cuáles suenan.
		aletazos  cue flap (o hover si está quieto en el aire) con la fuerza del
		          aletazo medida en el ala (Aleteo): planeando no suena.
		estelas   aire en las puntas de las alas al ir rápido, picar, despegar o
		          con la alegría de comer (joy: vuelta, aletazo de gloria).
	Con efectos reducidos (fxScale 0) no se ve el fuego ni las estelas; los
	cues siguen (los sonidos los respeta el cliente).
]]

local Aleteo = require(script.Parent.Aleteo)
local Estelas = require(script.Parent.Estelas)
local Fuego = require(script.Parent.Fuego)
local Tipos = require(script.Parent.Tipos)

export type Cue = {
	stage: number, -- 1 cría … 4 anciano (del nombre del modelo)
	voice: number,
	length: number,
	strength: number?, -- 0..1, solo en flap y hover
}
export type Hooks = {
	cue: (kind: string, cue: Cue) -> (),
	fxScale: () -> number,
}
export type Fx = { step: (dt: number) -> (), destroy: () -> () }

local FIRE_SKY = 2.5 -- segundos de fuego al cielo si el comportamiento no lo enciende
local SKY_EASE = 6 -- qué tan rápido gira el chorro hacia arriba y vuelve
local TAKEOFF_TRAILS = 1.5 -- segundos de estelas después de despegar
local MIN_STROKE = 0.2 -- fuerza mínima para que un aletazo suene
local HOVER_SPEED = 8 -- studs/s: más lento y aleteando = quieto en el aire

local DragonFx = {}

-- Etapa por el nombre del modelo (…E1 … E4, también …E2_v2); sin rig, la cría.
function DragonFx.stage(rig: any): number
	local name = if rig then rig.model.Name else ""
	return math.clamp(tonumber(string.match(name, "E(%d)")) or 1, 1, 4)
end

function DragonFx.new(motion: Tipos.Motion, hooks: Hooks): Fx
	local breath: Fuego.Fuego? = nil
	local trails: Estelas.Estelas? = nil
	local wing = Aleteo.new()
	local boundTo: any = nil
	local stage = 1
	local firing = false
	local skyUntil, sky = 0, 0
	local takeoffAt = -math.huge

	local function cue(kind: string, strength: number?)
		local state = motion.state
		hooks.cue(kind, {
			stage = stage,
			voice = state.voice,
			length = state.length,
			strength = strength,
		})
	end

	local function unbind()
		if breath then
			Fuego.destroy(breath)
		end
		if trails then
			Estelas.destroy(trails)
		end
		breath, trails = nil, nil
	end

	local function bind(rig: any)
		unbind()
		boundTo, stage, wing = rig, DragonFx.stage(rig), Aleteo.new()
		if rig and rig.bones.Boca and rig.bones.Cabeza then
			breath = Fuego.build(rig.bones.Boca)
		end
		trails = if rig then Estelas.build(rig) else nil
	end

	local function step(dt: number)
		local state = motion.state
		local rig = state.rig
		if rig ~= boundTo then
			bind(rig)
		end
		local now = os.clock()
		local events = state.events
		for _, event in events do
			if event.kind == "fireSky" then
				skyUntil = now + FIRE_SKY
			elseif event.kind == "takeoff" or event.kind == "joy" then
				takeoffAt = now
			end
			cue(event.kind)
		end
		table.clear(events)

		-- Fuego: el del comportamiento o, tras fireSky, el del cielo.
		local skyOn = now < skyUntil
		if skyOn and state.fire then
			skyUntil = math.max(skyUntil, now + 0.15) -- sigue al cielo mientras arda
		end
		local fire = (state.fire or skyOn) and not state.hidden
		sky += ((if skyOn then 1 else 0) - sky) * (1 - math.exp(-dt * SKY_EASE))
		if fire ~= firing then
			firing = fire
			cue(if fire then "fireStart" else "fireEnd")
		end
		local visible = hooks.fxScale() > 0
		local b = breath
		if b and rig then
			local L = state.length * state.fireSize
			if math.abs(b.length - L) > b.length * 0.08 then
				Fuego.resize(b, L)
			end
			Fuego.step(b, rig.bones.Boca, rig.bones.Cabeza, fire and visible, sky)
		end

		if trails then
			local boost = math.clamp(1 - (now - takeoffAt) / TAKEOFF_TRAILS, 0, 1)
			Estelas.step(trails, state, hooks.fxScale(), boost)
		end

		-- Un aletazo por vuelta de la fase, si el ala de verdad barrió el aire.
		if rig and not state.hidden then
			local strength = Aleteo.step(wing, rig, state)
			if strength and strength >= MIN_STROKE then
				local hovering = state.feeding > 0.5 or state.velocity.Magnitude < HOVER_SPEED
				cue(if hovering then "hover" else "flap", strength)
			end
		end
	end

	return {
		step = step,
		destroy = unbind, -- los bucles de sonido los corta el cliente
	}
end

return table.freeze(DragonFx)
