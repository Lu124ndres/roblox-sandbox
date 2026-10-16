--!strict
--[[
	Dragon/Fx

	Sonidos y efectos del dragón: lee DragonMotion.state cada cuadro.
		fuego     chorro de llamas desde la boca hacia adelante de la cabeza,
		          con chispas y una luz que ilumina todo (trucos de fuego)
		roar      rugido con la voz de su etapa y temblor de cámara cerca
		estelas   aire en las puntas de las alas al ir rápido o picar (Estelas)
		whoosh    el aire al pasar rápido (picadas, volteretas)
		aletazos  cada bajada del ala suena (los grandes, más grave y fuerte)
	Los sonidos y destellos son los del juego (hooks): respetan volumen,
	alcance y el modo de efectos reducidos.
]]

local Estelas = require(script.Parent.Estelas)
local Tipos = require(script.Parent.Tipos)

export type Hooks = {
	play: (key: string, position: Vector3?, pitch: number?) -> (),
	sparkle: (position: Vector3, color: Color3, count: number?) -> (),
	shake: (position: Vector3, magnitude: number, seconds: number) -> (),
	fxScale: () -> number,
}
export type Fx = { step: (dt: number) -> (), destroy: () -> () }

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/fire_sparks_main.dds"
local rgb = Color3.fromRGB

local DragonFx = {}

type Breath = {
	socket: Bone,
	flames: ParticleEmitter,
	sparks: ParticleEmitter,
	light: PointLight,
	length: number,
}

local function build(rig: any): Breath?
	local boca, cabeza = rig.bones.Boca, rig.bones.Cabeza
	if not boca or not cabeza then
		return nil
	end
	local forward = (boca.WorldPosition - cabeza.WorldPosition).Unit
	local socket = Instance.new("Bone")
	socket.Name = "Fuego"
	socket.CFrame = boca.WorldCFrame:ToObjectSpace(
		CFrame.lookAt(boca.WorldPosition, boca.WorldPosition + forward)
	)
	socket.Parent = boca
	local flames = Instance.new("ParticleEmitter")
	flames.Texture = FIRE
	flames.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 250, 200)),
		ColorSequenceKeypoint.new(0.3, rgb(255, 160, 40)),
		ColorSequenceKeypoint.new(1, rgb(150, 20, 5)),
	})
	flames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	flames.LightEmission = 1
	flames.LightInfluence = 0
	flames.EmissionDirection = Enum.NormalId.Front
	flames.Rotation = NumberRange.new(0, 360)
	flames.RotSpeed = NumberRange.new(-120, 120)
	flames.Lifetime = NumberRange.new(0.45, 0.7)
	flames.SpreadAngle = Vector2.new(9, 9)
	flames.LockedToPart = true -- el dragón vuela más rápido que el chorro: que viaje con la boca
	flames.Rate = 70
	flames.Enabled = false
	flames.Parent = socket
	local sparks = flames:Clone()
	sparks.Texture = SPARK
	sparks.Rate = 40
	sparks.SpreadAngle = Vector2.new(20, 20)
	sparks.Parent = socket
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 140, 40)
	light.Brightness = 4
	light.Enabled = false
	light.Parent = socket
	return { socket = socket, flames = flames, sparks = sparks, light = light, length = 0 }
end

local function resize(breath: Breath, length: number, size: number)
	breath.length = length
	local L = length * size
	breath.flames.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05 * L),
		NumberSequenceKeypoint.new(0.4, 0.18 * L),
		NumberSequenceKeypoint.new(1, 0.3 * L),
	})
	breath.flames.Speed = NumberRange.new(1.1 * L, 1.5 * L)
	breath.flames.Acceleration = Vector3.new(0, 0.2 * L, 0)
	breath.sparks.Size = NumberSequence.new(0.02 * L, 0)
	breath.sparks.Speed = NumberRange.new(1.2 * L, 1.8 * L)
	breath.light.Range = math.min(1.2 * L, 60)
end

function DragonFx.new(motion: Tipos.Motion, hooks: Hooks): Fx
	local breath: Breath? = nil
	local trails: Estelas.Estelas? = nil
	local boundTo: any = nil
	local lastStroke = 0
	local firing = false

	local function step(_dt: number)
		local state = motion.state
		if state.rig ~= boundTo then
			if breath then
				breath.socket:Destroy()
			end
			if trails then
				Estelas.destroy(trails)
			end
			boundTo = state.rig
			breath = if state.rig then build(state.rig) else nil
			trails = if state.rig then Estelas.build(state.rig) else nil
		end
		if trails then
			Estelas.step(trails, state, hooks.fxScale())
		end
		local b = breath
		if b and math.abs(b.length - state.length) > b.length * 0.08 then
			resize(b, state.length, state.fireSize)
		end
		local fire = state.fire and not state.hidden and hooks.fxScale() > 0
		if b then
			b.flames.Enabled, b.sparks.Enabled, b.light.Enabled = fire, fire, fire
		end
		if fire and not firing then
			hooks.play("Roar", motion.mouth(), state.voice * 0.8)
		end
		firing = fire
		local events = state.events
		for _, event in events do
			if event.kind == "roar" then
				hooks.play("Roar", motion.mouth(), state.voice)
				hooks.shake(state.center, 0.3 + state.length * 0.006, 1.6)
				hooks.sparkle(motion.mouth(), rgb(255, 170, 60), 18)
			elseif event.kind == "whoosh" or event.kind == "flap" then
				hooks.play("Whoosh", state.center, 0.6 * state.voice)
			end
		end
		table.clear(events)
		-- Un aletazo por vuelta de la fase (en la bajada).
		local stroke = math.floor((state.phase + math.pi / 2) / (2 * math.pi))
		if stroke ~= lastStroke and not state.hidden then
			lastStroke = stroke
			if state.length > 25 then
				hooks.play("Whoosh", state.center, math.clamp(0.9 - state.length / 250, 0.35, 0.9))
			end
		end
	end

	return {
		step = step,
		destroy = function()
			if breath then
				breath.socket:Destroy()
			end
			if trails then
				Estelas.destroy(trails)
			end
		end,
	}
end

return table.freeze(DragonFx)
