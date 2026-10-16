--!strict
--[[
	Dragon/Estelas

	Una estela de aire en la punta de cada ala: aparece cuando el dragón va
	rápido, pica con las alas plegadas o da aletazos fuertes, y se apaga al
	planear despacio. Va de la mano del ala (AlaIzq3 / AlaDer3) a un punto en la
	punta: una cinta fina entre dos huesos nuevos cerca de la punta (BordeAla<lado> y
	PuntaAla<lado>, que siguen la animación). Color
	aguamarina del dragón marino; con efectos reducidos no se ve.
]]

local Tipos = require(script.Parent.Tipos)

export type Estelas = { trails: { Trail }, tips: { Bone }, rig: any }

local INNER, OUTER = 0.72, 0.95 -- dónde va la cinta: fracción del brazo más allá de la mano

local FAST = 28 -- studs/s: desde aquí empieza a verse
local FULL = 55 -- y aquí ya se ve entera
local rgb = Color3.fromRGB

local Estelas = {}

local function trail(hand: Bone, tip: Bone): Trail
	local t = Instance.new("Trail")
	t.Name = "Estela"
	t.Attachment0 = hand
	t.Attachment1 = tip
	t.Color = ColorSequence.new(rgb(200, 255, 250), rgb(60, 200, 210))
	t.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	t.WidthScale = NumberSequence.new(1, 0.1)
	t.LightEmission = 0.7
	t.LightInfluence = 0.2
	t.Lifetime = 0.2
	t.MinLength = 0.05
	t.FaceCamera = false
	t.Enabled = false
	t.Parent = hand
	return t
end

function Estelas.build(rig: any): Estelas?
	local trails, tips = {}, {}
	for _, s in { "Izq", "Der" } do
		local arm, hand = rig.bones[`Ala{s}2`], rig.bones[`Ala{s}3`]
		if arm and hand then
			-- La punta queda más allá de la mano, en la dirección del brazo.
			local reach = hand.WorldPosition - arm.WorldPosition
			local function bone(name: string, k: number): Bone
				local b = Instance.new("Bone")
				b.Name = name
				b.Parent = hand
				b.WorldPosition = hand.WorldPosition + reach * k
				table.insert(tips, b)
				return b
			end
			table.insert(trails, trail(bone(`BordeAla{s}`, INNER), bone(`PuntaAla{s}`, OUTER)))
		end
	end
	return if #trails > 0 then { trails = trails, tips = tips, rig = rig } else nil
end

-- strength: 0..1 cuánto se ve (velocidad, picada, aletazo); 0 o sin efectos: apagadas.
function Estelas.step(e: Estelas, state: Tipos.State, fxScale: number)
	local speed = state.velocity.Magnitude
	local strength = math.max(math.clamp((speed - FAST) / (FULL - FAST), 0, 1), state.fold)
	local on = strength > 0.15 and fxScale > 0 and not state.hidden
	for _, t in e.trails do
		t.Enabled = on
		if on then
			t.Lifetime = 0.1 + 0.16 * strength
		end
	end
end

function Estelas.destroy(e: Estelas)
	for _, t in e.trails do
		t:Destroy()
	end
	for _, tip in e.tips do
		tip:Destroy()
	end
end

return table.freeze(Estelas)
