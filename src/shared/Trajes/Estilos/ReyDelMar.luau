--!strict
--[[
	Trajes/Estilos/ReyDelMar

	Majestuoso: camina derecho, con poco vaivén de brazos, la barbilla en
	alto y mirando despacio su reino. En la vitrina posa de héroe: puño al
	cielo, la otra mano adelante y un paso al frente.
	Efectos: aura del mar (Trajes/Aura) más suave que antes (el traje tiene
	mucho detalle y no se tapa), luz suave de agua en la gema del pecho,
	destellos en la visera, la corona y los cristales de las hombreras, el
	brillo de las gemas que titila y ondas de agua en cada pisada
	(Trajes/Huellas). Sin capa: chocaba con la canasta de la espalda.
	Puntos en altos del traje, medidos en el modelo (tools/blender/traje_v2_rey_del_mar*.py).
]]

local Tipos = require(script.Parent.Parent.Tipos)

local Aura = require(script.Parent.Parent.Aura)
local Huellas = require(script.Parent.Parent.Huellas)
local Particulas = require(script.Parent.Parent.Particulas)

local T = Particulas.Textures
local rgb = Color3.fromRGB
local WATER = rgb(110, 220, 255)
local GEM = rgb(60, 225, 255)

local VISOR = Vector3.new(0, 0.112, -0.108) -- desde Cabeza: la ranura en T
local CROWN_GEM = Vector3.new(0, 0.248, -0.106) -- desde Cabeza: la gema de la aguja
local CHEST_GEM = Vector3.new(0, 0.15, -0.106) -- desde Pecho
local CRYSTALS = Vector3.new(0.15, 0.123, -0.042) -- desde cada Brazo (x según el lado)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local function sparkle(fx: Tipos.Fx, parent: Instance?, rate: number, size: number)
	Aura.add(fx, parent, {
		texture = T.Chispa,
		colors = { rgb(255, 255, 255), GEM },
		size = { size, 0 },
		alpha = { 0, 1 },
		life = { 0.4, 0.8 },
		rate = rate,
		light = 1,
		bright = 2.5,
		spin = { -120, 120 },
		spread = 180,
		speed = { 0, 0.02 },
	})
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
		-- Vitrina: pose de héroe fija (puño al cielo, la otra mano adelante, un paso al
		-- frente) que respira y llama al mar con el puño cada tanto.
		local w = pulse(now, 6, 2.2)
		local breath = 0.03 * math.sin(now * 1.6)
		pose.Pecho = CFrame.Angles(0.06 + breath, 0, 0)
		pose.Cabeza = CFrame.Angles(0.22 + 0.08 * w, -0.1, 0)
		pose.BrazoDer = CFrame.Angles(2.75 + 0.15 * w, 0, 0.3)
		pose.CodoDer = CFrame.Angles(0.35 - 0.3 * w, 0, 0)
		pose.BrazoIzq = CFrame.Angles(0.75 + breath, 0, -0.55)
		pose.CodoIzq = CFrame.Angles(0.25, 0, 0)
		pose.PiernaIzq = CFrame.Angles(0.32, 0, -0.05)
		pose.RodillaIzq = CFrame.Angles(-0.3, 0, 0)
		pose.PiernaDer = CFrame.Angles(-0.22, 0, 0.05)
		return pose
	end,
	effects = function(fx: Tipos.Fx): Tipos.Tick?
		local h = fx.height
		Aura.build(fx, {
			tongues = {
				texture = T.Agua,
				colors = { rgb(255, 255, 255), rgb(190, 240, 255) },
				size = { 0.24, 0.3 },
				alpha = { 0.7, 0.2, 0.35, 1 },
				life = { 0.9, 1.3 },
				rate = 7,
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
				rate = 30,
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
				rate = 14,
				light = 0.3,
				spread = 30,
				drag = 0.5,
				z = 0.4,
			},
			glints = {
				texture = T.Chispa,
				colors = { rgb(255, 255, 255), WATER },
				size = { 0.07, 0 },
				alpha = { 0, 1 },
				life = { 0.5, 0.9 },
				rate = 8,
				light = 1,
				bright = 2,
				spin = { -90, 90 },
				z = 0.6,
			},
			glow = rgb(30, 160, 255),
			ring = { rgb(200, 250, 255), rgb(0, 140, 255) },
			outline = rgb(120, 230, 255),
		})
		local visor = fx.socket("Cabeza", VISOR)
		sparkle(fx, visor, 2, 0.05)
		sparkle(fx, fx.socket("Cabeza", CROWN_GEM), 4, 0.07)
		local chest = fx.socket("Pecho", CHEST_GEM)
		local chestLight = Aura.light(chest, GEM, 0.5, 0.7, h) -- suave: más fuerte lava el traje
		sparkle(fx, chest, 3, 0.07)
		for _, side in { -1, 1 } do
			local name = if side < 0 then "BrazoIzq" else "BrazoDer"
			sparkle(fx, fx.socket(name, CRYSTALS * Vector3.new(side, 1, 1)), 3, 0.06)
		end
		local steps = Huellas.new(fx, {
			kind = "agua",
			color = rgb(150, 235, 255),
			fade = rgb(40, 140, 220),
			size = Vector3.new(0.12, 0.004, 0.12),
			life = 1.1,
		})
		local glow = Aura.glow(fx)
		return function(ctx: Tipos.Context)
			steps(ctx)
			local shimmer = math.sin(ctx.now * 2.3)
			glow(1.3 + 0.45 * shimmer)
			if chestLight then
				chestLight.Brightness = 0.5 + 0.2 * shimmer
			end
		end
	end,
}

return style
