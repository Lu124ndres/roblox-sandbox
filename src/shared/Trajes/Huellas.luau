--!strict
--[[
	Trajes/Huellas

	Pisadas que deja un traje al caminar, solo en este cliente: cada vez que un
	pie toca el piso (rayo corto hacia abajo desde el tobillo) aparece una
	marca que se apaga sola. Dos clases:
		lava  una huella encendida que se enfría (de naranja a roca) y se borra
		agua  una onda que se abre y se desvanece
	No hay pisadas en las vitrinas, quieto, ni con efectos reducidos al mínimo.
	Hay un tope de marcas vivas por traje.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Tipos = require(script.Parent.Tipos)

export type Spec = {
	kind: "lava" | "agua",
	color: Color3, -- al aparecer
	fade: Color3, -- al terminar (lava: roca fría)
	size: Vector3, -- en altos del traje (ancho, alto, largo)
	life: number, -- segundos
}

local FEET = { "PieIzq", "PieDer" }
local REACH = 0.075 -- altos: el tobillo está a ~0.05 del piso con el pie apoyado
local MIN_SPEED = 3
local MAX_ALIVE = 10

local Huellas = {}

local function mark(spec: Spec, at: CFrame, h: number): BasePart
	local part = Instance.new("Part")
	part.Name = "Huella"
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = spec.color
	part.Size = spec.size * h
	part.CFrame = at
	if spec.kind == "agua" then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(spec.size.Y, spec.size.X, spec.size.X) * h
		part.CFrame = at * CFrame.Angles(0, 0, math.pi / 2)
		part.Transparency = 0.35
	end
	part.Parent = Workspace
	local goal: { [string]: any } = { Transparency = 1, Color = spec.fade }
	if spec.kind == "agua" then
		goal.Size = Vector3.new(spec.size.Y, spec.size.X * 3, spec.size.X * 3) * h
	end
	TweenService
		:Create(
			part,
			TweenInfo.new(spec.life, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			goal
		)
		:Play()
	Debris:AddItem(part, spec.life)
	return part
end

-- Devuelve el paso por cuadro que deja las pisadas del traje de fx.
function Huellas.new(fx: Tipos.Fx, spec: Spec): Tipos.Tick
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = spec.kind == "lava"
	local holder = fx.mesh.Parent
	local character = holder and holder.Parent
	params.FilterDescendantsInstances = { character or fx.mesh }
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local down = { true, true }
	local alive: { BasePart } = {}
	return function(ctx: Tipos.Context)
		if ctx.display or ctx.speed < MIN_SPEED or fx.rate() <= 0 then
			return
		end
		local h = fx.height
		for i, name in FEET do
			local bone = fx.bones[name]
			if bone then
				local foot = bone.TransformedWorldCFrame
				local hit = Workspace:Raycast(foot.Position, Vector3.new(0, -REACH * h, 0), params)
				if hit and not down[i] then
					-- La huella mira hacia donde camina el personaje.
					local look = if root and root:IsA("BasePart")
						then root.CFrame.LookVector
						else foot.LookVector
					local flat = Vector3.new(look.X, 0, look.Z)
					local yaw = if flat.Magnitude > 0.01 then flat.Unit else -Vector3.zAxis
					local at = CFrame.lookAlong(hit.Position + hit.Normal * 0.03, yaw)
					table.insert(alive, mark(spec, at, h))
					if #alive > MAX_ALIVE then
						table.remove(alive, 1):Destroy()
					end
				end
				down[i] = hit ~= nil
			end
		end
	end
end

return table.freeze(Huellas)
