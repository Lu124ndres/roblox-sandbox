--!strict
--[[
	FoamShore

	La espuma de la orilla (Isla.Espuma, tools/generar_isla.py) es un anillo
	redondo y la isla de bloques (World/BlockIsland) no lo es: muchas piezas
	quedaban encima de la arena, como franjas de agua flotando. Al cargar se
	borran las que tocan la isla en alguna esquina o en el punto al que llegan
	cuando la ola sube (`travel` studs hacia la arena, -Z local).
]]

local Workspace = game:GetService("Workspace")

local LAND_MARGIN = 0.3 -- la isla cuenta como tierra si asoma esto por encima de la espuma

local FoamShore = {}

-- true si en algún punto de la pieza, o al subir la ola, debajo hay isla en vez de agua.
function FoamShore.overLand(part: BasePart, island: Instance, travel: number): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island }
	local half = part.Size / 2
	local reach = half.Z + travel
	for _, offset in
		{
			Vector3.new(-half.X, 0, half.Z),
			Vector3.new(half.X, 0, half.Z),
			Vector3.new(-half.X, 0, -reach),
			Vector3.new(half.X, 0, -reach),
			Vector3.new(0, 0, -reach),
		}
	do
		local spot = part.CFrame:PointToWorldSpace(offset)
		local hit = Workspace:Raycast(spot + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
		if hit and hit.Position.Y > part.Position.Y - LAND_MARGIN then
			return true
		end
	end
	return false
end

return FoamShore
