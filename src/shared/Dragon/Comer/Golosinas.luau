--!strict
--[[
	Dragon/Comer/Golosinas

	Un pez raro (rareza 3 o más, FedInfo.rarity) le gusta más: encima del bocado
	hace una de estas (Dragon/Comer elige por la rareza):
		brillo     raro: dos aletazos de alegría, pecho hinchado, cola arriba
		           enroscada y la cabeza ladeada (treat: chispas del color del pez)
		llamarada  épico: baja la cabeza y mete el pecho (anticipación), la lanza
		           al cielo con la boca abierta y echa una llamarada del color del
		           pez hacia arriba (treatFlare), las alas se abren y vuelve con rebote
		voltereta  legendario y mítico: la llamarada y después una voltereta de
		           alegría sobre su eje con estela (joy). El adulto y el anciano no
		           dan vueltas: abren las alas enormes, suben y bajan de un aletazo
	Ninguna se corta a la mitad (Dragon/Comer espera a que termine para otra).
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Acto = require(script.Parent.Acto)

type Pose = Acto.Pose
type Ctx = Acto.Ctx

-- La cabeza al cielo con la boca abierta: gather (0..1) la junta antes, up la lanza.
local function toSky(gather: number, up: number): Pose
	return {
		neckSnap = -0.15 * gather + 0.55 * up,
		headSnap = -0.2 * gather + 0.65 * up,
		chest = -0.12 * gather + 0.25 * up,
		pitch = -0.05 * gather + 0.16 * up,
		jaw = 1.2 * up,
		spread = 0.45 * up,
		tailUp = 0.4 * up,
	}
end

local brillo: Acto.Act = {
	name = "brillo",
	seconds = 1.3,
	events = { { at = 0.08, kind = "treat" } },
	pose = function(u: number, c: Ctx): Pose
		local joy = C.hold(u, 0.05, 0.25, 0.6, 0.95)
		local span = C.span(u, 0.1, 0.7)
		local flaps = math.sin(span * math.pi * 4) * C.bell(span) -- dos aletazos: arriba, abajo
		return {
			spread = 0.3 * flaps * (0.6 + 0.4 * c.profile.bounce),
			chest = 0.2 * joy,
			tailUp = 0.35 * joy,
			tailCurl = 0.5 * c.side * joy,
			tilt = 0.2 * c.side * joy,
			head = 0.15 * joy,
		}
	end,
}

local llamarada: Acto.Act = {
	name = "llamarada",
	seconds = 1.7,
	events = { { at = 0.05, kind = "treat" }, { at = 0.34, kind = "treatFlare" } },
	pose = function(u: number, _c: Ctx): Pose
		local gather = C.hold(u, 0.04, 0.22, 0.26, 0.33)
		local up = C.overshoot(C.span(u, 0.28, 0.4)) * (1 - C.smooth(C.span(u, 0.68, 0.95)))
		return toSky(gather, up)
	end,
}

local voltereta: Acto.Act = {
	name = "voltereta",
	seconds = 2.6,
	events = {
		{ at = 0.05, kind = "treat" },
		{ at = 0.22, kind = "treatFlare" },
		{ at = 0.5, kind = "whoosh" },
		{ at = 0.5, kind = "joy" },
	},
	pose = function(u: number, c: Ctx): Pose
		local gather = C.hold(u, 0.02, 0.12, 0.15, 0.2)
		local up = C.overshoot(C.span(u, 0.17, 0.27)) * (1 - C.smooth(C.span(u, 0.4, 0.55)))
		local p = toSky(gather, up)
		if c.stage <= 2 then
			local spin = C.span(u, 0.5, 0.86)
			if spin > 0 and spin < 1 then
				p.roll = math.pi * 2 * C.smooth(spin)
			end
			p.fold = 0.3 * C.bell(spin)
			p.rise = 0.06 * C.bell(spin)
			p.tailUp += 0.25 * C.bell(spin)
		else
			local wide = C.hold(u, 0.48, 0.6, 0.8, 0.97)
			p.spread += 0.85 * wide - 0.45 * C.bell(C.span(u, 0.8, 0.95))
			p.rise = 0.05 * wide
			p.neck = 0.2 * wide
			p.chest += 0.2 * wide
		end
		return p
	end,
}

local Golosinas = {}

-- La golosina de un pez de esta rareza (nil si es común o poco común).
function Golosinas.forRarity(rarity: number): Acto.Act?
	if rarity >= 5 then
		return voltereta
	elseif rarity == 4 then
		return llamarada
	elseif rarity == 3 then
		return brillo
	end
	return nil
end

return table.freeze(Golosinas)
