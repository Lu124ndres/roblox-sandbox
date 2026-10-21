--!strict
--[[
	OrcaFx/Comida

	Sonidos y efectos de la animación especial al comer (OrcaMotion/Comer):
		snap         chasquido de la mandíbula (como mucho uno cada SNAP_GAP s)
		gulp         traga
		shine        llegó un pez raro: destello en la boca y campanitas
		happySpout   chorro alegre por el espiráculo, con destellos turquesa
		belly        se gira mostrando la panza: chapoteo
		flick        coletazo chico que salpica
		wave         saluda con la aleta: destellos dorados en la aleta de arriba
		clicks       chasquidos de orca (la voz de su etapa)
		song         canto de orca (festejos)
		rareLaunch   sale del agua de un salto: salpicadura brillante
		partySplash  cae del tirabuzón: ola enorme, ondas y temblor
		shoreSlap    la ola llega a la orilla de quien le dio de comer y lo moja
	La Orca fantasma suma su toque espectral (Fantasma): un destello violeta,
	se vuelve transparente un instante y un brillo la atraviesa de la boca a
	la cola, con un soplido de espíritu en los momentos grandes.
	El tamaño sigue el alto de la orca; el tono, su voz (aguda la bebé).
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local OrcaMotion = require(script.Parent.Parent.OrcaMotion)
local Events = require(script.Parent.Events)
local Fantasma = require(script.Parent.Fantasma)
local Trails = require(script.Parent.Trails)

local WATER = WorldLayout.waterLevel
local BASE_HEIGHT = 16.5 -- etapa 1: tamaño 1 de los efectos
local SNAP_GAP = 0.28
local SHORE_REACH = 0.8 -- qué parte del camino hacia quien la alimenta recorre la ola
local COLORS = Trails.Colors
local GHOST = Fantasma.Colors

local Comida = {}

local lastSnap = 0

local function surface(position: Vector3): Vector3
	return Vector3.new(position.X, WATER, position.Z)
end

-- Destello con los colores de la orca (o los de la fantasma).
local function burst(
	position: Vector3,
	count: number,
	ghost: Fantasma.Fantasma?,
	hooks: Events.Hooks
)
	if ghost then
		hooks.sparkle(position, GHOST.Violet, math.floor(count * 1.1))
		hooks.sparkle(position, GHOST.Mint, count)
		hooks.sparkle(position, GHOST.Pumpkin, math.floor(count * 0.5))
	else
		hooks.sparkle(position, COLORS.Gold, count)
		hooks.sparkle(position, COLORS.Teal, count)
		hooks.sparkle(position, COLORS.Coral, math.floor(count * 0.6))
	end
end

-- La ola que moja la orilla: salpica entre la orca y quien le dio de comer.
local function shore(
	event: OrcaMotion.Event,
	motion: OrcaMotion.Motion,
	hooks: Events.Hooks,
	scale: number
)
	local water = motion.water()
	local spot = event.spot
	local target = if spot then surface(water:Lerp(surface(spot), SHORE_REACH)) else water
	hooks.play("OrcaTailSlap", target, 0.9)
	hooks.play("BigSplash", target, 0.8)
	hooks.splash(target, 3 * scale)
	for k = 1, 3 do
		hooks.ring(water, motion.state.height * (0.6 + k * 0.5), 1.2 + k * 0.3)
	end
	if spot then -- unas gotas le llegan encima
		hooks.splash(spot, 1.1)
	end
	hooks.shake(target, 0.2 + 0.15 * scale, 0.6)
end

-- Devuelve true si el evento es de la comida (y ya sonó).
function Comida.play(
	event: OrcaMotion.Event,
	motion: OrcaMotion.Motion,
	hooks: Events.Hooks,
	ghost: Fantasma.Fantasma?
): boolean
	local state = motion.state
	local height = state.height
	local scale = math.sqrt(height / BASE_HEIGHT)
	local deep = math.clamp(1.25 / scale, 0.55, 1.3) -- las grandes suenan más grave
	local voice = state.voice
	local kind = event.kind
	local size = event.size or 1
	if kind == "snap" then
		if os.clock() - lastSnap < SNAP_GAP then
			return true
		end
		lastSnap = os.clock()
		hooks.play("OrcaSnap", motion.mouth(), deep * 1.1, 0.8 + 0.1 * math.min(size, 4))
		if ghost then
			hooks.sparkle(motion.mouth(), GHOST.Violet, 4)
		end
	elseif kind == "gulp" then
		hooks.play("OrcaGulp", motion.mouth(), deep * 0.9)
	elseif kind == "shine" then
		local mouth = motion.mouth()
		hooks.play("OrcaShine", mouth, 1 + 0.08 * size, 0.6 + 0.15 * size)
		burst(mouth, 8 + 6 * size, ghost, hooks)
		if ghost then
			Fantasma.pulse(ghost, 0.25 + 0.08 * size)
		end
	elseif kind == "happySpout" then
		local blowhole = motion.top()
		hooks.spout(blowhole, math.max(1, height / 15) * 1.35)
		hooks.play("OrcaHappySpout", blowhole, deep, 0.8)
		hooks.sparkle(
			blowhole + Vector3.new(0, height * 0.35, 0),
			if ghost then GHOST.Mint else COLORS.Teal,
			14
		)
		if ghost then
			Fantasma.pulse(ghost, 0.3)
		end
	elseif kind == "belly" then
		hooks.play("Plop", motion.water(), deep)
		hooks.splash(motion.water(), 1.4 * scale)
	elseif kind == "flick" then
		local tail = surface(motion.point("Cola5") or motion.point("Cola4") or state.center)
		hooks.play("OrcaTailSlap", tail, 1.2 * deep, 0.7)
		hooks.splash(tail, 1.8 * scale)
		hooks.ring(tail, height * 0.5, 1)
	elseif kind == "wave" then
		local left = motion.point("AletaIzq2") or motion.point("AletaIzq")
		local right = motion.point("AletaDer2") or motion.point("AletaDer")
		local upper = if left
				and right
				and right.Y > left.Y
			then right
			else left or right or motion.top()
		hooks.sparkle(upper, if ghost then GHOST.Violet else COLORS.Gold, 10)
		if ghost then
			Fantasma.sweep(ghost, 0.8)
		end
	elseif kind == "clicks" then
		hooks.play("OrcaClicks", motion.mouth(), voice * 1.1)
	elseif kind == "song" then
		local top = motion.top()
		hooks.play("OrcaSong", top, voice)
		hooks.play("OrcaCall", top, voice * 1.05)
		burst(top + Vector3.new(0, height * 0.3, 0), 10, ghost, hooks)
		if ghost then
			hooks.play("OrcaGhostWhoosh", top, voice * 0.8)
			Fantasma.pulse(ghost, 0.5)
			Fantasma.sweep(ghost, 1.2)
		end
	elseif kind == "rareLaunch" then
		local water = motion.water()
		hooks.play("OrcaShine", water, 0.9, 1)
		hooks.splash(water, 2.6 * scale)
		burst(water + Vector3.new(0, height * 0.3, 0), 18, ghost, hooks)
		hooks.sparkle(water + Vector3.new(0, height * 0.2, 0), COLORS.Crystal, 24)
		if ghost then
			hooks.play("OrcaGhostWhoosh", state.center, deep)
			Fantasma.pulse(ghost, 0.65)
			Fantasma.sweep(ghost, 1)
		end
	elseif kind == "partySplash" then
		local water = motion.water()
		hooks.play("OrcaPartySplash", water, deep)
		hooks.splash(water, 4.5 * scale)
		for k = 1, 4 do
			hooks.ring(water, height * (0.6 + k * 0.45), 1.1 + k * 0.35)
		end
		burst(water + Vector3.new(0, height * 0.4, 0), 22, ghost, hooks)
		hooks.shake(water, 0.55, 1.1)
		if ghost then
			Fantasma.pulse(ghost, 0.55)
		end
	elseif kind == "shoreSlap" then
		shore(event, motion, hooks, scale)
	else
		return false
	end
	return true
end

return table.freeze(Comida)
