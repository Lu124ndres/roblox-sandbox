--!strict
--[[
	BasketStyles2

	Canastas 7 a 10 de la espalda (11 a 14 en BasketStyles3) (mismo orden que Config.Shop.Basket), con
	la misma forma de estilo que BasketStyles: reciben la función que crea
	piezas y la escala, y devuelven cuerpo, borde (color y material) y la
	altura del borde. BasketBuilder las agrega después de las 6 primeras.
]]

local BasketStyles = require(script.Parent.BasketStyles)

local M = Enum.Material
local rgb = Color3.fromRGB
local Ball, Cylinder = Enum.PartType.Ball, Enum.PartType.Cylinder

type Maker = BasketStyles.Maker
type Style = (p: Maker, s: number) -> (BasePart, BasePart, Color3, Enum.Material, number)

-- Cofre con bandas, cerradura y gemas: la base de varios estilos.
local function chest(
	p: Maker,
	s: number,
	wood: Color3,
	band: Color3,
	bandMaterial: Enum.Material,
	gem: Color3?
)
	local body = p(Vector3.new(1.65, 1.4, 1.1) * s, CFrame.new(), wood, M.Wood)
	for x = -1, 1, 2 do
		p(Vector3.new(0.14, 1.43, 1.14) * s, CFrame.new(x * 0.76 * s, 0, 0), band, bandMaterial)
	end
	p(Vector3.new(1.69, 0.14, 1.14) * s, CFrame.new(0, -0.35 * s, 0), band, bandMaterial)
	p(Vector3.new(0.34, 0.4, 0.08) * s, CFrame.new(0, 0.15 * s, 0.58 * s), band, bandMaterial)
	if gem then
		p(Vector3.one * 0.22 * s, CFrame.new(0, 0.15 * s, 0.64 * s), gem, M.Neon, Ball)
		for x = -1, 1, 2 do
			p(Vector3.one * 0.16 * s, CFrame.new(x * 0.76 * s, 0.4 * s, 0.6 * s), gem, M.Neon, Ball)
		end
	end
	local rim = p(Vector3.new(1.72, 0.18, 1.17) * s, CFrame.new(0, 0.75 * s, 0), band, bandMaterial)
	return body, rim
end

local list: { Style } = {
	-- 7 cofre de coral
	function(p, s)
		local body, rim =
			chest(p, s, rgb(255, 150, 140), rgb(255, 236, 220), M.SmoothPlastic, rgb(255, 120, 200))
		for k = 1, 3 do
			p(
				Vector3.new(0.12, 0.5, 0.12) * s,
				CFrame.new((k - 2) * 0.45 * s, 1.0 * s, 0.3 * s)
					* CFrame.Angles(0, 0, math.rad(k * 20 - 40)),
				rgb(255, 110, 150),
				M.SmoothPlastic
			)
		end
		return body, rim, rim.Color, rim.Material, 0.75 * s
	end,
	-- 8 barril pirata
	function(p, s)
		local body = p(
			Vector3.new(1.75, 1.4, 1.4) * s,
			CFrame.new() * CFrame.Angles(0, 0, math.rad(90)),
			rgb(120, 74, 38),
			M.Wood,
			Cylinder
		)
		for _, y in { -0.5, 0, 0.5 } do
			p(
				Vector3.new(0.12, 1.45, 1.45) * s,
				CFrame.new(0, y * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
				rgb(60, 60, 66),
				M.Metal,
				Cylinder
			)
		end
		p(
			Vector3.new(0.5, 0.5, 0.06) * s,
			CFrame.new(0, 0, 0.72 * s),
			rgb(250, 250, 250),
			M.SmoothPlastic
		)
		p(
			Vector3.new(0.2, 0.2, 0.08) * s,
			CFrame.new(0, 0.05 * s, 0.74 * s),
			rgb(20, 20, 20),
			M.SmoothPlastic,
			Ball
		)
		local rim = p(
			Vector3.new(0.16, 1.3, 1.3) * s,
			CFrame.new(0, 0.8 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			rgb(90, 56, 30),
			M.Wood,
			Cylinder
		)
		return body, rim, rim.Color, rim.Material, 0.8 * s
	end,
	-- 9 saco de cristal
	function(p, s)
		local body =
			p(Vector3.new(1.6, 1.6, 1.2) * s, CFrame.new(), rgb(170, 230, 255), M.Glass, Ball)
		body.Transparency = 0.35
		for k = 1, 5 do
			p(
				Vector3.new(0.18, 0.5, 0.18) * s,
				CFrame.new((k - 3) * 0.3 * s, -0.2 * s, 0.1 * s)
					* CFrame.Angles(math.rad(10), 0, math.rad(k * 15 - 45)),
				rgb(120, 220, 255),
				M.Neon
			)
		end
		local rim = p(
			Vector3.new(1.2, 0.2, 0.9) * s,
			CFrame.new(0, 0.78 * s, 0),
			rgb(220, 250, 255),
			M.Glass
		)
		return body, rim, rim.Color, rim.Material, 0.78 * s
	end,
	-- 10 cofre volcánico
	function(p, s)
		local body, rim = chest(p, s, rgb(50, 34, 30), rgb(255, 110, 30), M.Neon, rgb(255, 200, 60))
		body.Material = M.CrackedLava
		return body, rim, rim.Color, rim.Material, 0.75 * s
	end,
}

return { list = list, chest = chest }
