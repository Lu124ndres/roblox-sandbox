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
		pose       gira un hueso que no sigue al cuerpo (la capa), en el
		           espacio del personaje
		surface    la SurfaceAppearance del traje, para hacer latir su brillo
	El modo de efectos reducidos se respeta con `emitter` y `rate` (FxQuality).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trajes = require(ReplicatedStorage.Shared.Trajes)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

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
	-- Rotación de reposo de cada hueso en el espacio del personaje (para pose).
	local rests: { [string]: CFrame } = {}
	for name, bone in bones do
		rests[name] = frame.Rotation:Inverse() * bone.WorldCFrame.Rotation
	end
	return {
		mesh = mesh,
		bones = bones,
		height = height,
		surface = mesh:FindFirstChildWhichIsA("SurfaceAppearance"),
		rate = FxQuality.rateScale,
		emitter = emitter,
		pose = function(name: string, turn: CFrame)
			local bone, rest = bones[name], rests[name]
			if bone and rest then
				bone.Transform = rest:Inverse() * turn * rest
			end
		end,
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
