--!strict
--[[
	EventShapes

	Las dos cosas sólidas de los eventos (piezas locales, sin colisión):
		coins   monedas de oro que llueven girando alrededor de la cámara
		        (Lluvia de monedas); al pasar de largo vuelven a caer desde arriba
		aurora  tres cortinas de rayos de luz (Beams) celestes y violetas que
		        ondulan alto en el cielo, alrededor de la cámara (Poder doble)
	`update(eye, t, dt, fade)` las mueve; `fade` 0..1 las hace aparecer y
	desaparecer. Las crea EventFx.
]]

local Workspace = game:GetService("Workspace")

local COIN_GOLD = Color3.fromRGB(255, 196, 40)
local COIN_RADIUS = 45 -- alrededor de la cámara
local COIN_TOP, COIN_BOTTOM = 55, -25 -- alto donde aparecen y se reciclan, respecto de la cámara
local AURORA_DISTANCE = 420
local AURORA_HEIGHT = 170
local AURORA_RAYS = 30 -- rayos por cortina
local AURORA_RAY_WIDTH = 32 -- más ancho que la separación (~25): los rayos se superponen
local AURORA_TALL = 90
local AURORA_ARC = math.rad(100) -- lo que abarca cada cortina
local AURORA_LOW, AURORA_HIGH = Color3.fromRGB(170, 90, 255), Color3.fromRGB(90, 230, 255)
local AURORA_FADE = NumberSequence.new({ -- de abajo hacia arriba: aparece, brilla y se apaga
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.25, 0.5),
	NumberSequenceKeypoint.new(0.6, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})

export type Coin = { part: BasePart, speed: number, spin: number }
export type Ribbon = {
	bottoms: { Attachment },
	tops: { Attachment },
	beams: { Beam },
	base: number,
	phase: number,
}

local EventShapes = {}

local function part(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = material
	piece.Anchored = true
	piece.CanCollide, piece.CanQuery, piece.CanTouch = false, false, false
	piece.CastShadow = false
	piece.Transparency = 1
	return piece
end

function EventShapes.coins(folder: Folder, count: number): { Coin }
	local list = {}
	for k = 1, count do
		local coin = part(`Moneda{k}`, Vector3.new(0.3, 1.8, 1.8), COIN_GOLD, Enum.Material.Metal)
		coin.Shape = Enum.PartType.Cylinder
		coin.Reflectance = 0.25
		coin.Position = Vector3.new(0, -1000, 0)
		coin.Parent = folder
		table.insert(
			list,
			{ part = coin, speed = 18 + math.random() * 10, spin = 4 + math.random() * 5 }
		)
	end
	return list
end

local function drop(coin: Coin, eye: Vector3, height: number)
	local angle, distance = math.random() * math.pi * 2, math.sqrt(math.random()) * COIN_RADIUS
	coin.part.Position = eye
		+ Vector3.new(math.cos(angle) * distance, height, math.sin(angle) * distance)
end

function EventShapes.updateCoins(coins: { Coin }, eye: Vector3, t: number, dt: number, fade: number)
	for _, coin in coins do
		local piece = coin.part
		if fade <= 0 then
			piece.Transparency = 1
			continue
		end
		local position = piece.Position
		if position.Y < eye.Y + COIN_BOTTOM or (position - eye).Magnitude > COIN_TOP * 2 then
			drop(coin, eye, COIN_TOP * (0.4 + math.random() * 0.6))
			position = piece.Position
		end
		piece.Transparency = 1 - fade
		piece.CFrame = CFrame.new(position - Vector3.new(0, coin.speed * dt, 0))
			* CFrame.Angles(t * coin.spin, 0, t * coin.spin * 0.6)
	end
end

-- Cada cortina es una fila de rayos verticales (Beams) sobre un arco alto alrededor de la
-- cámara: se apagan suaves arriba y abajo, van de celeste abajo a violeta arriba y la
-- fila ondula, como una aurora de verdad.
function EventShapes.aurora(folder: Folder): { Ribbon }
	local ribbons = {}
	for r = 1, 3 do
		local bottoms, tops, beams = {}, {}, {}
		for k = 1, AURORA_RAYS do
			local bottom, top = Instance.new("Attachment"), Instance.new("Attachment")
			bottom.Name, top.Name = `Aurora{r}_{k}_Abajo`, `Aurora{r}_{k}_Arriba`
			bottom.Parent, top.Parent = Workspace.Terrain, Workspace.Terrain
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = bottom, top
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Width0, beam.Width1 = AURORA_RAY_WIDTH, AURORA_RAY_WIDTH * 1.4
			beam.Color = ColorSequence.new(AURORA_HIGH, AURORA_LOW)
			beam.Transparency = AURORA_FADE
			beam.Enabled = false
			beam.Parent = folder
			table.insert(bottoms, bottom)
			table.insert(tops, top)
			table.insert(beams, beam)
		end
		table.insert(ribbons, {
			bottoms = bottoms,
			tops = tops,
			beams = beams,
			base = (r - 1) * math.pi * 2 / 3,
			phase = r * 1.7,
		})
	end
	return ribbons
end

function EventShapes.updateAurora(ribbons: { Ribbon }, eye: Vector3, t: number, fade: number)
	for _, ribbon in ribbons do
		for _, beam in ribbon.beams do
			beam.Enabled = fade > 0
			beam.Brightness = 2.5 * fade
		end
		if fade <= 0 then
			continue
		end
		for k, bottom in ribbon.bottoms do
			local along = (k - 1) / (AURORA_RAYS - 1)
			local angle = ribbon.base
				+ (along - 0.5) * AURORA_ARC
				+ math.sin(t * 0.35 + along * 6 + ribbon.phase) * 0.04
			local wave = math.sin(t * 0.5 + along * 9 + ribbon.phase) * 14
			local flat = Vector3.new(math.cos(angle), 0, math.sin(angle)) * AURORA_DISTANCE
			local base = Vector3.new(eye.X + flat.X, AURORA_HEIGHT + wave, eye.Z + flat.Z)
			bottom.WorldPosition = base
			ribbon.tops[k].WorldPosition = base + Vector3.new(0, AURORA_TALL + wave * 0.6, 0)
		end
	end
end

return EventShapes
