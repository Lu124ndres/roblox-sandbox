--!strict
--[[
	BodyRig

	Las articulaciones R15 que BodyPose mueve por código y cómo sumarles una
	rotación encima de lo que dejó el Animator (igual que ArmPose con el
	hombro de la caña). Los C0 de R15 no vienen girados, así que los ejes son
	los del personaje:
		X  brazos, piernas y cabeza: positivo = hacia adelante (la cabeza, hacia
		   arriba); tronco: positivo = hacia atrás
		Y  giro: positivo = hacia la izquierda, visto desde arriba
		Z  brazos y piernas: positivo = hacia la derecha del personaje
	R6 no se anima (devuelve nil): sus articulaciones vienen giradas y el
	brazo de la caña ya lo mueve ArmPose.
]]

export type Writer = (offset: CFrame) -> ()
export type BodyRig = {
	joints: { [string]: Writer },
	legLength: number, -- cadera a tobillo en studs (cuánto baja al agacharse)
}

-- Nombre de la articulación -> parte que la contiene.
local JOINTS = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
	LeftAnkle = "LeftFoot",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	RightAnkle = "RightFoot",
}
local DEFAULT_LEG = 2

local BodyRig = {}

local function writerFor(joint: Instance?): Writer?
	if joint and joint:IsA("AnimationConstraint") then
		local constraint: AnimationConstraint = joint
		return function(offset: CFrame)
			constraint.Transform *= offset
		end
	elseif joint and joint:IsA("Motor6D") then
		local motor: Motor6D = joint
		return function(offset: CFrame)
			motor.Transform *= offset
		end
	end
	return nil
end

local function sizeY(character: Model, name: string): number
	local part = character:FindFirstChild(name)
	return if part and part:IsA("BasePart") then part.Size.Y else 0
end

function BodyRig.find(character: Model): BodyRig?
	local joints: { [string]: Writer } = {}
	for name, partName in JOINTS do
		local part = character:FindFirstChild(partName)
		local writer = writerFor(part and part:FindFirstChild(name))
		if writer then
			joints[name] = writer
		end
	end
	if not joints.Root or not joints.Waist then
		return nil
	end
	local leg = sizeY(character, "RightUpperLeg") + sizeY(character, "RightLowerLeg")
	return { joints = joints, legLength = if leg > 0 then leg else DEFAULT_LEG }
end

local function rad(degrees: number): number
	return math.rad(degrees)
end

-- Escribe los canales de BodyPose (grados; hop en studs) en las articulaciones.
function BodyRig.apply(rig: BodyRig, v: { [string]: number })
	local j = rig.joints
	local leg = rig.legLength
	local crouch, spread, stagger = v.crouch, v.spread, v.stagger
	local drop = leg * (1 - math.cos(rad(crouch))) + leg * 0.5 * (1 - math.cos(rad(spread)))
	j.Root(CFrame.new(0, v.hop - drop, 0))
	j.Waist(CFrame.Angles(rad(v.waistX), rad(v.waistY), rad(v.waistZ)))
	if j.Neck then
		j.Neck(CFrame.Angles(rad(v.neckX), rad(v.neckY), 0))
	end
	-- Piernas: la cadera va adelante, la rodilla el doble atrás y el tobillo
	-- deja el pie plano. El pie adelantado (stagger) dobla más la rodilla.
	local legs = {
		{ "Left", crouch + stagger, -spread, math.max(stagger, 0) },
		{ "Right", crouch - stagger * 0.6, spread, math.max(-stagger, 0) },
	}
	for _, side in legs do
		local name, hip, out, front = side[1], side[2], side[3], side[4]
		local knee = -(2 * crouch + front * 0.8)
		local hipJoint, kneeJoint, ankleJoint = j[`{name}Hip`], j[`{name}Knee`], j[`{name}Ankle`]
		if hipJoint then
			hipJoint(CFrame.Angles(rad(hip), 0, rad(out)))
		end
		if kneeJoint then
			kneeJoint(CFrame.Angles(rad(knee), 0, 0))
		end
		if ankleJoint then
			ankleJoint(CFrame.Angles(rad(-(hip + knee)), 0, 0))
		end
	end
	for _, name in { "Left", "Right" } do
		local prefix = if name == "Left" then "l" else "r"
		local shoulder, elbow = j[`{name}Shoulder`], j[`{name}Elbow`]
		local x, z = v[`{prefix}ShoulderX`], v[`{prefix}ShoulderZ`]
		if shoulder and (x ~= 0 or z ~= 0) then
			shoulder(CFrame.Angles(rad(x), 0, rad(z)))
		end
		if elbow then
			elbow(CFrame.Angles(rad(v[`{prefix}Elbow`]), 0, 0))
		end
	end
end

return BodyRig
