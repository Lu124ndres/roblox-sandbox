--!strict
--[[
	GuideRing

	El destino de cada tramo del tutorial (como el anillo de la referencia,
	referencias/Ejemplo.mp4): un aro de neón en el suelo, del verde de las
	flechas, que late y gira despacio. Se arma con tramos rectos (Roblox no
	tiene cilindros huecos). place lo apoya en el suelo y show lo prende.
	Solo en este cliente.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GuideArrow = require(script.Parent.GuideArrow)

local SEGMENTS = 28
local RADIUS = 5
local WIDTH = 0.7 -- ancho del aro
local THICK = 0.2
local BEAT_SPEED = 3.2 -- latidos por segundo (en radianes: ~0.5 por segundo)
local BEAT_SIZE = 0.12 -- cuánto crece al latir
local SPIN = 0.4 -- radianes por segundo
local RAY_UP, RAY_DOWN = 8, 30

export type Ring = {
	place: (position: Vector3) -> (),
	show: (visible: boolean) -> (),
}

local GuideRing = {}

function GuideRing.new(): Ring
	local model = Instance.new("Model")
	model.Name = "AnilloGuia"
	local parts: { BasePart } = {}
	local arc = 2 * math.pi * RADIUS / SEGMENTS * 1.08 -- un poco más largo: sin huecos
	for k = 1, SEGMENTS do
		local part = Instance.new("Part")
		part.Name = `Tramo{k}`
		part.Size = Vector3.new(arc, THICK, WIDTH)
		part.Color = GuideArrow.COLOR
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.CastShadow = false
		part.Transparency = 1
		part.Parent = model
		parts[k] = part
	end
	model.Parent = Workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false
	local center = Vector3.zero
	local visible = false
	local connection: RBXScriptConnection? = nil

	local function draw()
		local t = os.clock()
		local radius = RADIUS * (1 + math.sin(t * BEAT_SPEED) * BEAT_SIZE)
		local turn = t * SPIN
		for k, part in parts do
			local angle = turn + (k - 1) / SEGMENTS * 2 * math.pi
			local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
			-- Cada tramo, tangente al aro.
			part.CFrame = CFrame.lookAt(
				center + offset,
				center + offset + Vector3.new(-offset.Z, 0, offset.X)
			) * CFrame.Angles(0, math.rad(90), 0)
		end
	end

	local function show(on: boolean)
		if on == visible then
			return
		end
		visible = on
		for _, part in parts do
			part.Transparency = if on then 0.15 else 1
		end
		if on and not connection then
			connection = RunService.RenderStepped:Connect(draw)
		elseif not on and connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function place(position: Vector3)
		local character = Players.LocalPlayer.Character
		params.FilterDescendantsInstances = if character then { character, model } else { model }
		local hit = Workspace:Raycast(
			position + Vector3.new(0, RAY_UP, 0),
			Vector3.new(0, -RAY_DOWN, 0),
			params
		)
		center = if hit then hit.Position + Vector3.new(0, 0.15, 0) else position
	end

	return { place = place, show = show }
end

return GuideRing
