--!strict
--[[
	Trajes/Estilos/DiosDelVolcan

	Pesado y amenazante: brazos y piernas con menos vaivén, el cuerpo se
	inclina hacia adelante al caminar, respira hondo y mira despacio a los
	lados. En la vitrina posa con los brazos abiertos y los puños arriba, y
	ruge cada tanto.
	Efectos: la lava del cuerpo respira (el brillo propio del traje sube y
	baja con el corazón), sello de magma a sus pies (charco, aro de runas,
	onda de choque y brasas), pisadas de lava que se enfrían (Trajes/Huellas),
	brasas y llamitas en las puntas de los cuernos y las hombreras, gotas de
	lava que caen de las hombreras y los puños, humo de la corona, una luz
	suave en el corazón que late con él, halo y contorno de lava.
	Puntos en altos del traje, medidos en el modelo (tools/blender/traje_v2_dios_del_volcan*.py).
]]

local Tipos = require(script.Parent.Parent.Tipos)

local Aura = require(script.Parent.Parent.Aura)
local Huellas = require(script.Parent.Parent.Huellas)
local Particulas = require(script.Parent.Parent.Particulas)
local Sello = require(script.Parent.Parent.Sello)

local T = Particulas.Textures
local rgb = Color3.fromRGB
local LAVA = rgb(255, 120, 30)
local WHITE = rgb(255, 255, 255)

local CROWN = Vector3.new(0, 0.279, 0.01) -- desde Cabeza: la púa del medio
local HORN = Vector3.new(0.281, 0.346, 0.003) -- desde Cabeza: punta del cuerno (x según el lado)
local HEART = Vector3.new(0, 0.161, -0.113) -- desde Pecho: el corazón de cristal
local SPIKES = Vector3.new(0.142, 0.131, 0) -- desde cada Brazo: las púas de la hombrera
local DRIP = Vector3.new(0.175, -0.078, 0.064) -- desde cada Brazo: las gotas (y según el lado)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local function embers(fx: Tipos.Fx, parent: Instance?, rate: number, fall: boolean)
	Aura.add(fx, parent, {
		texture = T.Brasa,
		colors = { rgb(255, 220, 120), LAVA },
		size = { 0.022, 0 },
		life = { 0.6, 1.1 },
		speed = if fall then { 0, 0.04 } else { 0.25, 0.5 },
		accel = Vector3.new(0, if fall then -1.2 else -0.5, 0),
		rate = rate,
		light = 1,
		bright = 2,
		spread = if fall then 0 else 25,
	})
end

local function flame(fx: Tipos.Fx, parent: Instance?, size: number)
	Aura.add(fx, parent, {
		texture = T.Fuego,
		colors = { WHITE, rgb(255, 215, 190) },
		size = { size * 0.7, size, size * 0.5 },
		alpha = { 0.55, 0.1, 0.3, 1 },
		life = { 0.45, 0.7 },
		speed = { 0.1, 0.18 },
		accel = Vector3.new(0, 0.25, 0),
		rate = 8,
		light = 0.45,
		bright = 1.6,
		tilt = 8,
		spread = 10,
		flip = true,
	})
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
		-- Vitrina: pose de poder fija (brazos abiertos con los puños arriba, piernas
		-- firmes, cabeza baja) que respira hondo y ruge cada tanto.
		local w = pulse(now, 7, 2.6)
		local breath = 0.04 * math.sin(now * 1.2)
		pose.Pecho = CFrame.Angles(-0.08 + breath + 0.12 * w, 0, 0)
		pose.Cabeza = CFrame.Angles(-0.12 + 0.42 * w + 0.03 * math.sin(now * 30) * w, 0, 0)
		pose.BrazoIzq = CFrame.Angles(0.15, 0, -1.25 - 0.2 * w)
		pose.BrazoDer = CFrame.Angles(0.15, 0, 1.25 + 0.2 * w)
		pose.CodoIzq = CFrame.Angles(0, 0, -1.2 - 0.3 * w)
		pose.CodoDer = CFrame.Angles(0, 0, 1.2 + 0.3 * w)
		pose.PiernaIzq = CFrame.Angles(0, 0, -0.16)
		pose.PiernaDer = CFrame.Angles(0, 0, 0.16)
		return pose
	end,
	effects = function(fx: Tipos.Fx): Tipos.Tick?
		local h = fx.height
		Sello.build(fx) -- charco, runas, onda de choque, brasas, halo y contorno
		local crown = fx.socket("Cabeza", CROWN)
		Aura.add(fx, crown, {
			texture = T.Smoke,
			colors = { rgb(70, 60, 58) },
			size = { 0.1, 0.22 },
			alpha = { 0.4, 1 },
			life = { 1.4, 2.2 },
			speed = { 0.25, 0.4 },
			rate = 3,
			spread = 10,
		})
		embers(fx, crown, 3, false)
		local heart = fx.socket("Pecho", HEART)
		local heartLight = Aura.light(heart, LAVA, 0.6, 0.9, h) -- suave: más fuerte lava el traje
		for _, side in { -1, 1 } do
			local arm = if side < 0 then "Izq" else "Der"
			local tip = fx.socket("Cabeza", HORN * Vector3.new(side, 1, 1))
			flame(fx, tip, 0.06)
			embers(fx, tip, 3, false)
			flame(fx, fx.socket("Brazo" .. arm, SPIKES * Vector3.new(side, 1, 1)), 0.09)
			for _, front in { -1, 1 } do
				embers(fx, fx.socket("Brazo" .. arm, DRIP * Vector3.new(side, 1, front)), 2, true)
			end
			embers(fx, fx.socket("Mano" .. arm, Vector3.new(0, -0.03, 0)), 3, true)
		end
		local steps = Huellas.new(fx, {
			kind = "lava",
			color = rgb(255, 150, 40),
			fade = rgb(40, 30, 30),
			size = Vector3.new(0.13, 0.006, 0.17),
			life = 2.6,
		})
		local glow = Aura.glow(fx)
		return function(ctx: Tipos.Context)
			steps(ctx)
			-- El corazón late (dos golpes y pausa) y la lava del cuerpo respira con él.
			local t = ctx.now % 1.6
			local beat = math.exp(-((t - 0.2) / 0.08) ^ 2) + 0.6 * math.exp(-((t - 0.5) / 0.08) ^ 2)
			glow(0.75 + 0.25 * math.sin(ctx.now * 1.4) + 0.5 * beat)
			if heartLight then
				heartLight.Brightness = 0.6 + 1.2 * beat
			end
		end
	end,
}

return style
