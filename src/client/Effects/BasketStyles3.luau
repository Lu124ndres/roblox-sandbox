--!strict
--[[
	BasketStyles3

	Canastas 11 a 14 de la espalda (mismo orden que Config.Shop.Basket), con
	la misma forma de estilo que BasketStyles: reciben la función que crea
	piezas y la escala, y devuelven cuerpo, borde (color y material) y la
	altura del borde. BasketBuilder las agrega después de las 6 primeras.
]]

local BasketStyles = require(script.Parent.BasketStyles)
local BasketStyles2 = require(script.Parent.BasketStyles2)

local M = Enum.Material
local rgb = Color3.fromRGB
local Ball, Cylinder = Enum.PartType.Ball, Enum.PartType.Cylinder

type Maker = BasketStyles.Maker
type Style = (p: Maker, s: number) -> (BasePart, BasePart, Color3, Enum.Material, number)

local chest = BasketStyles2.chest

local list: { Style } = {
	-- 11 jaula dorada
	function(p, s)
		local gold = rgb(255, 200, 60)
		local body = p(
			Vector3.new(1.5, 1.4, 1.0) * s,
			CFrame.new(0, -0.1 * s, 0),
			rgb(255, 240, 200),
			M.Fabric
		)
		body.Transparency = 0.6
		for x = -0.7, 0.71, 0.35 do
			p(Vector3.new(0.08, 1.5, 0.08) * s, CFrame.new(x * s, 0, 0.55 * s), gold, M.Foil)
			p(Vector3.new(0.08, 1.5, 0.08) * s, CFrame.new(x * s, 0, -0.55 * s), gold, M.Foil)
		end
		p(Vector3.new(1.7, 0.16, 1.2) * s, CFrame.new(0, -0.75 * s, 0), gold, M.Foil)
		p(Vector3.new(0.5, 0.5, 0.5) * s, CFrame.new(0, 1.05 * s, 0), gold, M.Foil, Ball)
		local rim = p(Vector3.new(1.7, 0.16, 1.2) * s, CFrame.new(0, 0.75 * s, 0), gold, M.Foil)
		return body, rim, rim.Color, rim.Material, 0.75 * s
	end,
	-- 12 tesoro del leviatán
	function(p, s)
		local body, rim =
			chest(p, s, rgb(20, 90, 110), rgb(120, 255, 220), M.Neon, rgb(255, 255, 255))
		for x = -1, 1, 2 do
			p(
				Vector3.new(0.1, 0.8, 0.6) * s,
				CFrame.new(x * 0.9 * s, 0.2 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(x * 25)),
				rgb(40, 160, 170),
				M.SmoothPlastic
			)
		end
		return body, rim, rim.Color, rim.Material, 0.75 * s
	end,
	-- 13 arca celestial
	function(p, s)
		local body, rim =
			chest(p, s, rgb(245, 245, 255), rgb(255, 215, 90), M.Foil, rgb(140, 210, 255))
		for x = -1, 1, 2 do -- alas
			for k = 0, 2 do
				p(
					Vector3.new(0.08, 0.32, 0.9 - k * 0.2) * s,
					CFrame.new(x * (0.95 + k * 0.12) * s, (0.35 + k * 0.2) * s, -0.1 * s)
						* CFrame.Angles(0, 0, math.rad(x * (30 + k * 12))),
					rgb(255, 255, 255),
					M.SmoothPlastic
				)
			end
		end
		return body, rim, rim.Color, rim.Material, 0.75 * s
	end,
	-- 14 bóveda infinita
	function(p, s)
		local body = p(Vector3.new(1.7, 1.7, 1.15) * s, CFrame.new(), rgb(16, 14, 30), M.Metal)
		p(
			Vector3.new(1.0, 1.0, 0.1) * s,
			CFrame.new(0, 0, 0.6 * s) * CFrame.Angles(0, math.rad(90), 0),
			rgb(120, 80, 255),
			M.Neon,
			Cylinder
		)
		p(
			Vector3.new(0.6, 0.6, 0.12) * s,
			CFrame.new(0, 0, 0.62 * s) * CFrame.Angles(0, math.rad(90), 0),
			rgb(255, 255, 255),
			M.Neon,
			Cylinder
		)
		for _, y in { -0.6, 0.6 } do
			p(Vector3.new(1.76, 0.1, 1.2) * s, CFrame.new(0, y * s, 0), rgb(255, 120, 255), M.Neon)
		end
		local rim = p(
			Vector3.new(1.76, 0.18, 1.22) * s,
			CFrame.new(0, 0.9 * s, 0),
			rgb(120, 80, 255),
			M.Neon
		)
		return body, rim, rim.Color, rim.Material, 0.9 * s
	end,
}

return { list = list }
