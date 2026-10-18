--!strict
--[[
	Zorro/Comer/Cria

	El bocado propio de la cría (etapa 1): salta torpe por el pez y se le escapa.
		torpe   se agacha apurada y salta con la boca abierta; el mordisco se
		        cierra en el aire (se le escapó: sorpresa), cae desparramada con
		        una pata adelante y las orejas cada una por su lado, busca el pez
		        en el agua con la cabeza ladeada, se tira en picada encima y lo
		        atrapa; traga contenta y menea la cola
	u = 0 es cuando el pez llega a la boca. Como todo bocado, entra y sale por el
	reposo. Comer/Elegir la usa solo después de una pausa (si los peces llegan
	seguidos, el próximo la fundiría antes de que la termine).
	Eventos: hop, bite (el mordisco al aire), hopLand, splash, pounce, bite
	(ahora sí), gulp y yip.
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

local span, bell, hold, arc = Curvas.span, Curvas.bell, Curvas.hold, Curvas.arc

local function torpe(u: number, ctx: Clip.Ctx): Pose.Pose
	local s = ctx.side
	local load = bell(span(u, 0, 0.16)) -- se agacha apurada
	local air = arc(span(u, 0.14, 0.42))
	local miss = hold(u, 0.28, 0.32, 0.46, 0.56) -- ¿y el pez?
	local sprawl = bell(span(u, 0.4, 0.6)) -- cae desparramada
	local search = hold(u, 0.46, 0.54, 0.62, 0.68) -- lo busca en el agua
	local dive = arc(span(u, 0.64, 0.8)) -- la picada
	local happy = hold(u, 0.8, 0.86, 0.94, 1)
	local toss = bell(span(u, 0.8, 0.95))
	-- Boca: abierta al saltar, se cierra en el aire, abierta en la picada, cerrada
	-- con el pez y entreabierta al tragar.
	local jaw = 0.5 * hold(u, 0, 0.06, 0.26, 0.29)
		- 0.5 * hold(u, 0.29, 0.31, 0.4, 0.5)
		+ 0.55 * hold(u, 0.6, 0.66, 0.76, 0.78)
		- 0.6 * hold(u, 0.78, 0.8, 0.84, 0.87)
		+ 0.25 * bell(span(u, 0.86, 0.94))
	local p: Pose.Pose = {
		take = 0.9 * hold(u, 0, 0.08, 0.9, 1),
		jaw = jaw,
		dy = 1.1 * ctx.lift * air + 0.45 * ctx.lift * dive,
		crouch = 0.55 * load - 0.3 * air + 0.5 * sprawl + 0.45 * search - 0.2 * dive,
		pounce = 0.9 * dive,
		lean = -0.08 * load + 0.1 * air - 0.12 * sprawl - 0.1 * search,
		sway = 0.12 * s * sprawl,
		tilt = 0.3 * s * sprawl + 0.25 * s * search + 0.12 * s * toss,
		lookPitch = 0.25 * air - 0.42 * search - 0.3 * dive + 0.4 * toss,
		lookYaw = 0.22 * s * search + 0.18 * s * miss,
		-- En el aire una pata manotea más que la otra; al caer, una delantera adelante.
		stepFL = (if s > 0 then 0.9 else 0.45) * air + (if s > 0 then 0.5 else 0) * sprawl,
		stepFR = (if s > 0 then 0.45 else 0.9) * air + (if s > 0 then 0 else 0.5) * sprawl,
		stepHL = 0.4 * air,
		stepHR = 0.4 * air,
		earL = -0.3 * air + (if s > 0 then -0.45 else 0.35) * sprawl + 0.4 * happy,
		earR = -0.3 * air + (if s > 0 then 0.35 else -0.45) * sprawl + 0.4 * happy,
		earTipL = 0.6 * sprawl * s,
		earTipR = -0.4 * sprawl * s,
		emoSorpresa = miss,
		emoFeliz = happy,
		blink = bell(span(u, 0.42, 0.47)), -- el golpe de la caída
		tailWag = 0.5 * air + 1.1 * happy,
		tailLift = 0.25 * air - 0.2 * sprawl + 0.3 * happy,
		tailGusto = 0.8 * happy,
	}
	return Clip.mix(p, Clip.mira(u, 0.3, 0.78))
end

return table.freeze({
	torpe = {
		name = "torpe",
		seconds = 1.9,
		events = {
			{ at = 0.15, kind = "hop" },
			{ at = 0.29, kind = "bite" },
			{ at = 0.42, kind = "hopLand" },
			{ at = 0.43, kind = "splash" },
			{ at = 0.64, kind = "pounce" },
			{ at = 0.78, kind = "bite" },
			{ at = 0.79, kind = "splash" },
			{ at = 0.86, kind = "gulp" },
			{ at = 0.93, kind = "yip" },
		},
		pose = torpe,
	} :: Clip.Clip,
})
