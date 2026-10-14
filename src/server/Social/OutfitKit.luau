--!strict
--[[
	OutfitKit

	Herramientas para vestir al personaje con piezas (Uniforms y sus partes):
		rig      encuentra las partes del cuerpo (R15 o R6), izquierda primero
		piece    pieza soldada a una parte del cuerpo: no choca, no pesa, los
		         rayos la ignoran
		ball / cylinder  atajos de forma (el cilindro va de pie: su alto es Y)
	En las partes del cuerpo -Z es el frente y +Z la espalda.
]]

export type Rig = {
	r15: boolean,
	head: BasePart,
	torso: BasePart, -- UpperTorso (R15) o Torso (R6)
	hips: BasePart?, -- LowerTorso (solo R15)
	upperArms: { BasePart }, -- en R6, el brazo entero
	lowerArms: { BasePart },
	hands: { BasePart },
	upperLegs: { BasePart }, -- en R6, la pierna entera
	lowerLegs: { BasePart },
	feet: { BasePart },
}

local OutfitKit = {}

OutfitKit.rgb = Color3.fromRGB
OutfitKit.M = Enum.Material

-- Del lado izquierdo (-1) o derecho (1), según el orden de las listas del Rig.
function OutfitKit.side(index: number): number
	return if index == 1 then -1 else 1
end

function OutfitKit.rig(character: Model): Rig?
	local function part(name: string): BasePart?
		local found = character:FindFirstChild(name)
		return if found and found:IsA("BasePart") then found else nil
	end
	local function pair(left: string, right: string): { BasePart }
		local list = {}
		for _, name in { left, right } do
			local found = part(name)
			if found then
				table.insert(list, found)
			end
		end
		return list
	end
	local head = part("Head")
	local upper = part("UpperTorso")
	local torso = upper or part("Torso")
	if not head or not torso then
		return nil
	end
	if upper then
		return {
			r15 = true,
			head = head,
			torso = torso,
			hips = part("LowerTorso"),
			upperArms = pair("LeftUpperArm", "RightUpperArm"),
			lowerArms = pair("LeftLowerArm", "RightLowerArm"),
			hands = pair("LeftHand", "RightHand"),
			upperLegs = pair("LeftUpperLeg", "RightUpperLeg"),
			lowerLegs = pair("LeftLowerLeg", "RightLowerLeg"),
			feet = pair("LeftFoot", "RightFoot"),
		}
	end
	return {
		r15 = false,
		head = head,
		torso = torso,
		hips = nil,
		upperArms = pair("Left Arm", "Right Arm"),
		lowerArms = {},
		hands = {},
		upperLegs = pair("Left Leg", "Right Leg"),
		lowerLegs = {},
		feet = {},
	}
end

-- Pieza en `anchor * offset`, soldada a `anchor`.
function OutfitKit.piece(
	parent: Instance,
	name: string,
	anchor: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = anchor.CFrame * offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.Massless = true
	part.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	part.Parent = parent
	return part
end

function OutfitKit.ball(
	parent: Instance,
	name: string,
	anchor: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = OutfitKit.piece(parent, name, anchor, size, offset, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Cilindro de pie: `height` en Y, `diameter` de ancho.
function OutfitKit.cylinder(
	parent: Instance,
	name: string,
	anchor: BasePart,
	height: number,
	diameter: number,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = OutfitKit.piece(
		parent,
		name,
		anchor,
		Vector3.new(height, diameter, diameter),
		offset * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Funda un poco más grande que la parte del cuerpo (mangas, pantalón, botas).
-- `from`..`to`: qué tramo cubre, de 0 (abajo) a 1 (arriba).
function OutfitKit.sleeve(
	parent: Instance,
	name: string,
	limb: BasePart,
	from: number,
	to: number,
	grow: number,
	color: Color3,
	material: Enum.Material?
): Part
	local height = limb.Size.Y * (to - from) + 0.02
	local middle = -limb.Size.Y / 2 + limb.Size.Y * (from + to) / 2
	return OutfitKit.piece(
		parent,
		name,
		limb,
		Vector3.new(limb.Size.X + grow, height, limb.Size.Z + grow),
		CFrame.new(0, middle, 0),
		color,
		material
	)
end

return OutfitKit
