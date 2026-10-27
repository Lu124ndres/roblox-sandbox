--!strict
--[[
	LairPerches

	Con el hábitat completo de Blender las mallas de los peñones no chocan:
	por cada roca de Dragon/Guarida queda un cilindro invisible que sí choca,
	de radio `size` y con la cima justo en Guarida.point() (como el núcleo de
	las rocas de primitivas, LairRocks), para que se puedan pisar. LavaLair
	los pone solo con el hábitat completo y LairLift los sube y hunde con la
	lava, como las rocas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairParts = require(script.Parent.LairParts)

local BELOW = 14 -- studs que el cilindro sigue bajo la lava (como LairRocks)

local LairPerches = {}

function LairPerches.build(parent: Instance)
	local base = Guarida.lava - BELOW
	for k, perch in Guarida.perches do
		local top = Guarida.point(perch)
		local pillar = LairParts.column(
			parent,
			Vector3.new(top.X, base, top.Z),
			top.Y - base,
			perch.size,
			Color3.new(),
			{ collide = true, transparency = 1 }
		)
		pillar.Name = `Apoyo{k}`
		pillar.CastShadow = false
	end
end

return table.freeze(LairPerches)
