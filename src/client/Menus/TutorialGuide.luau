--!strict
--[[
	TutorialGuide

	Guía del primer minuto, pensada para que se entienda sin leer de más
	(pedido del usuario): arriba, la instrucción grande de la misión y su
	avance (TutorialBanner); en el mundo, una fila de flechas amarillas que
	sale del jugador y llega hasta el destino (GuidePath) y, en el destino,
	un aura de luz amarilla en el suelo (LightAura; sin pilar ni cartel,
	pedido del usuario).

	Cada misión (Config.Retention.tutorial) tiene sus tramos: al volcán, primero
	«¡CRUZA EL PUENTE!» hasta la entrada del puente y, ya en él, «¡ALIMENTA A
	...!» hasta la puerta del cráter (desde ahí se alimenta). Al llegar al
	destino las flechas se van y queda el aviso. Al cumplir un paso, «¡LISTO!»
	y pasa al siguiente. El avance lo decide el servidor (atributos Tutorial
	y TutorialCount); nada queda puesto en el mapa.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantName = require(script.Parent.Parent.GiantName)
local LightAura = require(script.Parent.Parent.Effects.LightAura)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local GuidePath = require(script.Parent.GuidePath)
local TutorialBanner = require(script.Parent.TutorialBanner)

local ATTR = Protocol.PlayerAttributes
local STEPS = Config.Retention.tutorial
local ARRIVE = 12 -- studs del destino a los que las flechas se van
local DONE_SECONDS = 1.4 -- lo que se ve «¡LISTO!» antes del paso siguiente
local GUIDE_COLOR = Color3.fromRGB(255, 214, 30) -- el amarillo de las flechas (GuideArrow)

type Leg = { target: Vector3, title: string, hint: string }

local TutorialGuide = {}

local function polar(angle: number, radius: number, y: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
end

-- Cómo se hace la acción según con qué juega: «Mantén E» o «Toca PESCAR».
-- hold: pescar y alimentar, que en el mando muestran el gatillo (RT).
local function how(verb: string, button: string, hold: boolean?): string
	if InputHints.mode() == "touch" then
		return `Toca {button}`
	end
	return `{verb} {if hold then InputHints.holdAction() else InputHints.action()}`
end

-- El tramo actual de la misión `id`: adónde ir y qué dice el aviso grande.
local function legFor(id: string, position: Vector3, count: number, goal: number): Leg
	if id == "pescar" then
		local angle = math.deg(math.atan2(position.Z, position.X))
		return {
			target = polar(angle, WorldLayout.shoreRadius - 5, WorldLayout.waterLevel + 1),
			title = `¡PESCA {goal} PECES!`,
			hint = `{how("Mantén", "PESCAR", true)} en la playa · llevas {count}`,
		}
	elseif id == "alimentar" then
		local start, finish = WorldZones.bridgeEnds()
		local onTheWay = WorldZones.isOnBridge(position)
			or WorldZones.distanceToCrater(position) < WorldLayout.craterBaseRadius
		if onTheWay then
			return {
				target = finish,
				title = `¡ALIMENTA A {string.upper(GiantName.current())}!`,
				hint = `{how("Mantén", "ALIMENTAR", true)} en la puerta del volcán`,
			}
		end
		return {
			target = start,
			title = "¡CRUZA EL PUENTE!",
			hint = "Sigue las flechas hasta el volcán",
		}
	elseif id == "entrenar" then
		return {
			target = WorldZones.pondCenter(1),
			title = "¡ENTRENA EN EL ESTANQUE!",
			hint = `{how("Aprieta", "ENTRENAR")} junto al agua`,
		}
	end
	return {
		target = polar(WorldLayout.shopAngle, WorldLayout.shopRadius, WorldLayout.plateauHeight),
		title = "¡COMPRA UNA MEJORA!",
		hint = `{how("Aprieta", "MEJORAS")} en la tienda`,
	}
end

function TutorialGuide.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local banner = TutorialBanner.new(screen)
	local route = GuidePath.new()
	local marker = LightAura.marker(GUIDE_COLOR)
	local shownStep, shownTitle = -1, ""
	local celebrating = false

	local function step(): number
		local value = player:GetAttribute(ATTR.Tutorial)
		return (if type(value) == "number" then value else 0) + 1
	end

	local function count(): number
		local value = player:GetAttribute(ATTR.TutorialCount)
		return if type(value) == "number" then value else 0
	end

	local function position(): Vector3?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.Position else nil
	end

	local refresh: () -> ()

	-- Al cumplir un paso: «¡LISTO!» un momento y después el siguiente.
	local function celebrate(nextIndex: number)
		celebrating = true
		banner.done()
		task.delay(DONE_SECONDS, function()
			celebrating = false
			if step() == nextIndex then
				refresh()
			end
		end)
	end

	-- Pone en el aviso grande el tramo actual (o lo esconde si el tutorial terminó).
	refresh = function()
		local index = step()
		local current = STEPS[index]
		local loaded = player:GetAttribute(ATTR.DataLoaded) == true
		if not loaded or not current then
			banner.show(false)
			shownStep = -1
			return
		end
		if shownStep ~= -1 and shownStep ~= index then
			shownStep = index
			shownTitle = ""
			celebrate(index)
			return
		end
		if celebrating then
			return
		end
		shownStep = index
		local leg = legFor(current.id, position() or Vector3.zero, count(), current.goal)
		shownTitle = leg.title
		local progress = if current.goal > 1 then `{count()}/{current.goal}` else ""
		banner.set(leg.title, progress, leg.hint)
		banner.show(true)
	end
	for _, attribute in { ATTR.Tutorial, ATTR.TutorialCount, ATTR.DataLoaded } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	InputHints.onChange(refresh)
	refresh()

	RunService.Heartbeat:Connect(function(dt: number)
		local current = STEPS[step()]
		local at = position()
		if not current or shownStep == -1 or not at then
			route.hide()
			marker.show(false)
			return
		end
		local leg = legFor(current.id, at, count(), current.goal)
		if leg.title ~= shownTitle and not celebrating then -- cambió de tramo (subió al puente)
			refresh()
		end
		local distance = (leg.target - at).Magnitude
		marker.place(leg.target)
		marker.show(true)
		if distance < ARRIVE then
			route.hide()
			return
		end
		route.update(at, leg.target, os.clock(), dt)
	end)
end

return TutorialGuide
