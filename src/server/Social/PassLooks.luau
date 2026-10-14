--!strict
--[[
	PassLooks

	La apariencia completa de los pases con traje (además de la corona y la
	capa de OutfitParts), para que resalten entre los marineros:
		ReyDelMar      almirante de los mares: casaca azul con doble fila de
		               botones de oro, charreteras con flecos, banda turquesa,
		               pantalón blanco y botas altas, barba blanca de Poseidón,
		               tridente dorado a la espalda y burbujas
		DiosDelVolcan  ver VolcanoLook
	Los colores del cuerpo los pone Uniforms (BodyColors).
]]

local OutfitKit = require(script.Parent.OutfitKit)
local GearParts = require(script.Parent.GearParts)
local VolcanoLook = require(script.Parent.VolcanoLook)

local rgb, M = OutfitKit.rgb, OutfitKit.M
local piece, ball, cylinder, sleeve =
	OutfitKit.piece, OutfitKit.ball, OutfitKit.cylinder, OutfitKit.sleeve

local GOLD = rgb(255, 200, 70)
local COAT = rgb(24, 48, 120)
local TEAL = rgb(40, 200, 200)

local PassLooks = {}

local function king(model: Model, rig: OutfitKit.Rig)
	local s = rig.torso.Size
	for index, arm in rig.upperArms do
		sleeve(model, `Casaca{index}`, arm, if rig.r15 then 0 else 0.22, 1, 0.08, COAT, M.Fabric)
		-- Charretera: disco dorado con flecos.
		local top = CFrame.new(0, arm.Size.Y / 2 + 0.04, 0)
		cylinder(model, "Charretera", arm, 0.12, arm.Size.X * 1.45, top, GOLD, M.Metal)
		for fringe = 1, 5 do
			local angle = math.rad(-60 + (fringe - 1) * 30)
			local side = OutfitKit.side(index)
			local at = top
				* CFrame.new(
					side * math.cos(angle) * arm.Size.X * 0.66,
					-0.14,
					math.sin(angle) * arm.Size.Z * 0.66
				)
			piece(model, "Fleco", arm, Vector3.new(0.06, 0.26, 0.06), at, GOLD, M.Metal)
		end
	end
	local forearms: { BasePart } = if rig.r15 then rig.lowerArms else rig.upperArms
	for index, arm in forearms do
		local bottom = if rig.r15 then 0.12 else 0.22
		if rig.r15 then
			sleeve(model, `CasacaAntebrazo{index}`, arm, bottom, 1, 0.08, COAT, M.Fabric)
		end
		sleeve(model, `PunoOro{index}`, arm, bottom, bottom + 0.12, 0.12, GOLD, M.Metal)
	end
	for row = 0, 2 do -- doble fila de botones
		for _, x in { -1, 1 } do
			ball(
				model,
				"Boton",
				rig.torso,
				Vector3.one * 0.16,
				CFrame.new(x * s.X * 0.18, s.Y * (0.25 - row * 0.22), -s.Z / 2 - 0.04),
				GOLD,
				M.Metal
			)
		end
	end
	local sash = CFrame.new(0, 0, -s.Z / 2 - 0.03) * CFrame.Angles(0, 0, math.rad(38))
	piece(model, "Banda", rig.torso, Vector3.new(0.3, s.Y * 1.2, 0.05), sash, TEAL, M.Fabric)
	if rig.hips then
		sleeve(model, "Faldon", rig.hips, 0.1, 1, 0.08, COAT, M.Fabric)
	end
	GearParts.belt(model, rig, rgb(245, 245, 240))
	GearParts.shoes(model, rig, rgb(18, 18, 22), true)
	-- Barba y bigote blancos.
	local head = rig.head
	local h = head.Size
	piece(
		model,
		"Barba",
		head,
		Vector3.new(h.X * 0.72, h.Y * 0.5, 0.3),
		CFrame.new(0, -h.Y * 0.36, -h.Z / 2 - 0.02),
		rgb(236, 236, 240),
		M.Fabric
	)
	piece(
		model,
		"Bigote",
		head,
		Vector3.new(h.X * 0.5, 0.1, 0.12),
		CFrame.new(0, -h.Y * 0.1, -h.Z / 2 - 0.05),
		rgb(236, 236, 240),
		M.Fabric
	)
	-- Tridente a la espalda.
	local back = CFrame.new(0, 0, s.Z / 2 + 0.25) * CFrame.Angles(0, 0, math.rad(25))
	piece(model, "TridenteAsta", rig.torso, Vector3.new(0.14, 4.4, 0.14), back, GOLD, M.Metal)
	local head3 = back * CFrame.new(0, 2.2, 0)
	piece(model, "TridenteCruz", rig.torso, Vector3.new(1.1, 0.14, 0.14), head3, GOLD, M.Metal)
	for prong = -1, 1 do
		local tall = if prong == 0 then 0.8 else 0.6
		piece(
			model,
			"TridentePunta",
			rig.torso,
			Vector3.new(0.12, tall, 0.12),
			head3 * CFrame.new(prong * 0.48, tall / 2, 0),
			GOLD,
			M.Metal
		)
	end
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(rgb(170, 235, 255))
	bubbles.LightEmission = 0.4
	bubbles.Transparency = NumberSequence.new(0.3, 1)
	bubbles.Size = NumberSequence.new(0.15, 0.3)
	bubbles.Rate = 5
	bubbles.Lifetime = NumberRange.new(1.2, 2)
	bubbles.Speed = NumberRange.new(1.5, 3)
	bubbles.SpreadAngle = Vector2.new(30, 30)
	bubbles.Parent = model:FindFirstChild("Banda")
end

function PassLooks.build(outfit: string, model: Model, rig: OutfitKit.Rig)
	if outfit == "ReyDelMar" then
		king(model, rig)
	elseif outfit == "DiosDelVolcan" then
		VolcanoLook.build(model, rig)
	end
end

return PassLooks
