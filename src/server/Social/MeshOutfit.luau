--!strict
--[[
	MeshOutfit

	Viste a un personaje con un traje de malla (Shared.Trajes): copia
	ServerStorage.Traje<clave>, lo escala para que su cadera quede a la
	altura de la del cuerpo y lo suelda al HumanoidRootPart con los pies en
	el piso. El cuerpo queda invisible (sigue ahí: anima, choca y sostiene
	la caña); los clientes mueven los huesos del traje copiándolo.
	Si el traje no está en ServerStorage devuelve nil (Outfits usa las piezas).
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trajes = require(ReplicatedStorage.Shared.Trajes)
local Cuerpo = require(ReplicatedStorage.Shared.Trajes.Cuerpo)

local HEAD_TOP = 1.2 -- studs de la cabeza sobre el cuello en el cuerpo R15

local MeshOutfit = {}

function MeshOutfit.available(key: string): boolean
	local template = ServerStorage:FindFirstChild(Trajes.templateName(key))
	return template ~= nil and Trajes.mesh(template) ~= nil
end

-- Esconde el cuerpo (las partes y la cara); el traje y las herramientas se ven.
local function hideBody(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") then
			child.Transparency = 1
			for _, decal in child:GetChildren() do
				if decal:IsA("Decal") then
					decal.Transparency = 1
				end
			end
		end
	end
end

function MeshOutfit.build(character: Model, key: string): Model?
	local template = ServerStorage:FindFirstChild(Trajes.templateName(key))
	local root = character:FindFirstChild("HumanoidRootPart")
	local rest = Cuerpo.rest(character)
	if not template or not root or not root:IsA("BasePart") or not rest then
		return nil
	end
	local floor, hip = Cuerpo.legs(character, rest)
	if not floor or not hip then
		return nil
	end
	local costume = template:Clone()
	local mesh = Trajes.mesh(costume)
	if not mesh or not costume:IsA("Model") then
		costume:Destroy()
		return nil
	end
	local _, costumeHip = Trajes.measure(mesh)
	costume:ScaleTo(costume:GetScale() * (hip - floor) / costumeHip)
	local frame, _, height = Trajes.measure(mesh)
	for _, part in costume:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			part.CastShadow = true
			if part ~= mesh then
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = mesh, part
				weld.Parent = part
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = Trajes.WELD
	weld.Part0 = root
	weld.Part1 = mesh
	weld.C0 = CFrame.new(0, floor, 0) * frame:ToObjectSpace(mesh.CFrame)
	weld.Parent = mesh
	costume.Name = Trajes.FOLDER
	costume:SetAttribute("Outfit", key)
	costume.Parent = character
	hideBody(character)
	-- Cuánto más alto que el cuerpo queda el traje (para subir el cartel de la cabeza).
	local head = character:FindFirstChild("Head")
	local headTop = if head
			and head:IsA("BasePart")
			and rest[head]
		then rest[head].Position.Y + head.Size.Y / 2
		else floor + 5 + HEAD_TOP
	character:SetAttribute(Trajes.EXTRA_HEIGHT, math.max(0, floor + height - headTop))
	return costume
end

return table.freeze(MeshOutfit)
