--!strict
--[[
	Trajes/Efectos

	Lo que un estilo (Shared.Trajes.Estilos) puede pedir para sus efectos, todo
	local al cliente y borrado al soltar el traje:
		socket     un hueso hijo pegado a un hueso, corrido `offset` (en altos del
		           traje, ejes del personaje): para partículas y luces
		aura       una pieza invisible del tamaño del cuerpo (cilindro de pie),
		           soldada al traje: sus emisores salen de toda la superficie
		highlight  contorno brillante del traje
	El modo de efectos reducidos se respeta con `emitter` (FxQuality).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trajes = require(ReplicatedStorage.Shared.Trajes)

local Efectos = {}

function Efectos.make(
	mesh: MeshPart,
	bones: { [string]: Bone },
	frame: CFrame,
	height: number,
	extras: { Instance },
	emitter: (ParticleEmitter) -> ()
): Trajes.Fx
	local function keep<T>(instance: T & Instance): T
		table.insert(extras, instance)
		return instance
	end
	return {
		bones = bones,
		height = height,
		emitter = emitter,
		socket = function(name: string, offset: Vector3): Bone?
			local bone = bones[name]
			if not bone then
				return nil
			end
			local target = bone.WorldPosition + frame:VectorToWorldSpace(offset * height)
			local socket = Instance.new("Bone")
			socket.Name = "Efecto"
			socket.CFrame = bone.WorldCFrame:ToObjectSpace(CFrame.new(target) * frame.Rotation)
			socket.Parent = bone
			return keep(socket)
		end,
		aura = function(size: Vector3, lift: number): BasePart
			local part = Instance.new("Part")
			part.Name = "Aura"
			part.Transparency = 1
			part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
			part.Massless = true
			part.CastShadow = false
			part.Size = size * height
			part.CFrame = frame * CFrame.new(0, lift * height, 0)
			if mesh.Anchored then
				part.Anchored = true
			else
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = mesh, part
				weld.Parent = part
			end
			part.Parent = mesh.Parent
			return keep(part)
		end,
		highlight = function(fill: Color3, outline: Color3, fillTransparency: number)
			local glow = Instance.new("Highlight")
			glow.FillColor = fill
			glow.OutlineColor = outline
			glow.FillTransparency = fillTransparency
			glow.OutlineTransparency = 0.15
			glow.DepthMode = Enum.HighlightDepthMode.Occluded
			glow.Adornee = mesh
			glow.Parent = mesh
			keep(glow)
		end,
	}
end

return table.freeze(Efectos)
