--!strict
--[[
	ArmPose

	Mueve el brazo derecho por código, sin animaciones subidas: rota el hombro
	sobre el eje lateral del torso. 0 grados = brazo abajo; 90 = brazo al
	frente; 150 = brazo atrás por encima de la cabeza.

	Funciona con los tres tipos de hombro que puede tener un avatar: R15 con
	articulaciones nuevas (AnimationConstraint), R15 clásico (Motor6D) y R6.
	La pose se suma a lo que dejó el Animator en Transform, así que la
	animación de caminar de Roblox sigue funcionando debajo.

	Inactiva (setActive(false), para jugadores a media distancia) no toca el
	hombro: el ángulo sigue cambiando para que la caña lo use, pero el brazo
	queda como lo deja el Animator.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type ArmPose = {
	set: (degrees: number, seconds: number, style: Enum.EasingStyle?) -> (),
	angle: () -> number, -- ángulo actual en grados, con el temblor incluido
	shake: (degrees: number) -> (),
	setActive: (active: boolean) -> (), -- mover el hombro o no
	destroy: () -> (),
}

-- Suma una rotación a lo que el Animator dejó en el Transform del hombro.
type Joint = (rotation: CFrame) -> ()

local SHAKE_SPEED = 38 -- radianes por segundo del temblor cuando pica

local ArmPose = {}

-- Devuelve el hombro derecho y si es R6 (gira sobre otro eje).
local function findJoint(character: Model): (Joint?, boolean)
	local upperArm = character:FindFirstChild("RightUpperArm")
	local shoulder = upperArm and upperArm:FindFirstChild("RightShoulder")
	if shoulder and shoulder:IsA("AnimationConstraint") then
		local constraint: AnimationConstraint = shoulder
		return function(rotation: CFrame)
			constraint.Transform *= rotation
		end, false
	elseif shoulder and shoulder:IsA("Motor6D") then
		local motor: Motor6D = shoulder
		return function(rotation: CFrame)
			motor.Transform *= rotation
		end, false
	end
	local torso = character:FindFirstChild("Torso")
	local r6 = torso and torso:FindFirstChild("Right Shoulder")
	if r6 and r6:IsA("Motor6D") then
		local motor: Motor6D = r6
		return function(rotation: CFrame)
			motor.Transform *= rotation
		end, true
	end
	return nil, false
end

function ArmPose.new(character: Model, active: boolean?): ArmPose?
	local joint, isR6 = findJoint(character)
	if not joint then
		return nil
	end
	local angle = Instance.new("NumberValue")
	local shakeDegrees = 0
	local elapsed = 0
	local current = 0
	local connection: RBXScriptConnection? = nil

	-- El Animator escribe Transform antes de la simulación; se suma la pose
	-- justo después, así que la animación de caminar no la borra.
	local function step(dt: number)
		elapsed += dt
		current = angle.Value + math.sin(elapsed * SHAKE_SPEED) * shakeDegrees
		local radians = math.rad(current)
		local rotation = if isR6 then CFrame.Angles(0, 0, radians) else CFrame.Angles(radians, 0, 0)
		joint(rotation)
	end

	local function setActive(on: boolean)
		if on and not connection then
			connection = RunService.PreSimulation:Connect(step)
		elseif not on and connection then
			connection:Disconnect()
			connection = nil
		end
	end
	setActive(active ~= false)

	return {
		set = function(degrees: number, seconds: number, style: Enum.EasingStyle?)
			local info =
				TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(angle, info, { Value = degrees }):Play()
		end,
		angle = function(): number
			return if connection then current else angle.Value
		end,
		shake = function(degrees: number)
			shakeDegrees = degrees
		end,
		setActive = setActive,
		destroy = function()
			setActive(false)
			angle:Destroy()
		end,
	}
end

return ArmPose
