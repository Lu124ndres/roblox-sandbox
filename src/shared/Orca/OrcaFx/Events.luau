--!strict
--[[
	OrcaFx/Events

	Sonidos y efectos de los momentos de cada truco (OrcaMotion.state.events):
		call     llamado con la voz de su edad (chillidos de cría, llamado de
		         ballena la adulta, grave la anciana: OrcaFx/Voz)
		roar     rugido con la boca abierta, destellos y temblor de cámara
		slap     coletazo o aletazo: salpicadura y onda donde pega
		spout    chorro grande por el espiráculo
		splash   salpicadura chica bajo el cuerpo
		cascade  el agua cae del lomo al emerger (varias salpicaduras alrededor)
	El tamaño de todo sigue el alto de la orca.
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local OrcaMotion = require(script.Parent.Parent.OrcaMotion)
local Trails = require(script.Parent.Trails)
local Voz = require(script.Parent.Voz)

local WATER = WorldLayout.waterLevel
local BASE_HEIGHT = 16.5 -- etapa 1: tamaño 1 de los efectos
local COLORS = Trails.Colors

export type Hooks = {
	play: (key: string, position: Vector3?, pitch: number?, volume: number?) -> (),
	splash: (position: Vector3, scale: number) -> (),
	ring: (position: Vector3, radius: number, seconds: number?) -> (),
	sparkle: (position: Vector3, color: Color3, count: number?) -> (),
	spout: (position: Vector3, scale: number) -> (),
	shake: (position: Vector3, magnitude: number, seconds: number) -> (), -- más fuerte cerca
	fxScale: () -> number, -- 0 en modo rápido
}

local Events = {}

local function under(position: Vector3): Vector3
	return Vector3.new(position.X, WATER, position.Z)
end

-- La aleta pectoral que quedó arriba (la que golpea el agua al rodar).
local function upperFin(motion: OrcaMotion.Motion): Vector3?
	local left, right = motion.point("AletaIzq"), motion.point("AletaDer")
	if left and right then
		return if left.Y > right.Y then left else right
	end
	return left or right
end

function Events.play(event: OrcaMotion.Event, motion: OrcaMotion.Motion, hooks: Hooks)
	local state = motion.state
	local height = state.height
	local scale = math.sqrt(height / BASE_HEIGHT)
	local deep = math.clamp(1.25 / scale, 0.55, 1.3) -- las grandes suenan más grave
	local kind = event.kind
	local size = event.size or 1 -- fuerza que pide el truco (la ola de la anciana, el soplo hondo)
	if kind == "call" then
		Voz.call(hooks.play, motion.top(), height, state.voice)
	elseif kind == "roar" then
		local mouth = motion.mouth()
		if Voz.stage(height) >= 3 then
			hooks.play("Roar", mouth, state.voice * 0.9)
		end
		Voz.call(hooks.play, mouth, height, state.voice * 0.8, 1, true)
		hooks.sparkle(mouth, COLORS.Teal, 24)
		hooks.sparkle(mouth, COLORS.Gold, 16)
		hooks.shake(state.center, 0.35 + 0.25 * scale, 1.6)
	elseif kind == "slap" then
		local hit = if event.where == "fin"
			then upperFin(motion)
			else motion.point("Cola5") or motion.point("Cola4")
		local spot = under(hit or state.center)
		hooks.play("BigSplash", spot, 1.3 * deep)
		hooks.splash(spot, 2.4 * scale * size)
		hooks.ring(spot, height * 0.6, 1.3)
		hooks.sparkle(spot + Vector3.new(0, height * 0.15, 0), COLORS.Crystal, 10)
		hooks.shake(spot, 0.15 * scale, 0.5)
	elseif kind == "spout" then
		local blowhole = motion.top()
		hooks.spout(blowhole, math.max(1, height / 15) * 1.3 * size)
		Voz.blow(hooks.play, blowhole, deep)
	elseif kind == "splash" then
		local spot = motion.water()
		hooks.play("Plop", spot, 1.2 * deep)
		hooks.splash(spot, 1.6 * scale * size)
	elseif kind == "cascade" then
		hooks.play("BigSplash", motion.water(), 0.7 * deep)
		for k = 1, 6 do
			local angle = k / 6 * math.pi * 2
			local spot = motion.water()
				+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * height * 0.5
			hooks.splash(spot, 1.8 * scale * size)
		end
		hooks.sparkle(state.center + Vector3.new(0, height * 0.4, 0), COLORS.Crystal, 30)
	end
end

return table.freeze(Events)
