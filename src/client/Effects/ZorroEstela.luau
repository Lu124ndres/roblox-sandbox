--!strict
--[[
	ZorroEstela

	La estela de agua que deja el zorro cuando corre o persigue su cola (el
	festejo de los combos): manchas de espuma sobre el agua debajo de sus patas
	traseras, que se abren y se borran, y gotas que saltan de las patas. Cada
	EVERY segundos (en modo rápido, menos manchas y sin gotas: son partes, no
	partículas, pero igual se cuidan). trail (0..1) es state.trail de Zorro.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local ZorroGotas = require(script.Parent.ZorroGotas)

local EVERY = 0.07 -- s entre manchas
local EVERY_LOW = 0.2 -- en modo rápido
local SECONDS = 1.6 -- lo que dura una mancha
local FOAM = Color3.fromRGB(225, 250, 255)
local CYAN = Color3.fromRGB(120, 235, 245)
local PAWS = { "PieIzq", "PieDer" }

export type Estela = { folder: Folder, next: number, paw: number }

local ZorroEstela = {}

function ZorroEstela.new(): Estela
	local folder = Instance.new("Folder")
	folder.Name = "EstelaZorro"
	folder.Parent = Workspace
	return { folder = folder, next = 0, paw = 1 }
end

local function patch(e: Estela, at: Vector3, size: number, color: Color3)
	local part = Instance.new("Part")
	part.Name = "Espuma"
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = 0.3
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.CastShadow = false
	part.Size = Vector3.new(0.1, size, size)
	part.CFrame = CFrame.new(at) * CFrame.Angles(0, math.random() * math.pi, math.rad(90))
	part.Parent = e.folder
	local info = TweenInfo.new(SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(part, info, { Size = Vector3.new(0.1, size * 2.4, size * 2.4), Transparency = 1 })
		:Play()
	Debris:AddItem(part, SECONDS + 0.1)
end

-- point: posición de un hueso (Zorro.Motion.point); water: altura del agua.
function ZorroEstela.update(
	e: Estela,
	trail: number,
	height: number,
	water: number,
	point: (name: string) -> Vector3?
)
	local now = os.clock()
	if trail <= 0.05 or now < e.next then
		return
	end
	local low = ClientSettings.fxScale() <= 0
	e.next = now + (if low then EVERY_LOW else EVERY)
	e.paw = e.paw % #PAWS + 1
	local foot = point(PAWS[e.paw])
	if not foot then
		return
	end
	local at = Vector3.new(foot.X, water + 0.06, foot.Z)
	patch(e, at, height * (0.12 + 0.08 * trail), if e.paw == 1 then FOAM else CYAN)
	if not low then
		ZorroGotas.paws(at, height)
	end
end

function ZorroEstela.destroy(e: Estela)
	e.folder:Destroy()
end

return table.freeze(ZorroEstela)
