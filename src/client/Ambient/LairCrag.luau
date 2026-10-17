--!strict
--[[
	LairCrag

	Piezas de roca volcánica natural para las rocas de la guarida (LairRocks):
	bloques torcidos de basalto y pizarra, algunos de obsidiana lisa,
	más rojizos cuanto más cerca de la lava (heat 0 = arriba, 1 = en la lava), y
	cuñas para los taludes del pie. Todas chocan: se pueden pisar.
		block(parent, rng, size, cframe, heat)   un bloque de roca
		wedge(parent, rng, size, cframe, heat)   un talud: la pendiente baja hacia LookVector
		facing(rng, at, out, lean)               en `at`, mirando hacia `out` con algo de azar;
		                                         lean > 0: la cara de afuera se recuesta hacia atrás
		under(cframe, size, ceiling)             la misma pieza, bajada hasta que su esquina
		                                         más alta quede en `ceiling` (nada sobresale de la cima)
]]

local LairParts = require(script.Parent.LairParts)

local rgb = Color3.fromRGB

local SHADES = { rgb(26, 23, 28), rgb(36, 32, 38), rgb(47, 42, 47), rgb(20, 18, 23) }
local HOT = rgb(62, 30, 24) -- la roca recalentada junto a la lava
local MATERIALS = {
	Enum.Material.Basalt,
	Enum.Material.Basalt,
	Enum.Material.Slate,
}
local SHINY = 0.1 -- parte de los bloques que son obsidiana brillosa (heat > 0: no en la cima)

local LairCrag = {}

local function look(rng: Random, heat: number): (Color3, Enum.Material, number)
	if heat > 0 and rng:NextNumber() < SHINY then
		-- Lisa y sin reflejo: el vidrio de Roblox refleja el cielo y la vuelve azul.
		return LairParts.OBSIDIAN, Enum.Material.SmoothPlastic, 0
	end
	local shade = SHADES[rng:NextInteger(1, #SHADES)]
	return shade:Lerp(HOT, heat * 0.4), MATERIALS[rng:NextInteger(1, #MATERIALS)], 0
end

function LairCrag.block(
	parent: Instance,
	rng: Random,
	size: Vector3,
	cframe: CFrame,
	heat: number
): BasePart
	local color, material, reflectance = look(rng, heat)
	return LairParts.part(parent, size, cframe, color, {
		material = material,
		reflectance = reflectance,
		collide = true,
	})
end

function LairCrag.wedge(
	parent: Instance,
	rng: Random,
	size: Vector3,
	cframe: CFrame,
	heat: number
): BasePart
	local color, material = look(rng, heat)
	local wedge = Instance.new("WedgePart")
	wedge.Size, wedge.CFrame, wedge.Color, wedge.Material = size, cframe, color, material
	wedge.Anchored, wedge.CanCollide = true, true
	wedge.CanQuery, wedge.CanTouch = false, false
	wedge.Parent = parent
	return wedge
end

function LairCrag.facing(rng: Random, at: Vector3, out: Vector3, lean: number): CFrame
	return CFrame.lookAt(at, at + out)
		* CFrame.Angles(0, rng:NextNumber(-0.35, 0.35), 0)
		* CFrame.Angles(lean, 0, rng:NextNumber(-0.18, 0.18))
end

function LairCrag.under(cframe: CFrame, size: Vector3, ceiling: number): CFrame
	local half = size / 2
	local highest = -math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				highest = math.max(highest, (cframe * (half * Vector3.new(x, y, z))).Y)
			end
		end
	end
	return cframe - Vector3.new(0, highest - ceiling, 0)
end

return table.freeze(LairCrag)
