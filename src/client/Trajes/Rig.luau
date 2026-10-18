--!strict
--[[
	Trajes/Rig

	Mueve los huesos de un traje de malla (Shared.Trajes). Con personaje,
	cada hueso gira lo mismo que la parte del cuerpo escondida que sigue
	(respecto de su parte padre), así el traje hace las animaciones de
	Roblox, la pose de la caña y los emotes; la Cadera también sube y baja
	con el cuerpo. Encima se suma el estilo del traje (amplitud de brazos y
	piernas, giros extra). En una vitrina, sin personaje, solo el estilo.

	Cuenta: si el hueso en reposo tiene rotación R (en el espacio del
	personaje) y la parte gira D respecto de su padre, Transform = R⁻¹·D·R.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trajes = require(ReplicatedStorage.Shared.Trajes)
local Cuerpo = require(ReplicatedStorage.Shared.Trajes.Cuerpo)
local Efectos = require(script.Parent.Efectos)

type Link = {
	bone: Bone,
	name: string,
	part: BasePart?,
	parentPart: BasePart?,
	rest: CFrame, -- rotación del hueso en reposo, en el espacio del personaje
	restInv: CFrame,
	scale: number,
}
export type Rig = {
	style: Trajes.Style,
	mesh: MeshPart,
	root: BasePart?,
	rest: Cuerpo.Rest?,
	links: { Link },
	height: number,
	extras: { Instance }, -- puntos de efectos creados (se borran al soltar)
	tick: Trajes.Tick?, -- lo que el estilo hace cada cuadro (capa, brillo, pisadas)
}

local Rig = {}

-- character = nil para una vitrina.
function Rig.bind(
	mesh: MeshPart,
	key: string,
	character: Model?,
	emitter: (ParticleEmitter) -> ()
): Rig?
	local bones = Trajes.bones(mesh)
	if not bones.Raiz then
		return nil
	end
	local frame, _, height = Trajes.measure(mesh)
	local style = Trajes.style(key)
	local root: BasePart? = nil
	local rest: Cuerpo.Rest? = nil
	local space: CFrame -- de la malla al espacio del personaje
	if character then
		local found = character:FindFirstChild("HumanoidRootPart")
		local weld = mesh:FindFirstChild(Trajes.WELD)
		rest = Cuerpo.rest(character)
		if
			not found
			or not found:IsA("BasePart")
			or not weld
			or not weld:IsA("Weld")
			or not rest
		then
			return nil
		end
		root = found
		space = weld.C0 * weld.C1:Inverse()
	else
		space = frame:ToObjectSpace(mesh.CFrame)
	end
	local rig: Rig = {
		style = style,
		mesh = mesh,
		root = root,
		rest = rest,
		links = {},
		height = height,
		extras = {},
	}
	local partOf: { [string]: BasePart? } = {}
	for _, info in Trajes.Bones do
		local bone = bones[info.name]
		local parentPart = if info.parent then partOf[info.parent] else nil
		local part = if character then Cuerpo.find(character, info.parts) or parentPart else nil
		partOf[info.name] = part
		if bone then
			local restCFrame = (space * mesh.CFrame:ToObjectSpace(bone.WorldCFrame)).Rotation
			local scale = if info.limb == "arms"
				then style.arms
				elseif info.limb == "legs" then style.legs
				else 1
			table.insert(rig.links, {
				bone = bone,
				name = info.name,
				part = part,
				parentPart = parentPart,
				rest = restCFrame,
				restInv = restCFrame:Inverse(),
				scale = scale,
			})
		end
	end
	local ok, err = pcall(function()
		rig.tick = style.effects(Efectos.make(mesh, bones, frame, height, rig.extras, emitter))
	end)
	if not ok then
		warn(`Trajes: efectos de {key}: {err}`)
	end
	return rig
end

function Rig.step(rig: Rig, ctx: Trajes.Context)
	local pose = rig.style.pose(ctx)
	local root, rest = rig.root, rig.rest
	local rootInv = if root then root.CFrame:Inverse() else CFrame.identity
	local deltas: { [BasePart]: CFrame } = {}
	local function delta(part: BasePart): CFrame
		local known = deltas[part]
		if known then
			return known
		end
		local restCFrame = rest and rest[part]
		local value = if part == root or not restCFrame
			then CFrame.identity
			else (rootInv * part.CFrame).Rotation * restCFrame.Rotation:Inverse()
		deltas[part] = value
		return value
	end
	for _, link in rig.links do
		local d = CFrame.identity
		local part, parentPart = link.part, link.parentPart
		if part and parentPart and part ~= parentPart then
			d = delta(parentPart):Inverse() * delta(part)
			if link.scale ~= 1 and ctx.speed > 2 then -- solo el vaivén al caminar (no la caña)
				local axis, angle = d:ToAxisAngle()
				if math.abs(angle) > 1e-4 then
					d = CFrame.fromAxisAngle(axis, angle * link.scale)
				end
			end
		end
		local extra = pose[link.name]
		if extra then
			d *= extra
		end
		local transform = link.restInv * d * link.rest
		if link.name == "Cadera" and part and rest and rest[part] then -- sube y baja con el cuerpo
			local offset = (rootInv * part.CFrame).Position - rest[part].Position
			transform = CFrame.new(link.restInv:VectorToWorldSpace(offset)) * transform
		end
		link.bone.Transform = transform
	end
	if rig.tick then
		rig.tick(ctx)
	end
end

function Rig.unbind(rig: Rig)
	for _, extra in rig.extras do
		extra:Destroy()
	end
	table.clear(rig.extras)
	rig.tick = nil
	for _, bone in Trajes.bones(rig.mesh) do -- también los que mueve el estilo (la capa)
		bone.Transform = CFrame.identity
	end
end

return table.freeze(Rig)
