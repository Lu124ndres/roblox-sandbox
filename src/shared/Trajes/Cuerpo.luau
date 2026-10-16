--!strict
--[[
	Trajes/Cuerpo

	La pose de reposo del cuerpo de un personaje (R15 o R6), medida desde
	sus articulaciones sin importar lo que esté animando: cada parte respecto
	del HumanoidRootPart. Sirve con Motor6D y con las articulaciones nuevas
	(AnimationConstraint). También dice dónde está el piso y la cadera.
]]

local Cuerpo = {}

export type Rest = { [BasePart]: CFrame }

function Cuerpo.rest(character: Model): Rest?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local links: { [BasePart]: { parent: BasePart, offset: CFrame } } = {}
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") then
			local part0, part1 = joint.Part0, joint.Part1
			if part0 and part1 then
				links[part1] = { parent = part0, offset = joint.C0 * joint.C1:Inverse() }
			end
		elseif joint:IsA("AnimationConstraint") then
			local a0, a1 = joint.Attachment0, joint.Attachment1
			local part0 = a0 and a0.Parent
			local part1 = a1 and a1.Parent
			if
				a0
				and a1
				and part0
				and part1
				and part0:IsA("BasePart")
				and part1:IsA("BasePart")
			then
				links[part1] = { parent = part0, offset = a0.CFrame * a1.CFrame:Inverse() }
			end
		end
	end
	local rest: Rest = { [root] = CFrame.identity }
	local function resolve(part: BasePart, depth: number): CFrame?
		local known = rest[part]
		if known then
			return known
		end
		local link = links[part]
		if not link or depth > 16 then
			return nil
		end
		local parent = resolve(link.parent, depth + 1)
		if not parent then
			return nil
		end
		local cframe = parent * link.offset
		rest[part] = cframe
		return cframe
	end
	for part in links do
		resolve(part, 0)
	end
	return rest
end

local function find(character: Model, names: { string }): BasePart?
	for _, name in names do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

-- Alto del piso y de la cadera respecto del centro del HumanoidRootPart.
function Cuerpo.legs(character: Model, rest: Rest): (number?, number?)
	local upper = find(character, { "LeftUpperLeg", "Left Leg" })
	local upperRest = upper and rest[upper]
	if not upper or not upperRest then
		return nil, nil
	end
	local floor = math.huge
	for _, name in { "LeftFoot", "LeftLowerLeg", "Left Leg", "RightFoot", "Right Leg" } do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local cframe = rest[part]
			if cframe then
				floor = math.min(floor, cframe.Position.Y - part.Size.Y / 2)
			end
		end
	end
	return floor, upperRest.Position.Y + upper.Size.Y / 2
end

-- Primera parte del cuerpo que existe de la lista.
Cuerpo.find = find

return table.freeze(Cuerpo)
