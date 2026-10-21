--!strict
--[[
	OrcaFx/Remolinos

	Una estela de agua en la punta de cada aleta de la cola (AletaColaIzq /
	AletaColaDer, solo en los modelos con esos huesos): dibuja el barrido de la
	cola cuando nada rápido bajo el agua y se apaga al planear, al salir del
	agua o con efectos reducidos. La punta es un hueso nuevo (PuntaCola<lado>)
	que sigue la animación.
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local Rig = require(script.Parent.Parent.OrcaMotion.Rig)

export type Remolinos = { trails: { Trail }, tips: { Bone }, rig: Rig.Rig }

local WATER = WorldLayout.waterLevel
local SLOW = 0.6 -- velocidad (en altos del modelo por segundo) desde la que se ve

local Remolinos = {}

function Remolinos.attach(rig: Rig.Rig, color: Color3): Remolinos?
	local trails, tips = {}, {}
	for _, s in { "Izq", "Der" } do
		local root = rig.bones[`AletaCola{s}`]
		local base = rig.bones.Cola5 or rig.bones.Cola4
		if root and base then
			-- La punta: siguiendo la aleta desde la base de la cola hacia afuera.
			local reach = root.WorldPosition - base.WorldPosition
			local tip = Instance.new("Bone")
			tip.Name = `PuntaCola{s}`
			tip.WorldPosition = root.WorldPosition + reach * 0.8
			tip.Parent = root
			local t = Instance.new("Trail")
			t.Name = "Remolino"
			t.Attachment0, t.Attachment1 = root, tip
			t.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
			t.Transparency = NumberSequence.new(0.55, 1)
			t.WidthScale = NumberSequence.new(1, 0.2)
			t.LightEmission = 0.5
			t.Lifetime = 0.45
			t.MinLength = 0.05
			t.Enabled = false
			t.Parent = root
			table.insert(tips, tip)
			table.insert(trails, t)
		end
	end
	return if #trails > 0 then { trails = trails, tips = tips, rig = rig } else nil
end

-- speed: studs/s en el plano; height: alto del modelo.
function Remolinos.update(
	r: Remolinos,
	speed: number,
	height: number,
	fxScale: number,
	visible: boolean
)
	local tail = (Rig.point(r.rig, "Cola5") or Rig.point(r.rig, "Cola4"))
	local under = tail ~= nil and tail.Y < WATER - height * 0.05
	local on = visible and under and fxScale > 0 and speed > SLOW * height
	for _, t in r.trails do
		t.Enabled = on
	end
end

function Remolinos.destroy(r: Remolinos)
	for _, t in r.trails do
		t:Destroy()
	end
	for _, tip in r.tips do
		tip:Destroy()
	end
end

return table.freeze(Remolinos)
