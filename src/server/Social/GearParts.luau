--!strict
--[[
	GearParts

	Cinturón con hebilla dorada y zapatos (o botas altas) para los trajes:
	el marinero, el Rey del Mar y el Dios del Volcán.
]]

local OutfitKit = require(script.Parent.OutfitKit)

local rgb, M = OutfitKit.rgb, OutfitKit.M
local piece, sleeve = OutfitKit.piece, OutfitKit.sleeve

local GOLD = rgb(255, 200, 70)

local GearParts = {}

function GearParts.belt(model: Model, rig: OutfitKit.Rig, color: Color3)
	local anchor = rig.hips or rig.torso
	local y = if rig.hips then anchor.Size.Y / 2 - 0.08 else -anchor.Size.Y / 2 + 0.1
	local s = anchor.Size
	piece(
		model,
		"Cinturon",
		anchor,
		Vector3.new(s.X + 0.06, 0.2, s.Z + 0.06),
		CFrame.new(0, y, 0),
		color
	)
	piece(
		model,
		"Hebilla",
		anchor,
		Vector3.new(0.34, 0.24, 0.06),
		CFrame.new(0, y, -s.Z / 2 - 0.04),
		GOLD,
		M.Metal
	)
end

function GearParts.shoes(model: Model, rig: OutfitKit.Rig, color: Color3, tall: boolean?)
	if rig.r15 then
		for _, foot in rig.feet do
			piece(
				model,
				"Zapato",
				foot,
				foot.Size + Vector3.new(0.08, 0.06, 0.12),
				CFrame.new(0, 0.02, -0.04),
				color,
				M.SmoothPlastic
			).Reflectance =
				0.08
		end
		if tall then
			for index, leg in rig.lowerLegs do
				sleeve(model, `Bota{index}`, leg, 0, 0.8, 0.1, color, M.SmoothPlastic)
			end
		end
	else
		for index, leg in rig.upperLegs do
			sleeve(
				model,
				`Zapato{index}`,
				leg,
				0,
				if tall then 0.45 else 0.16,
				0.1,
				color,
				M.SmoothPlastic
			)
		end
	end
end

return GearParts
