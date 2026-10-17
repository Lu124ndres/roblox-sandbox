--!strict
--[[
	Minotauro/Posturas

	Lo que el minotauro hace en su rutina (Minotauro/Rutina), una postura por
	módulo, con los principios de docs/estilo_modelos.md (anticipación, peso,
	arcos, rebote; orejas, cola y faldón los mueve Resortes):
		sentarse      se deja caer sentado, hace dos cosas sentado y se para
		olfatear      baja la cabeza al suelo, olfatea y resopla
		estirarse     se estira de pie con un bostezo
		mirarCielo    mira al cielo
		mirarJugador  se da vuelta hacia alguien, ladea la cabeza y resopla
		truco         uno de los trucos de su etapa (Minotauro/Trucos)
	La forma de cada una está en Posturas/Tipos.
]]

local Players = game:GetService("Players")

local Azar = require(script.Parent.Azar)
local Etapas = require(script.Parent.Etapas)
local Pose = require(script.Parent.Pose)
local Trucos = require(script.Parent.Trucos)
local Mirar = require(script.Mirar)
local Tipos = require(script.Tipos)

export type Behavior = Tipos.Behavior
export type Ctx = Tipos.Ctx
export type Event = Tipos.Event
export type Leave = Tipos.Leave

local POSTURAS: { [string]: Behavior } = {
	sentarse = require(script.Sentarse),
	olfatear = require(script.Olfatear),
	estirarse = require(script.Estirarse),
	mirarCielo = Mirar.cielo,
	mirarJugador = Mirar.jugador,
}

-- Los trucos con la forma de una postura (se arman una vez).
local fromTrick: { [string]: Behavior } = {}
local function asBehavior(trick: Trucos.Trick): Behavior
	local behavior = fromTrick[trick.name]
	if not behavior then
		behavior = table.freeze({
			name = trick.name,
			seconds = trick.seconds,
			events = function(_ctx: Ctx): { Event }
				return trick.events
			end,
			pose = function(u: number, _ctx: Ctx): Pose.Pose
				return trick.pose(u)
			end,
		})
		fromTrick[trick.name] = behavior
	end
	return behavior
end

local Posturas = {}

-- La postura que pide la rutina; "truco" elige uno de la etapa con la semilla.
function Posturas.pick(name: string, profile: Etapas.Profile, seed: number): Behavior?
	if name == "truco" then
		local tricks = profile.tricks
		local trick = Trucos.get(tricks[Azar.pick(#tricks, seed, 7)])
		return if trick then asBehavior(trick) else nil
	end
	return POSTURAS[name]
end

-- A quién mira mirarJugador: uno de los jugadores con personaje, elegido con la
-- semilla en la lista ordenada por UserId (la misma en todos los clientes). Devuelve
-- hacia dónde está desde `from`, en el plano, o nil si no hay nadie (o está encima).
function Posturas.lookAt(seed: number, from: Vector3): Vector3?
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(list, { id = player.UserId, at = root.Position })
		end
	end
	if #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	local at = list[Azar.pick(#list, seed, 11)].at
	local flat = Vector3.new(at.X - from.X, 0, at.Z - from.Z)
	return if flat.Magnitude > 1 then flat else nil
end

return table.freeze(Posturas)
