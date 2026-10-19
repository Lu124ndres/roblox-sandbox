--!strict
--[[
	RodOrnaments

	Adornos de cada estilo de caña (ver UIConfig.RodLooks). tipZ es dónde
	termina la caña (negativo) y point la puntera, para pegarle partículas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local RodParts = require(script.Parent.RodParts)

local RodOrnaments = {}

local BLANK_START = -0.9 -- donde empieza el primer tramo

-- Grosor aproximado de la vara en z (se afina de 0.2 a 0.09).
local function thickness(z: number, tipZ: number): number
	local t = math.clamp((z - BLANK_START) / (tipZ - BLANK_START), 0, 1)
	return 0.2 - 0.11 * t
end

local function along(tipZ: number, every: number, make: (z: number, d: number, index: number) -> ())
	local index, z = 1, BLANK_START - every / 2
	while z > tipZ + 0.3 do
		make(z, thickness(z, tipZ), index)
		z -= every
		index += 1
	end
end

-- Vetas o grietas: tiras finas a lo largo de la vara, a los lados.
local function veins(model: Model, tipZ: number, color: Color3)
	for side = -1, 1, 2 do
		local length = BLANK_START - tipZ - 0.4
		RodParts.piece(
			model,
			`Veta{side}`,
			Vector3.new(0.03, 0.03, length),
			CFrame.new(side * 0.06, 0.04, BLANK_START - length / 2),
			color,
			Enum.Material.Neon
		)
	end
end

function RodOrnaments.add(model: Model, look: UIConfig.RodLook, tipZ: number, point: Part)
	local style = look.style
	local darker = look.blank:Lerp(Color3.new(0, 0, 0), 0.3)
	if style == "bambu" then
		along(tipZ, 0.9, function(z, d, i)
			RodParts.ring(model, `Nudo{i}`, z, d + 0.06, darker, Enum.Material.Wood)
		end)
	elseif style == "madera" or style == "fibra" then
		local wraps = if style == "fibra"
			then { look.accent, Color3.fromRGB(80, 170, 255) }
			else { look.accent }
		along(tipZ, 1.6, function(z, d, i)
			RodParts.ring(model, `Hilo{i}`, z, d + 0.04, wraps[(i - 1) % #wraps + 1])
		end)
	elseif style == "coral" then
		for k = 1, 3 do
			local branch = RodParts.shaft(model, `Rama{k}`, 0.5, 0.07, 0, look.blank)
			branch.CFrame = CFrame.new(0, 0.12, -1.3 - k * 0.5)
				* CFrame.Angles(math.rad(50), math.rad(k * 120), 0)
				* CFrame.Angles(0, math.rad(90), 0)
		end
		RodParts.ball(
			model,
			"Perla",
			Vector3.new(0, 0.28, -1.0),
			0.22,
			Color3.fromRGB(250, 245, 255),
			Enum.Material.SmoothPlastic
		).Reflectance =
			0.3
	elseif style == "acero" then
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and string.find(child.Name, "Tramo") then
				child.Reflectance = 0.3
			end
		end
	elseif style == "dorada" then
		local gems = {
			Color3.fromRGB(255, 60, 80),
			Color3.fromRGB(60, 160, 255),
			Color3.fromRGB(80, 230, 120),
		}
		for k, gem in gems do
			RodParts.ball(
				model,
				`Gema{k}`,
				Vector3.new(0, 0.2, 0.6 - k * 0.35),
				0.14,
				gem,
				Enum.Material.Neon
			)
		end
	elseif style == "cristal" then
		RodParts.shaft(
			model,
			"Nucleo",
			BLANK_START - tipZ - 0.3,
			0.05,
			BLANK_START,
			look.accent,
			Enum.Material.Neon
		)
		RodParts.particles(point, Assets.Particles.Sparkle, look.blank, 6, 2, 0.35)
	elseif style == "abismo" then
		veins(model, tipZ, look.accent)
		RodParts.particles(point, Assets.Particles.Mist, look.accent, 8, 1.5, 0.5)
	elseif style == "volcanica" then
		veins(model, tipZ, look.accent)
		RodParts.particles(point, Assets.Particles.Spark, look.accent, 14, 4, 0.25)
	elseif style == "leviatan" then
		along(tipZ, 0.8, function(z, d, i)
			local fin = RodParts.piece(
				model,
				`Aleta{i}`,
				Vector3.new(0.03, 0.18 + d, 0.35),
				CFrame.new(0, d / 2 + 0.08, z),
				look.accent,
				Enum.Material.Neon
			)
			fin.Transparency = 0.2
		end)
		RodParts.particles(point, Assets.Particles.Mist, Color3.fromRGB(220, 255, 255), 6, 2, 0.3)
	end
end

return RodOrnaments
