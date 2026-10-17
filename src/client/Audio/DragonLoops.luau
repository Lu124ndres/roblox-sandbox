--!strict
--[[
	DragonLoops

	Los sonidos sostenidos de un dragón: la llama mientras echa fuego
	(DragonFireLoop) y el ronquido mientras duerme (DragonSnore). Cada cuadro
	se llama update(clave, encendido, posición, tono, volumen): el bucle se crea
	al encenderse en un Attachment que sigue al punto (boca o cabeza), y al
	apagarse baja el volumen en FADE segundos y se destruye. Pasan por
	Audio/Sounds (grupo de efectos del jugador, alcance de Sounds.define) y
	destroy() los corta todos.
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Sounds = require(script.Parent.Sounds)

local FADE = 0.6

export type Loops = {
	update: (key: string, on: boolean, position: Vector3, pitch: number, volume: number) -> (),
	destroy: () -> (),
}

type Live = { holder: Attachment, sound: Sound }

local DragonLoops = {}

local function fadeOut(live: Live)
	local info = TweenInfo.new(FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(live.sound, info, { Volume = 0 }):Play()
	task.delay(FADE + 0.05, function()
		live.holder:Destroy()
	end)
end

function DragonLoops.new(): Loops
	local live: { [string]: Live } = {}
	local missing: { [string]: boolean } = {} -- claves sin sonido: no se reintentan

	local function start(key: string, position: Vector3, pitch: number, volume: number)
		local holder = Instance.new("Attachment")
		holder.Name = `Bucle{key}`
		holder.WorldPosition = position
		holder.Parent = Workspace.Terrain
		local sound = Sounds.loop(key, holder)
		if not sound then
			holder:Destroy()
			missing[key] = true
			return
		end
		sound.PlaybackSpeed *= pitch
		local target = sound.Volume * volume
		sound.Volume = 0
		local info = TweenInfo.new(FADE * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(sound, info, { Volume = target }):Play()
		live[key] = { holder = holder, sound = sound }
	end

	local function update(
		key: string,
		on: boolean,
		position: Vector3,
		pitch: number,
		volume: number
	)
		local current = live[key]
		if on and not current and not missing[key] then
			start(key, position, pitch, volume)
		elseif on and current then
			current.holder.WorldPosition = position
		elseif current then
			live[key] = nil
			fadeOut(current)
		end
	end

	return {
		update = update,
		destroy = function()
			for key, current in live do
				live[key] = nil
				current.holder:Destroy()
			end
		end,
	}
end

return table.freeze(DragonLoops)
