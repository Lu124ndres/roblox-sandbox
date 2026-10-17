--!strict
--[[
	GroundFx

	El golpe en el fondo del cráter según lo que haya (Ambient/CraterMode):
	en el desierto del minotauro levanta arena (Effects/SandFx); en el agua
	salpica como siempre (Fx). Lo usan los efectos que no son del minotauro
	mismo: los peces que come, la llegada y la despedida, los ataques.
		splash(posición, tamaño)          salpicadura chica / polvo
		impact(posición, tamaño, radio)   golpe grande con su sonido y onda
]]

local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Fx)
local SandFx = require(script.Parent.SandFx)

local GroundFx = {}

function GroundFx.splash(position: Vector3, size: number)
	if CraterMode.isSand() then
		SandFx.puff(position, size)
	else
		Fx.splash(position, size)
	end
end

function GroundFx.impact(position: Vector3, size: number, radius: number)
	if CraterMode.isSand() then
		Sounds.play("MinoSandHit", position)
		SandFx.slam(position, size, radius)
	else
		Sounds.play("BigSplash", position)
		Fx.splash(position, size)
		Fx.ring(position, radius, 1.2)
	end
end

return table.freeze(GroundFx)
