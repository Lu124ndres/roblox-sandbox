--!strict
--[[
	BasketStyles

	Las 6 canastas de la espalda (mismo orden que Config.Shop.Basket). Cada
	estilo recibe la función que crea piezas (BasketBuilder) y la escala, y
	devuelve el cuerpo, el borde (con su color y material normal) y la
	altura del borde, donde asoman las colas de los peces.
]]

local M = Enum.Material
local rgb = Color3.fromRGB

export type Maker = (
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
) -> BasePart

type Style = (p: Maker, s: number) -> (BasePart, BasePart, Color3, Enum.Material, number)

local BasketStyles = {}

-- Cuerpo de mimbre: costillas verticales y bandas horizontales sobre la cara de afuera.
local function wicker(p: Maker, w: number, h: number, d: number, light: Color3, dark: Color3)
	for x = -w / 2 + 0.2, w / 2 - 0.15, 0.27 do
		p(Vector3.new(0.07, h - 0.1, 0.06), CFrame.new(x, 0, d / 2 + 0.02), dark, M.Fabric)
	end
	for y = -h / 2 + 0.25, h / 2 - 0.2, 0.3 do
		p(Vector3.new(w + 0.04, 0.1, d + 0.04), CFrame.new(0, y, 0), light, M.Fabric)
	end
	p(Vector3.new(w - 0.06, 0.12, d - 0.06), CFrame.new(0, -h / 2 - 0.04, 0), dark, M.Fabric)
end

local list: { Style } = {
	-- 1 mimbre
	function(p, s)
		local body = p(Vector3.new(1.5, 1.4, 1) * s, CFrame.new(), rgb(186, 136, 78), M.Fabric)
		wicker(p, 1.5 * s, 1.4 * s, 1 * s, rgb(206, 158, 96), rgb(128, 86, 46))
		local rim = p(
			Vector3.new(1.64, 0.18, 1.14) * s,
			CFrame.new(0, 0.72 * s, 0),
			rgb(120, 82, 44),
			M.Fabric
		)
		return body, rim, rim.Color, rim.Material, 0.72 * s
	end,
	-- 2 reforzada
	function(p, s)
		local body = p(Vector3.new(1.5, 1.5, 1) * s, CFrame.new(), rgb(176, 124, 70), M.Fabric)
		wicker(p, 1.5 * s, 1.5 * s, 1 * s, rgb(196, 146, 88), rgb(120, 80, 42))
		for _, y in { -0.45, 0.4 } do
			p(
				Vector3.new(1.58, 0.16, 1.08) * s,
				CFrame.new(0, y * s, 0),
				rgb(170, 176, 186),
				M.Metal
			)
			for x = -1, 1, 2 do
				p(
					Vector3.one * 0.12 * s,
					CFrame.new(x * 0.62 * s, y * s, 0.55 * s),
					rgb(220, 224, 230),
					M.Metal,
					Enum.PartType.Ball
				)
			end
		end
		local rim = p(
			Vector3.new(1.66, 0.2, 1.16) * s,
			CFrame.new(0, 0.78 * s, 0),
			rgb(150, 156, 166),
			M.Metal
		)
		return body, rim, rim.Color, rim.Material, 0.78 * s
	end,
	-- 3 pescador
	function(p, s)
		local body = p(Vector3.new(1.45, 1.75, 1) * s, CFrame.new(), rgb(196, 150, 90), M.Fabric)
		wicker(p, 1.45 * s, 1.75 * s, 1 * s, rgb(214, 170, 108), rgb(132, 92, 50))
		local rim = p(
			Vector3.new(1.6, 0.18, 1.14) * s,
			CFrame.new(0, 0.9 * s, 0),
			rgb(110, 74, 40),
			M.Fabric
		)
		p(
			Vector3.new(1.55, 0.12, 1.05) * s,
			CFrame.new(0, 1.15 * s, -0.55 * s) * CFrame.Angles(math.rad(-60), 0, 0),
			rgb(150, 104, 58),
			M.Fabric
		)
		p(
			Vector3.new(0.05, 0.6, 0.05) * s,
			CFrame.new(0.8 * s, 0.5 * s, 0.4 * s),
			rgb(230, 225, 210),
			M.Fabric
		)
		p(
			Vector3.one * 0.3 * s,
			CFrame.new(0.8 * s, 0.15 * s, 0.4 * s),
			rgb(230, 50, 50),
			M.SmoothPlastic,
			Enum.PartType.Ball
		)
		p(
			Vector3.new(0.31, 0.1, 0.31) * s,
			CFrame.new(0.8 * s, 0.2 * s, 0.4 * s),
			rgb(250, 250, 250),
			M.SmoothPlastic,
			Enum.PartType.Cylinder
		)
		return body, rim, rim.Color, rim.Material, 0.9 * s
	end,
	-- 4 baúl
	function(p, s)
		local gold = rgb(255, 196, 60)
		local body = p(Vector3.new(1.6, 1.35, 1.05) * s, CFrame.new(), rgb(132, 82, 44), M.Wood)
		for x = -1, 1, 2 do
			p(Vector3.new(0.14, 1.38, 1.09) * s, CFrame.new(x * 0.74 * s, 0, 0), gold, M.Metal)
		end
		p(Vector3.new(1.64, 0.14, 1.09) * s, CFrame.new(0, -0.3 * s, 0), gold, M.Metal)
		p(Vector3.new(0.3, 0.36, 0.08) * s, CFrame.new(0, 0.2 * s, 0.55 * s), gold, M.Metal)
		p(
			Vector3.new(1.62, 0.16, 1.07) * s,
			CFrame.new(0, 0.2 * s, -0.75 * s) * CFrame.Angles(math.rad(-75), 0, 0),
			rgb(150, 96, 52),
			M.Wood
		)
		local rim = p(Vector3.new(1.66, 0.16, 1.11) * s, CFrame.new(0, 0.72 * s, 0), gold, M.Metal)
		return body, rim, rim.Color, rim.Material, 0.72 * s
	end,
	-- 5 red de arrastre
	function(p, s)
		local net = rgb(46, 150, 90)
		local body = p(Vector3.new(1.6, 1.6, 1.05) * s, CFrame.new(), rgb(30, 90, 60), M.Fabric)
		body.Transparency = 0.25
		for x = -0.6, 0.61, 0.3 do
			p(Vector3.new(0.05, 1.62, 1.08) * s, CFrame.new(x * s, 0, 0), net, M.Fabric)
		end
		for y = -0.6, 0.61, 0.3 do
			p(Vector3.new(1.64, 0.05, 1.08) * s, CFrame.new(0, y * s, 0), net, M.Fabric)
		end
		local rim = p(
			Vector3.new(1.7, 0.2, 1.15) * s,
			CFrame.new(0, 0.82 * s, 0),
			rgb(150, 110, 60),
			M.Fabric
		)
		for _, x in { -0.75, 0, 0.75 } do
			p(
				Vector3.one * 0.32 * s,
				CFrame.new(x * s, 0.82 * s, 0.6 * s),
				rgb(255, 130, 30),
				M.SmoothPlastic,
				Enum.PartType.Ball
			)
		end
		return body, rim, rim.Color, rim.Material, 0.82 * s
	end,
	-- 6 bodega del abismo
	function(p, s)
		local purple = rgb(170, 70, 255)
		local body = p(Vector3.new(1.6, 1.7, 1.1) * s, CFrame.new(), rgb(34, 30, 46), M.Metal)
		for _, x in { -0.5, 0, 0.5 } do
			p(Vector3.new(0.08, 1.3, 0.06) * s, CFrame.new(x * s, 0, 0.56 * s), purple, M.Neon)
		end
		p(Vector3.new(1.66, 0.14, 1.16) * s, CFrame.new(0, -0.7 * s, 0), rgb(60, 52, 80), M.Metal)
		local rim = p(Vector3.new(1.7, 0.18, 1.2) * s, CFrame.new(0, 0.86 * s, 0), purple, M.Neon)
		return body, rim, rim.Color, rim.Material, 0.86 * s
	end,
}

BasketStyles.list = list

return BasketStyles
