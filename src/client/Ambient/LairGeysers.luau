--!strict
--[[
	LairGeysers

	Géiseres de fuego de la guarida volcánica, en las bocas de LairVents (en
	la repisa y en la laguna). Cada tanto revienta uno, de a uno y solo si
	alguien mira el cráter:
		aviso     la boca se enciende y se agranda, burbujea, suena un
		          borboteo y tiembla un poco (WARN_SECONDS);
		estallido una columna de fuego de neón sube de golpe y se apaga,
		          con llamas, brasas que vuelven a caer, humo, un fogonazo de
		          luz, el estruendo y una sacudida.
	En modo rápido no hay partículas, pero la columna y la luz siguen.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local LairParts = require(script.Parent.LairParts)
local LairVents = require(script.Parent.LairVents)

local P = LairParts
local MIN_WAIT, MAX_WAIT = 4, 10
local WARN_SECONDS = 1.8
local RISE_SECONDS = 0.3
local FADE_SECONDS = 1.4
local WATCH_DISTANCE = 450 -- la cámara a menos de esto del centro del cráter

Sounds.define({
	LairBubbles = { volume = 0.8, pitch = 0.6, rollOff = 350 },
	GeyserBurst = { volume = 0.9, pitch = 0.85, rollOff = 500 },
})

type Vent = LairVents.Vent

local LairGeysers = {}

local vents: { Vent } = {}
local folder: Instance? = nil
local rng = Random.new()

-- La columna de fuego: sube de golpe y se apaga adelgazando.
local function column(parent: Instance, v: Vent)
	for _, layer in { { 4.5, 0 }, { 9, 0.6 } } do
		local width, transparency = layer[1], layer[2]
		local part = P.part(
			parent,
			Vector3.new(0.5, width, width),
			CFrame.new(v.mouth) * P.UPRIGHT,
			P.MAGMA_HOT,
			{
				shape = Enum.PartType.Cylinder,
				material = Enum.Material.Neon,
				transparency = transparency,
			}
		)
		local top = CFrame.new(v.mouth + Vector3.new(0, v.height / 2, 0)) * P.UPRIGHT
		local up = TweenInfo.new(RISE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(part, up, { Size = Vector3.new(v.height, width, width), CFrame = top })
			:Play()
		local fade = TweenInfo.new(
			FADE_SECONDS,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			RISE_SECONDS
		)
		TweenService
			:Create(part, fade, { Transparency = 1, Size = Vector3.new(v.height, 0.5, 0.5) })
			:Play()
		Debris:AddItem(part, RISE_SECONDS + FADE_SECONDS + 0.2)
	end
end

local function erupt(v: Vent)
	local parent = folder
	if not parent then
		return
	end
	local warnInfo = TweenInfo.new(WARN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	v.warn.Enabled = true
	TweenService
		:Create(
			v.glow,
			warnInfo,
			{ Transparency = 0, Size = v.glowSize * Vector3.new(1, 1.8, 1.8) }
		)
		:Play()
	TweenService:Create(v.light, warnInfo, { Brightness = 2 }):Play()
	Sounds.play("LairBubbles", v.mouth)
	if P.near(v.mouth, 200) then
		CameraShake.shake(0.1, WARN_SECONDS)
	end
	task.wait(WARN_SECONDS)
	v.warn.Enabled = false
	column(parent, v)
	P.burst(v.fire, 30)
	P.burst(v.embers, 50)
	P.burst(v.smoke, 8)
	Sounds.play("GeyserBurst", v.mouth)
	if P.near(v.mouth, 260) then
		CameraShake.shake(0.3, 0.8)
	end
	v.light.Brightness = 8
	local after = TweenInfo.new(FADE_SECONDS + 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(v.light, after, { Brightness = 0 }):Play()
	TweenService:Create(v.glow, after, { Transparency = 0.45, Size = v.glowSize }):Play()
end

function LairGeysers.build(parent: Instance)
	folder = parent
	vents = LairVents.build(parent)
end

-- Mientras active() sea true, cada tanto revienta uno (nunca el mismo dos veces seguidas).
function LairGeysers.start(active: () -> boolean)
	task.spawn(function()
		local last = 0
		while true do
			task.wait(rng:NextNumber(MIN_WAIT, MAX_WAIT))
			if #vents > 0 and active() and P.near(P.CENTER, WATCH_DISTANCE) then
				local index = rng:NextInteger(1, #vents)
				if index == last then
					index = index % #vents + 1
				end
				last = index
				erupt(vents[index])
			end
		end
	end)
end

return table.freeze(LairGeysers)
