--!strict
--[[
	Bobber

	Corcho de la pesca: vuela en arco desde la punta de la caña, cae con
	salpicadura, flota con vaivén y ondas, mordisquea cuando pica y se hunde
	si el pez se escapa. Efecto local: el servidor no sabe que existe.
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
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, EFFECTS.BobberSize * 0.5, 0)
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
	local sink = Instance.new("NumberValue")
	local current = if startFloating then target else from

	local function land()
		trail.Enabled = false
		mode = "floating"
		modeTime = 0
		Fx.splash(target, 0.6)
		Sounds.play("Plop", target)
	end

	local connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		modeTime += dt
		if mode == "flying" then
			local t = math.min(modeTime / EFFECTS.CastFlightSeconds, 1)
			current = from:Lerp(target, t)
				+ Vector3.new(0, EFFECTS.CastArcHeight * 4 * t * (1 - t), 0)
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
			if sinceRipple >= interval and mode ~= "sinking" then
				sinceRipple = 0
				Fx.ring(target, if mode == "nibble" then 1.6 else 1.1, 1.1)
			end
		end
		float.CFrame = CFrame.new(current)
		top.CFrame = CFrame.new(current + Vector3.new(0, EFFECTS.BobberSize * 0.4, 0))
	end)

	return {
		attachment = attachment,
		setMode = function(newMode: Mode)
			if mode == "flying" and newMode ~= "sinking" then
				return -- todavía en el aire: el modo nuevo llega al caer
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
		position = function(): Vector3
			return current
		end,
		destroy = function()
			connection:Disconnect()
			sink:Destroy()
			folder:Destroy()
		end,
	}
end

return Bobber
