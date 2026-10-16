--!strict
--[[
	Trajes/Estilos/DiosDelVolcan

	Pesado y amenazante: brazos y piernas con menos vaivén, el cuerpo se
	inclina hacia adelante al caminar, respira hondo y mira despacio a los
	lados. En la vitrina saca músculo con los dos brazos y ruge.
	Efectos: sello de magma a sus pies (charco de lava, aro de runas que gira,
	onda de choque y brasas ralas que suben), hombreras de fuego, contorno y
	halo de lava, humo del volcán de la cabeza y gotas de lava en las manos.
	Nada de fuego encima del cuerpo: el traje se ve entero.
]]

local Tipos = require(script.Parent.Parent.Tipos)

local Aura = require(script.Parent.Parent.Aura)
local Particulas = require(script.Parent.Parent.Particulas)

local T = Particulas.Textures
local rgb = Color3.fromRGB
local LAVA = rgb(255, 120, 30)
local WHITE = rgb(255, 255, 255)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local style: Tipos.Style = {
	arms = 0.8,
	legs = 0.85,
	pose = function(ctx: Tipos.Context): { [string]: CFrame }
		local now = ctx.now
		local move = math.clamp(ctx.speed / 16, 0, 1)
		local still = 1 - move
		local pose = {
			Pecho = CFrame.Angles(-0.13 * move + 0.045 * math.sin(now * 1.1), 0, 0),
			Cabeza = CFrame.Angles(0.05 * move, 0.3 * math.sin(now * 0.28) * still, 0),
		}
		if not ctx.display then
			return pose
		end
		local w = pulse(now, 8, 3.2)
		if w > 0 then -- doble bíceps y rugido
			pose.BrazoIzq = CFrame.Angles(0, 0, -1.45 * w)
			pose.BrazoDer = CFrame.Angles(0, 0, 1.45 * w)
			pose.CodoIzq = CFrame.Angles(0, 0, -1.5 * w)
			pose.CodoDer = CFrame.Angles(0, 0, 1.5 * w)
			pose.Pecho = pose.Pecho * CFrame.Angles(0.1 * w, 0, 0)
			pose.Cabeza = CFrame.Angles(0.3 * w + 0.03 * math.sin(now * 30) * w, 0, 0)
		end
		return pose
	end,
	effects = function(fx: Tipos.Fx)
		local h = fx.height
		-- Sello de magma: el poder está en el piso y en la silueta, no encima del
		-- cuerpo (las lenguas de fuego tapaban el traje). Charco de lava que brilla,
		-- aro de runas que gira, una onda de choque cada tanto y brasas ralas que
		-- suben más alto que la cabeza.
		local floor = fx.aura(Vector3.new(0.7, 0.02, 0.7), 0.01)
		local seal = Instance.new("Attachment")
		seal.Name = "Sello"
		seal.Parent = floor
		Aura.add(fx, seal, { -- charco de lava
			texture = T.Halo,
			colors = { rgb(255, 80, 10), rgb(140, 15, 0) },
			size = { 0.9, 1.0, 0.9 },
			alpha = { 1, 0.72, 0.75, 1 },
			life = { 2.4, 2.4 },
			speed = { 0.001, 0.001 },
			rate = 1.2,
			light = 0.6,
			bright = 1,
			flat = true,
			locked = true,
			z = -1,
		})
		Aura.add(fx, seal, { -- aro de runas que gira
			texture = T.Anillo,
			colors = { rgb(255, 150, 40), rgb(255, 70, 0) },
			size = { 0.8 },
			alpha = { 1, 0.15, 0.15, 1 },
			life = { 3, 3 },
			speed = { 0.001, 0.001 },
			spin = { 18, 18 },
			rate = 0.7,
			light = 1,
			bright = 2,
			flat = true,
			locked = true,
			tilt = 0,
		})
		Aura.add(fx, seal, { -- onda de choque
			texture = T.Anillo,
			colors = { rgb(255, 230, 150), rgb(255, 70, 0) },
			size = { 0.3, 1.6, 2.1 },
			alpha = { 0.1, 0.5, 1 },
			life = { 1.1, 1.1 },
			speed = { 0.001, 0.001 },
			rate = 0.28,
			light = 1,
			bright = 2.5,
			flat = true,
		})
		Aura.add(fx, floor, { -- brasas ralas que suben del sello
			texture = T.Brasa,
			colors = { rgb(255, 235, 160), LAVA, rgb(200, 40, 0) },
			size = { 0.04, 0.03, 0 },
			alpha = { 0, 0.1, 1 },
			life = { 2.2, 3.2 },
			speed = { 0.25, 0.45 },
			accel = Vector3.new(0, 0.1, 0),
			rate = 14,
			light = 1,
			bright = 2,
			spread = 8,
			drag = 0.3,
			shape = Enum.ParticleEmitterShape.Disc,
			z = 0.5,
		})
		-- Hombreras de fuego: dos llamas chicas que marcan la silueta.
		for _, side in { -1, 1 } do
			Aura.add(fx, fx.socket("Pecho", Vector3.new(0.17 * side, 0.12, 0.02)), {
				texture = T.Fuego,
				colors = { WHITE, rgb(255, 215, 190) },
				size = { 0.12, 0.17, 0.09 },
				alpha = { 0.6, 0.1, 0.3, 1 },
				life = { 0.55, 0.8 },
				speed = { 0.12, 0.2 },
				accel = Vector3.new(0, 0.25, 0),
				rate = 9,
				light = 0.45,
				bright = 1.6,
				tilt = 8,
				spread = 10,
				flip = true,
			})
		end
		-- Un halo tenue detrás del cuerpo y el contorno de lava.
		Aura.add(fx, fx.socket("Pecho", Vector3.zero), {
			texture = T.Halo,
			colors = { rgb(255, 110, 20) },
			size = { 0.9, 1.05, 0.95 },
			alpha = { 1, 0.88, 0.9, 1 },
			life = { 1.6, 2 },
			rate = 1.5,
			light = 1,
			locked = true,
			z = -4,
		})
		fx.highlight(rgb(255, 150, 40), rgb(255, 150, 40), 1)
		-- Volcán de la cabeza: un hilo de humo y alguna chispa.
		local top = fx.socket("Cabeza", Vector3.new(0, 0.36, 0))
		Aura.add(fx, top, {
			texture = T.Smoke,
			colors = { rgb(70, 60, 58) },
			size = { 0.1, 0.22 },
			alpha = { 0.4, 1 },
			life = { 1.4, 2.2 },
			speed = { 0.25, 0.4 },
			rate = 3,
			spread = 10,
		})
		Aura.add(fx, top, {
			texture = T.Brasa,
			colors = { rgb(255, 220, 120), LAVA },
			size = { 0.022, 0 },
			life = { 0.6, 1.1 },
			speed = { 0.3, 0.55 },
			accel = Vector3.new(0, -0.6, 0),
			rate = 4,
			light = 1,
			bright = 2,
			spread = 25,
		})
		local chest = fx.socket("Pecho", Vector3.new(0, 0.08, -0.1))
		if chest then
			local light = Instance.new("PointLight")
			light.Color = LAVA
			light.Brightness = 3
			light.Range = 2.2 * h
			light.Parent = chest
		end
		for _, side in { "Izq", "Der" } do
			Aura.add(fx, fx.socket("Mano" .. side, Vector3.new(0, -0.03, 0)), {
				texture = T.Brasa,
				colors = { rgb(255, 200, 80), LAVA },
				size = { 0.025, 0 },
				life = { 0.5, 0.9 },
				speed = { 0, 0.05 },
				accel = Vector3.new(0, -1.2, 0),
				rate = 3,
				light = 1,
				bright = 2,
			})
		end
	end,
}

return style
