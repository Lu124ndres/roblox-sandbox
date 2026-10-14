--!strict
--[[
	SailorParts

	Uniforme de marinero para todos (Uniforms): gorro blanco con el ala
	enrollada y cinta azul, cuello marinero azul con dos rayas blancas
	(atrás el cuadro, adelante en V), pañoleta roja anudada, camisa blanca
	con puños azules a rayas, cinturón con hebilla dorada, pantalón azul
	acampanado y zapatos negros brillantes (GearParts). Cada pieza sale de
	OutfitKit.
]]

local GearParts = require(script.Parent.GearParts)
local OutfitKit = require(script.Parent.OutfitKit)

local rgb, M = OutfitKit.rgb, OutfitKit.M
local piece, cylinder, sleeve = OutfitKit.piece, OutfitKit.cylinder, OutfitKit.sleeve

local WHITE = rgb(246, 246, 240)
local NAVY = rgb(28, 44, 96)
local RED = rgb(214, 40, 48)
local BLACK = rgb(20, 20, 24)

local SailorParts = {}

SailorParts.WHITE, SailorParts.NAVY = WHITE, NAVY

local function hat(model: Model, head: BasePart)
	local width = head.Size.X
	local top = CFrame.new(0, head.Size.Y / 2 + 0.05, 0.06) * CFrame.Angles(math.rad(-10), 0, 0)
	cylinder(model, "Gorro", head, 0.42, width * 0.86, top * CFrame.new(0, 0.2, 0), WHITE, M.Fabric)
	cylinder(
		model,
		"GorroCinta",
		head,
		0.1,
		width * 0.9,
		top * CFrame.new(0, 0.06, 0),
		NAVY,
		M.Fabric
	)
	cylinder(
		model,
		"GorroAla",
		head,
		0.16,
		width * 1.08,
		top * CFrame.new(0, -0.02, 0),
		WHITE,
		M.Fabric
	)
	cylinder(
		model,
		"GorroTapa",
		head,
		0.06,
		width * 0.7,
		top * CFrame.new(0, 0.42, 0),
		WHITE,
		M.Fabric
	)
end

local function collar(model: Model, torso: BasePart)
	local s = torso.Size
	local height = s.Y * 0.42
	local back = CFrame.new(0, s.Y / 2 - height / 2 + 0.02, s.Z / 2 + 0.03)
	piece(model, "Cuello", torso, Vector3.new(s.X * 0.84, height, 0.05), back, NAVY, M.Fabric)
	for _, x in { -1, 1 } do
		piece(
			model,
			"CuelloRaya",
			torso,
			Vector3.new(0.05, height - 0.12, 0.06),
			back * CFrame.new(x * (s.X * 0.42 - 0.12), 0.04, 0),
			WHITE,
			M.Fabric
		)
	end
	piece(
		model,
		"CuelloRayaAbajo",
		torso,
		Vector3.new(s.X * 0.84 - 0.18, 0.05, 0.06),
		back * CFrame.new(0, -height / 2 + 0.1, 0),
		WHITE,
		M.Fabric
	)
	-- Adelante: dos solapas en V que bajan de los hombros al pecho.
	local length = s.Y * 0.56
	for _, x in { -1, 1 } do
		local flap = CFrame.new(x * s.X * 0.17, s.Y / 2 - length * 0.42, -s.Z / 2 - 0.03)
			* CFrame.Angles(0, 0, math.rad(x * 32))
		piece(model, "Solapa", torso, Vector3.new(0.3, length, 0.05), flap, NAVY, M.Fabric)
		piece(
			model,
			"SolapaRaya",
			torso,
			Vector3.new(0.05, length * 0.9, 0.06),
			flap * CFrame.new(x * 0.08, 0, 0),
			WHITE,
			M.Fabric
		)
	end
	-- Pañoleta: nudo y dos puntas.
	local knot = CFrame.new(0, s.Y / 2 - length * 0.8, -s.Z / 2 - 0.08)
	piece(model, "Panoleta", torso, Vector3.new(0.3, 0.22, 0.12), knot, RED, M.Fabric)
	for _, x in { -1, 1 } do
		piece(
			model,
			"PanoletaPunta",
			torso,
			Vector3.new(0.14, 0.42, 0.06),
			knot * CFrame.new(x * 0.06, -0.26, 0) * CFrame.Angles(0, 0, math.rad(x * 14)),
			RED,
			M.Fabric
		)
	end
end

local function sleeves(model: Model, rig: OutfitKit.Rig)
	for index, arm in rig.upperArms do
		local cover = if rig.r15 then 0 else 0.25 -- en R6 la mano queda al aire
		sleeve(model, `Manga{index}`, arm, cover, 1, 0.08, WHITE, M.Fabric)
	end
	local cuffs: { BasePart } = if rig.r15 then rig.lowerArms else rig.upperArms
	for index, arm in cuffs do
		local bottom = if rig.r15 then 0.12 else 0.25
		if rig.r15 then
			sleeve(model, `Antebrazo{index}`, arm, bottom, 1, 0.08, WHITE, M.Fabric)
		end
		sleeve(model, `Puno{index}`, arm, bottom, bottom + 0.22, 0.12, NAVY, M.Fabric)
		sleeve(model, `PunoRaya{index}`, arm, bottom + 0.1, bottom + 0.14, 0.14, WHITE, M.Fabric)
	end
end

local function trousers(model: Model, rig: OutfitKit.Rig)
	if rig.hips then
		sleeve(model, "Cadera", rig.hips, 0, 1, 0.06, NAVY, M.Fabric)
	end
	local flares: { BasePart } = if rig.r15 then rig.lowerLegs else rig.upperLegs
	for index, leg in flares do -- campana del pantalón
		sleeve(
			model,
			`Campana{index}`,
			leg,
			if rig.r15 then 0.05 else 0.16,
			0.32,
			0.2,
			NAVY,
			M.Fabric
		)
	end
end

function SailorParts.build(model: Model, rig: OutfitKit.Rig)
	hat(model, rig.head)
	collar(model, rig.torso)
	sleeves(model, rig)
	trousers(model, rig)
	GearParts.belt(model, rig, NAVY)
	GearParts.shoes(model, rig, BLACK)
end

return SailorParts
