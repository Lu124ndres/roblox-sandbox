--!strict
--[[
	Trajes/Estilos/DiosDelVolcan

	Pesado y amenazante: brazos y piernas con menos vaivén, el cuerpo se
	inclina hacia adelante al caminar, respira hondo y mira despacio a los
	lados. En la vitrina saca músculo con los dos brazos y ruge.
	Efectos: aura de fuego (Trajes/Aura), humo y chispas del volcán de la
	cabeza, brillo de lava en el pecho y gotas de lava en las manos.
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
		-- Aura de fuego: lenguas de fuego por todo el cuerpo y a sus pies,
		-- brasas que suben, halo naranja y una onda de calor en el piso.
		Aura.build(fx, {
			tongues = {
				texture = T.Fuego,
				colors = { WHITE, rgb(255, 215, 190) },
				size = { 0.2, 0.28, 0.24 },
				alpha = { 0.7, 0.05, 0.15, 1 },
				life = { 0.8, 1.2 },
				speed = { 0.02, 0.05 },
				accel = Vector3.new(0, 0.45, 0),
				rate = 32,
				light = 0.45,
				bright = 1.6,
				tilt = 10,
				z = 0.3,
				flip = true,
			},
			feet = {
				texture = T.Fuego,
				colors = { WHITE },
				size = { 0.18, 0.25, 0.16 },
				alpha = { 0.6, 0.05, 0.2, 1 },
				life = { 0.6, 0.9 },
				speed = { 0.01, 0.03 },
				accel = Vector3.new(0, 0.6, 0),
				rate = 50,
				light = 0.45,
				bright = 1.6,
				tilt = 8,
				z = 0.2,
				flip = true,
			},
			motes = {
				texture = T.Brasa,
				colors = { rgb(255, 235, 160), LAVA, rgb(200, 40, 0) },
				size = { 0.03, 0.022, 0 },
				alpha = { 0, 0.1, 1 },
				life = { 1.4, 2.4 },
				speed = { 0.1, 0.3 },
				accel = Vector3.new(0, 0.35, 0),
				rate = 30,
				light = 1,
				bright = 2,
				spread = 70,
				drag = 0.8,
				z = 0.5,
			},
			glints = {
				texture = T.Chispa,
				colors = { rgb(255, 240, 200), LAVA },
				size = { 0.07, 0 },
				alpha = { 0, 1 },
				life = { 0.4, 0.7 },
				rate = 6,
				light = 1,
				bright = 2,
				spin = { -90, 90 },
				z = 0.6,
			},
			glow = rgb(255, 110, 20),
			ring = { rgb(255, 220, 120), rgb(255, 70, 0) },
			outline = rgb(255, 150, 40),
		})
		-- Volcán de la cabeza: humo y chispas.
		local top = fx.socket("Cabeza", Vector3.new(0, 0.36, 0))
		Aura.add(fx, top, {
			texture = T.Smoke,
			colors = { rgb(70, 60, 58) },
			size = { 0.12, 0.26 },
			alpha = { 0.3, 1 },
			life = { 1.4, 2.4 },
			speed = { 0.25, 0.4 },
			rate = 6,
			spread = 12,
		})
		Aura.add(fx, top, {
			texture = T.Brasa,
			colors = { rgb(255, 220, 120), LAVA },
			size = { 0.025, 0 },
			life = { 0.6, 1.1 },
			speed = { 0.3, 0.55 },
			accel = Vector3.new(0, -0.6, 0),
			rate = 8,
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
				rate = 4,
				light = 1,
				bright = 2,
			})
		end
	end,
}

return style
