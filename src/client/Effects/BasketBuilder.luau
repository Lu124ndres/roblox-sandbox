--!strict
--[[
	BasketBuilder

	Arma la canasta de la espalda según el nivel comprado en la tienda
	(Config.Shop.Basket), cada una con su estilo y un poco más grande:
		1 mimbre      tejido de mimbre con costillas y bandas
		2 reforzada   mimbre con flejes de metal y remaches
		3 pescador    cesta alta con tapa abierta y un corcho colgando
		4 baúl        cofre de madera con esquinas y cerradura de oro
		5 red         red verde con nudos y boyas naranjas
		6 abismo      bodega de metal oscuro con runas moradas que brillan
	Devuelve las piezas que FishBasket anima (colas de pez, borde, luz).
	Todo sin masa ni colisión, soldado al torso con Weld (C0 fijo, así una
	pieza sacada y vuelta a poner queda en su lugar).

	Los adornos del estilo (costillas, flejes, tapa, boyas...) van en la
	subcarpeta trim; FishBasket la deja sin padre para jugadores lejanos.
	Cuerpo, borde, correas y colas quedan siempre.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local BasketStyles = require(script.Parent.BasketStyles)

export type Basket = {
	folder: Folder,
	trim: Folder, -- adornos que se pueden quitar de lejos
	tails: { BasePart },
	rim: BasePart,
	rimColor: Color3,
	rimMaterial: Enum.Material,
	light: PointLight,
	root: BasePart,
}

local rgb = Color3.fromRGB
local M = Enum.Material
local SLOTS = 6
local TAIL_COLORS =
	{ UIConfig.FishColors.Sardina, UIConfig.FishColors.Caballa, UIConfig.FishColors.PezPayaso }

local BasketBuilder = {}

BasketBuilder.SLOTS = SLOTS

type Maker = BasketStyles.Maker

local function maker(folder: Instance, torso: BasePart, back: CFrame): Maker
	return function(size, cf, color, material, shape)
		local part = Instance.new("Part")
		part.Size = size
		part.Shape = shape or Enum.PartType.Block
		part.Color = color
		part.Material = material or M.SmoothPlastic
		part.CFrame = back * cf
		part.Massless, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1 = torso, part
		weld.C0 = torso.CFrame:ToObjectSpace(part.CFrame)
		weld.Parent = part
		part.Parent = folder
		return part
	end
end

function BasketBuilder.build(character: Model, level: number): Basket?
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return nil
	end
	local STYLES = BasketStyles.list
	local style = STYLES[math.clamp(level, 1, #STYLES)]
	-- Al tamaño del avatar (un torso normal mide 2 de ancho) y un poco más grande por nivel.
	local fit = math.clamp(torso.Size.X / 2, 0.45, 1.3) * 0.85
	local scale = fit * (1 + (math.clamp(level, 1, #STYLES) - 1) * 0.06)
	local folder = Instance.new("Folder")
	folder.Name = "Canasta"
	local back = torso.CFrame * CFrame.new(0, 0, torso.Size.Z / 2 + 0.55 * scale)
	local trim = Instance.new("Folder")
	trim.Name = "Adornos"
	trim.Parent = folder
	local p = maker(folder, torso, back)
	-- El estilo crea todo en trim; después cuerpo y borde vuelven a la canasta.
	local body, rim, rimColor, rimMaterial, top = style(maker(trim, torso, back), scale)
	body.Parent, rim.Parent = folder, folder
	for side = -1, 1, 2 do -- correas sobre los hombros
		p(
			Vector3.new(0.18, 0.12, torso.Size.Z + 1.1 * scale),
			CFrame.new(side * 0.5 * fit, torso.Size.Y / 2 - 0.05, -0.15 - 0.55 * scale),
			rgb(90, 60, 36),
			M.Fabric
		)
	end
	local tails: { BasePart } = {}
	for k = 1, SLOTS do
		local x = ((k - 1) % 3 - 1) * 0.42 * scale
		local z = (if k <= 3 then -0.18 else 0.2) * scale
		local tail = p(
			Vector3.new(0.1, 0.55, 0.35) * scale,
			CFrame.new(x, top + 0.25 * scale, z)
				* CFrame.Angles(math.rad((k % 2) * 30 - 15), math.rad(90), 0),
			TAIL_COLORS[(k - 1) % #TAIL_COLORS + 1]
		)
		tail.Transparency = 1
		table.insert(tails, tail)
	end
	local light = Instance.new("PointLight")
	light.Range = 8
	light.Color = if level >= #BasketStyles.list then rgb(170, 70, 255) else UIConfig.Colors.Feeding
	light.Enabled = level >= #BasketStyles.list
	light.Parent = rim
	folder.Parent = character
	return {
		folder = folder,
		trim = trim,
		tails = tails,
		rim = rim,
		rimColor = rimColor,
		rimMaterial = rimMaterial,
		light = light,
		root = body,
	}
end

return BasketBuilder
