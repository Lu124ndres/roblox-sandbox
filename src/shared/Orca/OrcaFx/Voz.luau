--!strict
--[[
	OrcaFx/Voz

	Llamado y resoplido de la orca según su edad (sale del alto, como el
	resto de sus efectos):
		cría (etapas 1 y 2)  chillidos de delfín, agudos y rápidos: una cría de
		                     orca chilla, no canta
		adulta (3)           llamado de ballena bajo el agua
		anciana (4)          el mismo llamado más grave; en los momentos grandes
		                     (rugido, canto) suma un canto largo y hondo debajo
	El resoplido del espiráculo es un chorro de aire y agua a presión encima del
	chapoteo de siempre: más grave cuanto más grande.
]]

local GiantStages = require(script.Parent.Parent.Parent.GiantStages)

type Play = (key: string, position: Vector3?, pitch: number?, volume: number?) -> ()

local NEAR = 0.95 -- ya cuenta como de esa etapa al llegar al 95 % de su alto

local Voz = {}

function Voz.stage(height: number): number
	local stage = 1
	for s = 2, GiantStages.count do
		if height >= GiantStages.heightFor(s) * NEAR then
			stage = s
		end
	end
	return stage
end

-- deep = momento grande: la anciana suma el canto hondo.
function Voz.call(
	play: Play,
	position: Vector3,
	height: number,
	voice: number,
	volume: number?,
	deep: boolean?
)
	local stage = Voz.stage(height)
	local v = volume or 1
	if stage <= 2 then
		play("OrcaCalfSqueak", position, math.clamp(voice, 0.9, 1.25), v)
		return
	end
	play("OrcaCall", position, voice, v)
	if deep and stage >= GiantStages.count then
		play("OrcaCallDeep", position, voice * 0.85, 0.7 * v)
	end
end

function Voz.blow(play: Play, position: Vector3, pitch: number)
	play("OrcaBlow", position, pitch, 0.8)
	play("Spout", position, pitch, 0.6)
end

return table.freeze(Voz)
