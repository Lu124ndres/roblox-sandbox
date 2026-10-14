--!strict
-- Prueba temporal: posiciones de cámara de cada escena del tráiler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local CENTER = WorldZones.craterCenter
local Camara = {}

-- t = segundos desde que empezó la escena; root = HumanoidRootPart del jugador.
function Camara.para(escena: number, t: number, root: BasePart): CFrame?
	local p, cf = root.Position, root.CFrame
	if escena == 1 then
		local from = (cf * CFrame.new(-7 + t * 0.25, 3.2, 8)).Position
		return CFrame.lookAt(from, p + cf.LookVector * 14 + Vector3.new(0, 1, 0))
	elseif escena == 2 then
		local from = (cf * CFrame.new(-2.5, 3.5, 7 - t * 0.4)).Position
		return CFrame.lookAt(from, p + Vector3.new(0, 1.2, 0))
	elseif escena == 3 then
		local from = p + cf.RightVector * 16 + cf.LookVector * 4 + Vector3.new(0, 5, 0)
		return CFrame.lookAt(from, p + cf.LookVector * 8 + Vector3.new(0, 2, 0))
	elseif escena == 4 then
		local toCenter = Vector3.new(CENTER.X - p.X, 0, CENTER.Z - p.Z).Unit
		local side = Vector3.new(-toCenter.Z, 0, toCenter.X)
		local from = p + side * (14 - t) - toCenter * 8 + Vector3.new(0, 9, 0)
		return CFrame.lookAt(from, CENTER + Vector3.new(0, 10, 0))
	elseif escena == 5 or escena == 7 then
		local out = Vector3.new(p.X - CENTER.X, 0, p.Z - CENTER.Z).Unit
		local side = Vector3.new(-out.Z, 0, out.X)
		local back = 150 + t * 6
		local from = p
			+ out * back
			+ side * (escena == 7 and (t * 8 - 30) or 20)
			+ Vector3.new(0, 70, 0)
		return CFrame.lookAt(from, CENTER + Vector3.new(0, 55, 0))
	elseif escena == 6 then
		local toCenter = Vector3.new(CENTER.X - p.X, 0, CENTER.Z - p.Z).Unit
		local side = Vector3.new(-toCenter.Z, 0, toCenter.X)
		local from = p - toCenter * 9 + side * (4 - t * 0.5) + Vector3.new(0, 4, 0)
		return CFrame.lookAt(from, p + toCenter * 25 + Vector3.new(0, 12, 0))
	elseif escena == 8 then
		local a = t * 0.25
		local from = CENTER
			+ Vector3.new(math.cos(a) * 45, WorldLayout.restArenaTop + 22, math.sin(a) * 45)
		return CFrame.lookAt(from, Vector3.new(CENTER.X, WorldLayout.restArenaTop + 3, CENTER.Z))
	elseif escena == 9 or escena == 10 then
		local dir = Vector3.new(-1, 0, -0.6).Unit
		local from = CENTER + dir * (420 - t * 15) + Vector3.new(0, 170 - t * 6, 0)
		return CFrame.lookAt(from, CENTER + Vector3.new(0, 40, 0))
	end
	return nil
end

return Camara
