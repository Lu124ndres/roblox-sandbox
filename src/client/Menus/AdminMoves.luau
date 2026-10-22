--!strict
--[[
	AdminMoves

	Volar y atravesar paredes para el admin, desde el panel (pestaña Moverse;
	pedido del usuario el 2026-10-21). Solo mueven al propio personaje, que
	Roblox ya deja manejar al cliente: el servidor no decide nada aquí.
		volar           se mueve hacia donde camina (WASD o el stick); Espacio o
		                R1 sube, Ctrl izquierdo o L1 baja
		sin colisión    ninguna pieza del personaje choca (atraviesa el mapa)
	Al reaparecer se apagan los dos.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FLY_SPEED = 90 -- studs por segundo
local UP_KEYS = { Enum.KeyCode.Space, Enum.KeyCode.ButtonR1 }
local DOWN_KEYS = { Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonL1 }

local AdminMoves = {}

local flyConnection: RBXScriptConnection? = nil
local flyParts: { Instance } = {}
local noclipConnection: RBXScriptConnection? = nil
local collided: { [BasePart]: boolean } = {} -- cómo chocaba cada pieza antes de apagarlo

local function held(keys: { Enum.KeyCode }): boolean
	for _, key in keys do
		if
			UserInputService:IsKeyDown(key)
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, key)
		then
			return true
		end
	end
	return false
end

local function parts(): (Model?, Humanoid?, BasePart?)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, if root and root:IsA("BasePart") then root else nil
end

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	for _, item in flyParts do
		item:Destroy()
	end
	flyParts = {}
	local _, humanoid = parts()
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function startFly()
	local _, humanoid, root = parts()
	if not humanoid or not root then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "VueloAdmin"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.Parent = root
	flyParts = { attachment, velocity, align }
	humanoid.PlatformStand = true
	flyConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local vertical = (if held(UP_KEYS) then 1 else 0) - (if held(DOWN_KEYS) then 1 else 0)
		velocity.VectorVelocity = (humanoid.MoveDirection + Vector3.new(0, vertical, 0)) * FLY_SPEED
		local look = if camera
			then camera.CFrame.LookVector * Vector3.new(1, 0, 1)
			else Vector3.zero
		if look.Magnitude > 0.01 then -- mirando justo abajo no hay hacia dónde girar
			align.CFrame = CFrame.lookAt(Vector3.zero, look)
		end
	end)
end

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	for part, could in collided do
		if part.Parent then
			part.CanCollide = could
		end
	end
	collided = {}
end

local function startNoclip()
	-- Roblox vuelve a prender el choque de algunas piezas: se apaga en cada paso de física.
	noclipConnection = RunService.Stepped:Connect(function()
		local character = parts()
		if not character then
			return
		end
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				if collided[part] == nil then
					collided[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
	end)
end

function AdminMoves.toggleFly()
	if flyConnection then
		stopFly()
	else
		startFly()
	end
end

function AdminMoves.flyLabel(): string
	return if flyConnection then "Volar: sí" else "Volar: no"
end

function AdminMoves.toggleNoclip()
	if noclipConnection then
		stopNoclip()
	else
		startNoclip()
	end
end

function AdminMoves.noclipLabel(): string
	return if noclipConnection then "Sin colisión: sí" else "Sin colisión: no"
end

function AdminMoves.start()
	Players.LocalPlayer.CharacterAdded:Connect(function()
		stopFly()
		stopNoclip()
	end)
end

return table.freeze(AdminMoves)
