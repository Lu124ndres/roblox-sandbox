--!strict
--[[
	ZorroCubos

	Los cubitos de agua que flotan alrededor del zorro (como en la referencia):
	bloques chicos de agua celeste y verde agua, y uno de cada cuatro de espuma
	brillante, que giran despacio y suben y bajan alrededor del cuerpo y de las
	colas. Cada uno va atado a un hueso, así siguen la animación. Más cubos al
	crecer (COUNT por etapa).

	Son primitivas (no partículas), así que el modo rápido se aplica a mano:
	con fxScale = 0 no se ve ninguno y con efectos reducidos, menos. Con
	visible = false (el zorro escondido o lejos de la cámara, lo decide
	ZorroAgua) se esconden todos.
	Se mueven todos juntos con BulkMoveTo (una sola llamada por cuadro).
		new(rig)                                crea los cubos (escondidos)
		update(c, dt, alto, etapa, visible)
		lift(c, 0..1)                           se abren y suben (aullido, abanico)
		destroy(c)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rig = require(ReplicatedStorage.Shared.Zorro.Rig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local COUNT = { 5, 8, 12, 16 } -- cubos por etapa
local LIFT_DECAY = 0.6 -- lo que tarda en volver de un "lift"
local BODY = { "Pecho", "Columna", "Cadera", "Cuello2", "Cabeza" }
local rgb = Color3.fromRGB
local LOOKS = { -- paleta de la biblia: claro, verde agua, claro y espuma
	{ color = rgb(143, 227, 247), material = Enum.Material.Glass, transparency = 0.35 },
	{ color = rgb(111, 230, 214), material = Enum.Material.Glass, transparency = 0.35 },
	{ color = rgb(143, 227, 247), material = Enum.Material.Glass, transparency = 0.35 },
	{ color = rgb(230, 247, 255), material = Enum.Material.Neon, transparency = 0.45 },
}

type Cube = {
	part: Part,
	bone: Bone,
	dir: Vector3, -- hacia dónde sale del hueso (unitario)
	radius: number, -- distancia al hueso, en altos del zorro
	size: number, -- lado, en altos del zorro
	phase: number,
	speed: number, -- vueltas alrededor del hueso (rad/s)
	axis: Vector3, -- eje de su giro propio
	spin: number,
	look: number, -- su LOOKS
	shown: boolean,
}
export type Cubos = { folder: Folder, cubes: { Cube }, lift: number, height: number }

local ZorroCubos = {}

-- Huesos donde se atan: el cuerpo y el medio y la punta de cada cola, alternados.
local function add(list: { Bone }, bone: Bone?)
	if bone then
		table.insert(list, bone)
	end
end

local function anchors(rig: Rig.Rig): { Bone }
	local body, tails = {}, {}
	for _, name in BODY do
		add(body, rig.bones[name])
	end
	for _, tail in rig.tails do
		add(tails, rig.bones[`{tail.prefix}2`])
		add(tails, rig.bones[`{tail.prefix}5`] or rig.bones[`{tail.prefix}4`])
	end
	local list = {}
	for i = 1, math.max(#body, #tails) do
		add(list, body[i])
		add(list, tails[i])
	end
	return list
end

function ZorroCubos.new(rig: Rig.Rig): Cubos
	local folder = Instance.new("Folder")
	folder.Name = "CubitosDeAgua"
	folder.Parent = Workspace
	local rng = Random.new(31) -- el mismo reparto cada vez
	local bones, cubes = anchors(rig), {}
	for i = 1, if #bones > 0 then COUNT[#COUNT] else 0 do
		local look = (i - 1) % #LOOKS + 1
		local part = Instance.new("Part")
		part.Name = "Cubito"
		part.Material = LOOKS[look].material
		part.Color = LOOKS[look].color
		part.Transparency = 1
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = false
		part.Parent = folder
		local dir = rng:NextUnitVector()
		table.insert(cubes, {
			part = part,
			bone = bones[(i - 1) % #bones + 1],
			dir = Vector3.new(dir.X, math.abs(dir.Y) * 0.6 + 0.2, dir.Z).Unit,
			radius = rng:NextNumber(0.1, 0.22),
			size = rng:NextNumber(0.022, 0.042),
			phase = rng:NextNumber(0, math.pi * 2),
			speed = rng:NextNumber(0.25, 0.6) * (if rng:NextNumber() < 0.5 then -1 else 1),
			axis = rng:NextUnitVector(),
			spin = rng:NextNumber(0.4, 1.1),
			look = look,
			shown = false,
		})
	end
	return { folder = folder, cubes = cubes, lift = 0, height = 0 }
end

-- Se abren y suben un rato (decae solo).
function ZorroCubos.lift(c: Cubos, amount: number)
	c.lift = math.max(c.lift, amount)
end

-- Lo muestra o lo esconde; true si recién aparece (hay que darle tamaño).
local function show(cube: Cube, on: boolean): boolean
	if cube.shown == on then
		return false
	end
	cube.shown = on
	cube.part.Transparency = if on then LOOKS[cube.look].transparency else 1
	return on
end

function ZorroCubos.update(c: Cubos, dt: number, height: number, stage: number, visible: boolean)
	c.lift = math.max(0, c.lift - dt / LIFT_DECAY)
	local count = COUNT[math.clamp(stage, 1, #COUNT)]
	local wanted = if visible then math.round(count * ClientSettings.fxScale()) else 0
	local resize = math.abs(height - c.height) > c.height * 0.01
	if resize then
		c.height = height
	end
	local t = os.clock()
	local parts: { BasePart }, frames: { CFrame } = {}, {}
	for i, cube in c.cubes do
		local appeared = show(cube, i <= wanted)
		if cube.shown then
			if resize or appeared then
				cube.part.Size = Vector3.one * (cube.size * height)
			end
			local open = 1 + 0.6 * c.lift
			local around = CFrame.fromAxisAngle(Vector3.yAxis, cube.phase + t * cube.speed)
			local offset = around:VectorToWorldSpace(cube.dir) * (cube.radius * height * open)
			local bob = math.sin(t * 1.3 + cube.phase) * 0.03 + 0.12 * c.lift
			local at = cube.bone.TransformedWorldCFrame.Position
				+ offset
				+ Vector3.yAxis * (bob * height)
			table.insert(parts, cube.part)
			table.insert(
				frames,
				CFrame.new(at) * CFrame.fromAxisAngle(cube.axis, cube.phase + t * cube.spin)
			)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function ZorroCubos.destroy(c: Cubos)
	c.folder:Destroy()
end

return table.freeze(ZorroCubos)
