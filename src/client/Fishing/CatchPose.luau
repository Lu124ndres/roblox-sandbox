--!strict
--[[
	CatchPose

	El cuerpo del pescador al sacar un pez (FishingStates, estado "caught").
	Como se clava un anzuelo de verdad, un tirón corto y firme hacia arriba,
	pero exagerado: la espalda se va atrás, la caña apunta al cielo y el
	cuerpo se congela un instante en el tope (hitstop). Cuando el pez le
	llega sobre la cabeza, otro hitstop corto, un saltito y festeja: puño
	arriba, y desde raro la pose de trofeo con el pecho afuera.

	Solo animación: el tirón dura lo mismo que antes y el festejo, lo que el
	pez está en alto (CatchShow).
]]

local RigParts = require(script.Parent.RigParts)

type Rig = RigParts.Rig

local PULL_DEGREES = 140 -- antes 118: la caña casi vertical
local PULL_SECONDS = 0.16
local HITSTOP_AT = 0.11 -- el tope del tirón
local HITSTOP_SECONDS = 0.07
local TROPHY_FROM = 3 -- raro (como CatchShow)
local CHEER_DEGREES, TROPHY_DEGREES = 125, 150

local CatchPose = {}

function CatchPose.hookSet(rig: Rig)
	local generation = rig.generation
	if rig.pose then
		rig.pose.shake(0)
		rig.pose.set(PULL_DEGREES, PULL_SECONDS, Enum.EasingStyle.Back)
	end
	if rig.body then
		rig.body.play("hookSet", PULL_SECONDS * 0.9)
	end
	task.delay(HITSTOP_AT, function()
		if rig.generation ~= generation then
			return
		end
		if rig.pose then
			rig.pose.freeze(HITSTOP_SECONDS)
		end
		if rig.body then
			rig.body.hitstop(HITSTOP_SECONDS)
		end
	end)
end

-- El pez llegó sobre la cabeza y queda en alto holdSeconds; después vuelve a
-- la espera (holdDegrees). generation: la del estado "caught" que lo lanzó.
function CatchPose.landed(
	rig: Rig,
	generation: number,
	level: number,
	holdSeconds: number,
	holdDegrees: number
)
	local body, pose = rig.body, rig.pose
	if rig.generation ~= generation then
		return
	end
	local trophy = level >= TROPHY_FROM
	if body then
		body.hitstop(0.05 + level * 0.01)
		body.hop(0.25 + level * 0.12)
		body.play(if trophy then "trophy" else "catchCheer", 0.22)
	end
	if pose then
		pose.set(if trophy then TROPHY_DEGREES else CHEER_DEGREES, 0.25, Enum.EasingStyle.Back)
	end
	task.delay(holdSeconds + 0.2, function()
		if rig.generation ~= generation then
			return
		end
		if rig.body then
			rig.body.play("hold", 0.45)
		end
		if rig.pose then
			rig.pose.set(holdDegrees, 0.45, Enum.EasingStyle.Sine)
		end
	end)
end

return CatchPose
