--!strict
--[[
	Trajes/Estilos/ReyDelMar

	Majestuoso: camina derecho, con poco vaivén de brazos, la barbilla en
	alto y mirando despacio su reino. En la vitrina alza el tridente.
	Efectos: aura del mar (Trajes/Aura) y el tridente brilla y gotea.
]]

local Tipos = require(script.Parent.Parent.Tipos)

local Aura = require(script.Parent.Parent.Aura)
local Particulas = require(script.Parent.Parent.Particulas)

local T = Particulas.Textures
local rgb = Color3.fromRGB
local WATER = rgb(110, 220, 255)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local style: Tipos.Style = {
	arms = 0.75,
	legs = 0.9,
	pose = function(ctx: Tipos.Context): { [string]: CFrame }
		local now = ctx.now
		local still = math.clamp(1 - ctx.speed / 8, 0, 1)
		local pose = {
			Pecho = CFrame.Angles(0.03 + 0.02 * math.sin(now * 1.3), 0, 0),
			Cabeza = CFrame.Angles(0.07, 0.28 * math.sin(now * 0.33) * still, 0),
		}
		if not ctx.display then
			return pose
		end
		local w = pulse(now, 7, 2.8)
		if w > 0 then -- alza el tridente
			pose.BrazoDer = CFrame.Angles(2.3 * w, 0, 0.25 * w)
			pose.BrazoIzq = CFrame.Angles(0, 0, -0.35 * w)
			pose.Cabeza = CFrame.Angles(0.07 + 0.22 * w, 0, 0)
		end
		return pose
	end,
	effects = function(fx: Tipos.Fx)
		local h = fx.height
		-- Aura del mar: medialunas de agua que giran por todo el cuerpo,
		-- fuentecitas a sus pies, burbujas, destellos, halo y onda en el piso.
		Aura.build(fx, {
			tongues = {
				texture = T.Agua,
				colors = { rgb(255, 255, 255), rgb(190, 240, 255) },
				size = { 0.3, 0.38 },
				alpha = { 0.6, 0.05, 0.2, 1 },
				life = { 0.9, 1.3 },
				rate = 16,
				light = 0.55,
				bright = 1.5,
				spin = { 150, 260 },
				locked = true,
				z = 0.3,
				flip = true,
			},
			feet = {
				texture = T.Brasa,
				colors = { rgb(225, 250, 255), rgb(60, 170, 255) },
				size = { 0.028, 0.012 },
				alpha = { 0, 0.2, 1 },
				life = { 0.5, 0.9 },
				speed = { 0.15, 0.3 },
				accel = Vector3.new(0, -0.6, 0),
				rate = 40,
				light = 0.8,
				bright = 1.5,
				spread = 15,
				z = 0.2,
			},
			motes = {
				texture = T.Burbuja,
				colors = { rgb(200, 245, 255) },
				size = { 0.035, 0.055 },
				alpha = { 0.5, 0.2, 1 },
				life = { 1.4, 2.4 },
				speed = { 0.04, 0.12 },
				accel = Vector3.new(0, 0.3, 0),
				rate = 18,
				light = 0.3,
				spread = 30,
				drag = 0.5,
				z = 0.4,
			},
			glints = {
				texture = T.Chispa,
				colors = { rgb(255, 255, 255), WATER },
				size = { 0.08, 0 },
				alpha = { 0, 1 },
				life = { 0.5, 0.9 },
				rate = 10,
				light = 1,
				bright = 2,
				spin = { -90, 90 },
				z = 0.6,
			},
			glow = rgb(30, 160, 255),
			ring = { rgb(200, 250, 255), rgb(0, 140, 255) },
			outline = rgb(120, 230, 255),
		})
		-- Tridente: brilla y gotea.
		local tip = fx.socket("ManoDer", Vector3.new(0.08, 0.47, -0.15))
		if tip then
			local light = Instance.new("PointLight")
			light.Color = WATER
			light.Brightness = 2.5
			light.Range = 1.8 * h
			light.Parent = tip
		end
		Aura.add(fx, tip, {
			texture = T.Chispa,
			colors = { rgb(230, 250, 255), WATER },
			size = { 0.06, 0 },
			alpha = { 0, 1 },
			life = { 0.6, 1.2 },
			speed = { 0, 0.06 },
			accel = Vector3.new(0, -0.7, 0),
			rate = 8,
			light = 1,
			bright = 2,
			spin = { -120, 120 },
			spread = 180,
		})
	end,
}

return style
