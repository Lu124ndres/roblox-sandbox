--!strict
--[[
	Bobber

	Corcho de la pesca: vuela en arco desde la punta de la caña (rápido al
	salir y frenando al caer; más lejos, más alto y más largo), cae con
	salpicadura, flota con vaivén y ondas, mordisquea cuando pica y se hunde
	si el pez se escapa. Curva el sedal (setLine): recto mientras vuela,
	colgando mientras flota (sale de la punta hacia abajo y llega al corcho
	casi a ras del agua) y más tenso cuando pica. Efecto local: el servidor no sabe que existe.
	Para jugadores a media distancia se apagan las ondas (setRipples).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)

export type Mode = "flying" | "floating" | "nibble" | "sinking"
export type Bobber = {
	attachment: Attachment, -- donde se ata el sedal
	setMode: (mode: Mode) -> (),
	setRipples: (on: boolean) -> (), -- ondas en el agua alrededor del corcho
	setLine: (line: Beam, tip: Attachment) -> (), -- sedal (desde la punta) que curva según el momento
	position: () -> Vector3,
	destroy: () -> (),
}

local COLORS = UIConfig.Colors
local EFFECTS = UIConfig.Effects

local Bobber = {}

local function ball(name: string, size: number, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

-- from: punta de la caña; target: punto del agua donde cae.
function Bobber.cast(from: Vector3, target: Vector3, startFloating: boolean?): Bobber
	local folder = Instance.new("Folder")
	folder.Name = "Corcho"
	folder.Parent = Workspace
	local float = ball("Cuerpo", EFFECTS.BobberSize, COLORS.Bobber, folder)
	local top = ball("Punta", EFFECTS.BobberSize * 0.55, COLORS.BobberTop, folder)
	-- Hacia dónde voló (plano): el sedal llega al corcho desde el lado del jugador.
	local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
	local outward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis
	local attachment = Instance.new("Attachment")
	attachment.CFrame =
		CFrame.fromMatrix(Vector3.new(0, EFFECTS.BobberSize * 0.5, 0), outward, Vector3.yAxis)
	attachment.Parent = float

	-- Estela mientras vuela.
	local trailEnd = Instance.new("Attachment")
	trailEnd.Position = Vector3.new(0, -EFFECTS.BobberSize * 0.5, 0)
	trailEnd.Parent = float
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment
	trail.Attachment1 = trailEnd
	trail.Lifetime = 0.3
	trail.Color = ColorSequence.new(COLORS.Bobber, COLORS.BobberTop)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.FaceCamera = true
	trail.Enabled = not startFloating
	trail.Parent = float

	local mode: Mode = if startFloating then "floating" else "flying"
	local elapsed, modeTime, sinceRipple = 0, 0, 0
	local ripples = true
	local sink = Instance.new("NumberValue")
	local current = if startFloating then target else from
	local line: Beam? = nil
	local tipAttachment: Attachment? = nil
	local start: Attachment? = nil -- inicio del sedal: en la punta, con el eje hacia abajo
	local distance = (target - from).Magnitude
	local flightSeconds = math.clamp(0.35 + distance / 80, 0.45, 0.85)
	local pending: Mode? = nil -- modo pedido mientras vuela: se aplica al caer
	local arc = math.clamp(distance * 0.22, 3, EFFECTS.CastArcHeight + 2)

	local function land()
		trail.Enabled = false
		mode = pending or "floating"
		modeTime = 0
		Fx.splash(target, 0.6)
		Sounds.play("Plop", target)
	end

	local connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		modeTime += dt
		if mode == "flying" then
			local t = math.min(modeTime / flightSeconds, 1)
			local ahead = 1 - (1 - t) ^ 2 -- sale rápido y frena al caer
			current = from:Lerp(target, ahead) + Vector3.new(0, arc * 4 * t * (1 - t), 0)
			if t >= 1 then
				land()
			end
		else
			local y = math.sin(elapsed * math.pi) * EFFECTS.BobAmplitude - sink.Value
			if mode == "nibble" then
				y -= math.abs(math.sin(modeTime * 11)) * EFFECTS.NibbleDepth
			end
			current = target + Vector3.new(0, y, 0)
			sinceRipple += dt
			local interval = if mode == "nibble" then 0.35 else EFFECTS.RippleSeconds
			if sinceRipple >= interval and mode ~= "sinking" and ripples then
				sinceRipple = 0
				Fx.ring(target, if mode == "nibble" then 1.6 else 1.1, 1.1)
			end
		end
		float.CFrame = CFrame.new(current)
		top.CFrame = CFrame.new(current + Vector3.new(0, EFFECTS.BobberSize * 0.4, 0))
		local beam, tip, origin = line, tipAttachment, start
		if beam and tip and origin and tip.Parent then
			origin.WorldCFrame = CFrame.fromMatrix(tip.WorldPosition, -Vector3.yAxis, outward)
			local span = (current - tip.WorldPosition).Magnitude
			local slack = if mode == "flying" then 0 elseif mode == "nibble" then 0.3 else 1
			-- Cuelga desde la punta, pero nunca por debajo del agua.
			local height = math.max(0, tip.WorldPosition.Y - current.Y)
			beam.CurveSize0 = math.min(span * 0.15, height * 0.6) * slack
			beam.CurveSize1 = span * 0.3 * slack
		end
	end)

	return {
		attachment = attachment,
		setMode = function(newMode: Mode)
			if mode == "flying" and newMode ~= "sinking" then
				pending = newMode -- todavía en el aire: el modo nuevo llega al caer
				return
			end
			mode = newMode
			modeTime = 0
			local requested: string = newMode
			if requested == "nibble" then
				Fx.splash(target, 0.5)
			elseif requested == "sinking" then
				local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				TweenService:Create(sink, info, { Value = 2.5 }):Play()
				TweenService:Create(float, info, { Transparency = 1 }):Play()
				TweenService:Create(top, info, { Transparency = 1 }):Play()
			end
		end,
		setRipples = function(on: boolean)
			ripples = on
		end,
		setLine = function(beam: Beam, tip: Attachment)
			local origin = Instance.new("Attachment")
			origin.Name = "InicioSedal"
			origin.Parent = Workspace.Terrain
			beam.Attachment0 = origin
			line, tipAttachment, start = beam, tip, origin
		end,
		position = function(): Vector3
			return current
		end,
		destroy = function()
			connection:Disconnect()
			sink:Destroy()
			folder:Destroy()
			if start then
				start:Destroy()
			end
		end,
	}
end

return Bobber
