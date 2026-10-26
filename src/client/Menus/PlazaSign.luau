--!strict
--[[
	PlazaSign

	Letreros de piedra de la plaza (GroupSign, LikeSign): un tablero sobre dos
	postes, apoyado en lo más alto que haya en ese punto (bloques del jardín o
	terreno) y de cara al spawn. Son primitivas locales de cada cliente.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local POST = 1 -- grosor de los dos postes
local STONE = Color3.fromRGB(70, 74, 86)
local GROUND_TRIES = 120 -- cada medio segundo, hasta que aparezca la isla

local PlazaSign = {}

-- Lo más alto que hay ahí (los bloques del jardín o el terreno), sin contar a los jugadores.
function PlazaSign.groundAt(x: number, z: number): number
	-- Hasta que el servidor arma la isla, el rayo llega al fondo del mar: se espera
	-- a encontrar suelo sobre el agua.
	for _ = 1, GROUND_TRIES do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		local characters = {}
		for _, other in Players:GetPlayers() do
			if other.Character then
				table.insert(characters, other.Character)
			end
		end
		params.FilterDescendantsInstances = characters
		local hit = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), params)
		-- Las piezas invisibles (zonas, detectores) no son suelo: se saltan.
		while hit and hit.Instance:IsA("BasePart") and hit.Instance.Transparency >= 1 do
			params:AddToFilter(hit.Instance)
			hit = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), params)
		end
		if hit and hit.Position.Y > WorldLayout.waterLevel then
			return hit.Position.Y
		end
		task.wait(0.5)
	end
	return WorldLayout.plateauHeight
end

local function part(folder: Folder, name: string, size: Vector3, cframe: CFrame): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Anchored = true
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = STONE
	piece.Material = Enum.Material.SmoothPlastic
	piece.Parent = folder
	return piece
end

-- Tablero de piedra sobre dos postes en `spot` ({ x, z }), de cara al spawn. Devuelve el tablero.
function PlazaSign.build(name: string, spot: Vector2, board: Vector3, lift: number): Part
	local ground = PlazaSign.groundAt(spot.X, spot.Y)
	local spawn = WorldLayout.spawnPosition
	local center = Vector3.new(spot.X, ground + lift + board.Y / 2, spot.Y)
	local facing = CFrame.lookAt(center, Vector3.new(spawn[1], center.Y, spawn[2]))
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	local tablero = part(folder, "Tablero", board, facing)
	local postHeight = lift + board.Y
	for _, side in { -1, 1 } do
		local x = side * (board.X / 2 - POST)
		local y = -board.Y / 2 - lift + postHeight / 2
		part(
			folder,
			"Poste",
			Vector3.new(POST, postHeight, POST),
			facing * CFrame.new(x, y, board.Z)
		)
	end
	return tablero
end

return PlazaSign
