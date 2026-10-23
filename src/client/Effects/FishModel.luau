--!strict
--[[
	FishModel

	Pez de primitivas para las animaciones (el que sale del agua, el trofeo,
	los que vuelan al gigante y los que saltan en el mar). Cada especie se ve
	distinta (FishShapes): cuerpo de dos tonos, ojos con pupila, cola en V,
	aletas y sus rasgos propios (FishFeatures). Los épicos o mejores llevan
	destellos del color de su rareza, los legendarios brillan y el mítico
	cambia de color sin parar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FishFeatures = require(script.Parent.FishFeatures)
local FishGlow = require(script.Parent.FishGlow)
local FishShapes = require(script.Parent.FishShapes)
local Squash = require(script.Parent.Squash)

local AURA_FROM_RARITY = 4 -- épico en adelante
local BLACK = Color3.fromRGB(16, 16, 24)
local WHITE = Color3.fromRGB(250, 250, 250)
local ARC_STRETCH, LAND_SQUASH = 0.4, 0.4 -- estirar al volar y aplastar al llegar (Squash)

local FishModel = {}

local oval, fin = FishFeatures.oval, FishFeatures.fin

-- El pez mira hacia -Z (su LookVector), con el pivote en el centro del cuerpo.
function FishModel.build(fishId: string, scale: number): Model
	local shape = FishShapes[fishId] or FishShapes.Sardina
	local s = shape.size * scale
	local model = Instance.new("Model")
	model.Name = `Pez{fishId}`

	local body = oval(model, "Cuerpo", s, shape.body, CFrame.new())
	body.Reflectance = 0.05
	model.PrimaryPart = body
	oval(
		model,
		"Panza",
		Vector3.new(s.X * 0.92, s.Y * 0.6, s.Z * 0.82),
		shape.belly,
		CFrame.new(0, -s.Y * 0.2, 0)
	)

	-- Ojos con pupila.
	local eye = math.max(0.16, s.Y * 0.24)
	for side = -1, 1, 2 do
		local center = Vector3.new(side * s.X * 0.4, s.Y * 0.12, -s.Z * 0.3)
		local white =
			FishFeatures.part(model, `Ojo{side}`, Vector3.one * eye, WHITE, CFrame.new(center))
		white.Shape = Enum.PartType.Ball
		local pupil = FishFeatures.part(
			model,
			`Pupila{side}`,
			Vector3.one * eye * 0.58,
			BLACK,
			CFrame.new(center + Vector3.new(side * eye * 0.25, 0, -eye * 0.08))
		)
		pupil.Shape = Enum.PartType.Ball
	end

	-- Cola en V y aletas.
	local tailLength = s.Z * 0.32
	for side = -1, 1, 2 do
		local lobe = Vector3.new(0.08 * scale, s.Y * 0.5, tailLength)
		fin(
			model,
			`AletaCola{side}`,
			lobe,
			shape.fin,
			CFrame.new(0, side * s.Y * 0.2, s.Z * 0.56)
				* CFrame.Angles(math.rad(side * 38), 0, 0)
				* CFrame.Angles(0, 0, if side > 0 then 0 else math.pi)
		)
		local pectoral = Vector3.new(0.05 * scale, s.Y * 0.22, s.Z * 0.18)
		fin(
			model,
			`AletaLado{side}`,
			pectoral,
			shape.fin,
			CFrame.new(side * s.X * 0.48, -s.Y * 0.12, -s.Z * 0.08)
				* CFrame.Angles(0, math.rad(side * 25), math.rad(side * 20))
		)
	end
	local dorsalHeight = s.Y * (if shape.tallFins then 0.75 else 0.4)
	fin(
		model,
		"AletaLomo",
		Vector3.new(0.06 * scale, dorsalHeight, s.Z * 0.42),
		shape.fin,
		CFrame.new(0, s.Y * 0.42 + dorsalHeight * 0.4, s.Z * 0.04)
	)
	if shape.tallFins then
		fin(
			model,
			"AletaPanza",
			Vector3.new(0.06 * scale, dorsalHeight * 0.8, s.Z * 0.32),
			shape.fin,
			CFrame.new(0, -s.Y * 0.42 - dorsalHeight * 0.32, s.Z * 0.1)
				* CFrame.Angles(0, 0, math.pi)
		)
	end

	FishFeatures.add(model, shape, s, scale)

	if shape.glow then
		local light = Instance.new("PointLight")
		light.Color = shape.glow
		light.Range = 9 * scale
		light.Brightness = 1.6
		light.Parent = body
	end
	local rarity, level = FishCatalog.rarity(fishId)
	if level >= AURA_FROM_RARITY then
		FishGlow.aura(body, UIConfig.RarityColors[rarity.id] or WHITE, scale)
	end
	if shape.rainbow then
		FishGlow.rainbow(model)
	end
	model.WorldPivot = CFrame.new()
	model.Parent = Workspace
	return model
end

-- Pose de un pez en arco de "from" a "to" en la fracción t (0..1) del vuelo.
-- elapsed (segundos) mueve el coleteo; turns = vueltas completas en el aire.
-- Sin conexiones: la usan arc y los vuelos que comparten un solo bucle (FeedFlights).
function FishModel.arcPose(
	from: Vector3,
	to: Vector3,
	height: number,
	t: number,
	elapsed: number,
	turns: number
): CFrame
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local heading = if flat.Magnitude > 0.01
		then CFrame.lookAt(Vector3.zero, flat)
		else CFrame.new()
	local position = from:Lerp(to, t) + Vector3.new(0, height * 4 * t * (1 - t), 0)
	local pitch = math.rad(70 - 140 * t) -- sube con la nariz arriba y cae de cabeza
	local wiggle = math.sin(elapsed * 30) * 0.4
	local roll = t * turns * math.pi * 2
	return CFrame.new(position) * heading.Rotation * CFrame.Angles(pitch, wiggle, roll)
end

-- Salto en arco de "from" a "to" girando, estirado según la velocidad; llama
-- onDone al terminar.
-- spins = vueltas completas en el aire (0 = solo cabecea).
function FishModel.arc(
	model: Model,
	from: Vector3,
	to: Vector3,
	height: number,
	seconds: number,
	onDone: (() -> ())?,
	spins: number?
)
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		local t = math.min(elapsed / seconds, 1)
		local pose = FishModel.arcPose(from, to, height, t, elapsed, spins or 0)
		Squash.pivot(model, pose, Squash.arc(t, ARC_STRETCH))
		if t >= 1 then
			connection:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
end

-- Coletazos en el lugar (mano o sobre la cabeza) por "seconds"; llega aplastado y rebota.
function FishModel.flop(model: Model, anchor: () -> CFrame, seconds: number, onDone: (() -> ())?)
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		local wag = math.sin(elapsed * 22) * 0.5 * math.max(0, 1 - elapsed / seconds * 0.5)
		local pose = anchor() * CFrame.Angles(math.rad(-75), wag, 0)
		Squash.pivot(model, pose, Squash.impact(elapsed, LAND_SQUASH))
		if elapsed >= seconds then
			connection:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
end

return FishModel
