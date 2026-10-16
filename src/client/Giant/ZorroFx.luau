--!strict
--[[
	ZorroFx

	Los efectos que van pegados al zorro de agua (en sus huesos) y los fuegos fatuos:
		gema      la gema de la frente late con una luz cian
		bruma     las puntas de las colas sueltan bruma de agua (más con las colas
		          abiertas: abanico, aullido)
		pisadas   cada pata que pisa el agua deja una onda
		fuegos    orbes de agua que brillan, suben en espiral alrededor del zorro y
		          se apagan (el truco "fuegos" y su ataque se llaman Fuegos fatuos)
	La cantidad sigue el modo de efectos reducidos (fxScale = 0 no emite).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Zorro = require(ReplicatedStorage.Shared.Zorro)
local Fx = require(script.Parent.Parent.Effects.Fx)

local CYAN = Color3.fromRGB(110, 255, 240)
local FOAM = Color3.fromRGB(225, 250, 255)
local BASE_HEIGHT = 16 -- alto de referencia: tamaño 1 de los efectos
local ORB_SECONDS = 3.2
local PAWS = { "ManoIzq", "ManoDer", "PieIzq", "PieDer" }

export type Orb = { part: Part, born: number, angle: number, radius: number, rise: number }
export type ZorroFx = {
	rig: any,
	light: PointLight?,
	mists: { ParticleEmitter },
	orbs: { Orb },
	folder: Folder,
	nextPaw: number,
}

local ZorroFx = {}

local function mist(parent: Instance): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Name = "Bruma"
	p.Texture = Assets.Particles.Mist
	p.Color = ColorSequence.new(FOAM, CYAN)
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.LightEmission = 0.5
	p.Lifetime = NumberRange.new(1, 1.6)
	p.SpreadAngle = Vector2.new(60, 60)
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-40, 40)
	p.Rate = 0
	p.Parent = parent
	return p
end

function ZorroFx.attach(rig: any): ZorroFx
	local folder = Instance.new("Folder")
	folder.Name = "FuegosFatuos"
	folder.Parent = Workspace
	local light: PointLight? = nil
	local head = rig.bones.Cabeza
	if head then
		local l = Instance.new("PointLight")
		l.Name = "LuzGema"
		l.Color = CYAN
		l.Shadows = false
		l.Parent = head
		light = l
	end
	local mists = {}
	for _, tail in rig.tails do
		local tip = rig.bones[`{tail.prefix}4`]
		if tip then
			table.insert(mists, mist(tip))
		end
	end
	return { rig = rig, light = light, mists = mists, orbs = {}, folder = folder, nextPaw = 0 }
end

-- Lanza `count` orbes alrededor del zorro.
function ZorroFx.orbs(fx: ZorroFx, motion: Zorro.Motion, count: number)
	local state = motion.state
	for _ = 1, count do
		local orb = Instance.new("Part")
		orb.Name = "FuegoFatuo"
		orb.Shape = Enum.PartType.Ball
		orb.Material = Enum.Material.Neon
		orb.Color = CYAN
		orb.Transparency = 0.15
		orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = true, false, false, false
		orb.CastShadow = false
		local size = state.height * (0.05 + math.random() * 0.03)
		orb.Size = Vector3.one * size
		local glow = Instance.new("PointLight")
		glow.Color = CYAN
		glow.Range = size * 5
		glow.Brightness = 2
		glow.Parent = orb
		orb.Parent = fx.folder
		table.insert(fx.orbs, {
			part = orb,
			born = os.clock(),
			angle = math.random() * math.pi * 2,
			radius = state.height * (0.55 + math.random() * 0.45),
			rise = state.height * (0.7 + math.random() * 0.6),
		})
	end
end

-- Cada cuadro: luz de la gema, bruma de las colas, ondas de las pisadas, orbes.
function ZorroFx.update(fx: ZorroFx, motion: Zorro.Motion, fxScale: number, visible: boolean)
	local state = motion.state
	local s = state.height / BASE_HEIGHT
	local rate = if visible then fxScale else 0
	if fx.light then
		fx.light.Range = math.clamp(state.height * 0.5, 8, 60)
		fx.light.Brightness = (1.2 + 0.6 * math.sin(os.clock() * 2.4) + 2 * state.fan)
			* (if visible then 1 else 0)
	end
	for _, m in fx.mists do
		m.Size = NumberSequence.new(0.6 * s, 1.8 * s)
		m.Speed = NumberRange.new(0.5 * s, 1.5 * s)
		m.Rate = (1.2 + 6 * state.fan) * rate
	end
	-- Pisadas: una onda donde pisó; y cada tanto, una suave bajo una pata quieta.
	local water = motion.water()
	if rate > 0 and (state.stepped > 0 or os.clock() > fx.nextPaw) then
		fx.nextPaw = os.clock() + 2.2 + math.random() * 1.5
		local paw = PAWS[math.random(#PAWS)]
		local at = motion.point(paw)
		if at then
			Fx.ring(Vector3.new(at.X, water.Y, at.Z), state.height * 0.12, 1.4)
		end
	end
	local now = os.clock()
	for i = #fx.orbs, 1, -1 do
		local orb = fx.orbs[i]
		local u = (now - orb.born) / ORB_SECONDS
		if u >= 1 then
			orb.part:Destroy()
			table.remove(fx.orbs, i)
		else
			local a = orb.angle + u * math.pi * 1.6
			local r = orb.radius * (1 - 0.3 * u)
			orb.part.Position = state.center
				+ Vector3.new(math.cos(a) * r, orb.rise * u + state.height * 0.2, math.sin(a) * r)
			orb.part.Transparency = 0.15 + 0.85 * math.max(0, (u - 0.7) / 0.3)
		end
	end
end

function ZorroFx.destroy(fx: ZorroFx)
	fx.folder:Destroy()
	if fx.light then
		fx.light:Destroy()
	end
	for _, m in fx.mists do
		m:Destroy()
	end
end

return table.freeze(ZorroFx)
