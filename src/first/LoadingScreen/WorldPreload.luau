--!strict
--[[
	WorldPreload

	El mapa en la pantalla de carga. El lugar usa StreamingEnabled: al cliente solo le
	llega lo que está cerca de su personaje, y las mallas y texturas de esas piezas bajan
	después, de a poco (se ven grises o sin forma un rato). Aquí se pide el mapa alrededor
	del personaje y se juntan sus piezas para precargarlas.
		streamAround(player)            pide (y espera) las piezas cercanas al personaje
		collect(root) -> { Instance }   una instancia por cada malla, textura, partícula o
		                                sonido distinto de root

	Se precargan instancias y no IDs sueltos: un ID suelto ContentProvider lo pide
	como imagen, y las mallas y los sonidos fallan ("Asset type does not match").
]]

local STREAM_TIMEOUT = 15 -- segundos que espera RequestStreamAroundAsync

local WorldPreload = {}

function WorldPreload.streamAround(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		-- pcall: si Roblox no contesta a tiempo, la carga sigue con lo que haya llegado.
		pcall(function()
			player:RequestStreamAroundAsync(root.Position, STREAM_TIMEOUT)
		end)
	end
end

-- Qué asset trae la instancia (para no precargar dos veces lo mismo); nil si ninguno.
local function contentKey(item: Instance): string?
	if item:IsA("MeshPart") then
		return item.MeshId .. item.TextureID
	elseif item:IsA("SpecialMesh") then
		return item.MeshId .. item.TextureId
	elseif item:IsA("Sound") then
		return item.SoundId
	elseif -- Decal incluye Texture, que hereda de Decal
		item:IsA("Decal")
		or item:IsA("ParticleEmitter")
		or item:IsA("Beam")
		or item:IsA("Trail")
	then
		return (item :: any).Texture
	elseif item:IsA("SurfaceAppearance") then
		return item:GetFullName() -- no deja leer sus IDs: va cada una
	end
	return nil
end

function WorldPreload.collect(root: Instance): { Instance }
	local seen: { [string]: boolean } = {}
	local list: { Instance } = {}
	for _, item in root:GetDescendants() do
		local key = contentKey(item)
		if key and key ~= "" and not seen[key] then
			seen[key] = true
			table.insert(list, item)
		end
	end
	return list
end

return table.freeze(WorldPreload)
