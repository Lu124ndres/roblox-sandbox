--!strict
--[[
	GiantEvolution

	Cuando el gigante pasa de etapa (GiantView), arranca su evolución
	(EvolveFx) y decide cuándo cambia el modelo:
		- con una evolución en curso (EvolucionHasta en el futuro): el modelo
		  nuevo aparece y empieza a crecer en el estallido, 1.3 s después
		  del inicio que marcó el servidor, igual para todos;
		- sin evolución (el admin lo puso en otra etapa, o el aviso llegó
		  tarde): estalla ya, con el destello tapando el cambio.
	Si la barra se llenó de golpe (Robux, ruleta) no evoluciona: toma la etapa
	sin animación y se va; sus saltos pisaban los de la despedida y quedaba a
	la vista durante el descanso.
	Quien entra a mitad o cambia de gigante no pasa por aquí: GiantView
	crea el cuerpo directo en su etapa (setStage instantáneo).
	En el estallido salta y gira como siempre, salvo los gigantes con pose
	de evolución propia (OWN_POSE: el minotauro se agacha, explota hacia
	arriba y ruge por su cuenta; el dragón se envuelve en las alas y las abre de golpe;
	el zorro de agua se agacha, se sacude y aúlla con el abanico abierto: Zorro/Evolucion).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantMoments = require(script.Parent.Parent.Audio.GiantMoments)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local EvolveFx = require(script.Parent.EvolveFx)
local EvolveLook = require(script.Parent.EvolveLook)
local GiantBody = require(script.Parent.GiantBody)

export type Handle = EvolveFx.Evolution

local OWN_POSE: { [string]: boolean } =
	{ Minotauro = true, DragonMarino = true, ZorroDeAgua = true }

local GiantEvolution = {}

local function tween(
	value: NumberValue,
	target: number,
	seconds: number,
	style: Enum.EasingStyle,
	out: boolean
)
	local direction = if out then Enum.EasingDirection.Out else Enum.EasingDirection.In
	local animation =
		TweenService:Create(value, TweenInfo.new(seconds, style, direction), { Value = target })
	animation:Play()
	return animation
end

-- Salto y pirueta del estallido (los gigantes sin pose propia).
local function leap(body: GiantBody.Body, height: number)
	local up = tween(body.lift, height * 0.12, 0.6, Enum.EasingStyle.Quad, true)
	up.Completed:Once(function()
		tween(body.lift, 0, 0.9, Enum.EasingStyle.Bounce, true)
	end)
	tween(body.spin, body.spin.Value + 360, 1.4, Enum.EasingStyle.Quad, true)
end

-- Hora del servidor en que empezó la evolución (o una que hace estallar ya).
local function startTime(): number
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local untilAt = state and state:GetAttribute(Protocol.GiantAttributes.EvolvingUntil)
	local now = Workspace:GetServerTimeNow()
	if type(untilAt) == "number" and untilAt > now then
		return math.min(untilAt - Config.Giants.cycle.evolveSeconds, now)
	end
	return now - EvolveLook.burstSeconds()
end

function GiantEvolution.begin(
	body: GiantBody.Body,
	def: Config.GiantDef,
	stage: number,
	progress: number
): Handle?
	if progress >= 1 then
		body.setStage(stage, true)
		return nil
	end
	return EvolveFx.play(body, def, stage, startTime(), function()
		if not body.model.Parent then
			return
		end
		body.setStage(stage) -- el modelo nuevo, escondido por el destello, y empieza a crecer
		if not OWN_POSE[def.id] then
			leap(body, GiantStages.heightFor(stage))
			GiantMoments.play("evolve", def.id, stage, body.top(), body.water())
		end
		if not (def.sand or def.lava or body.flies) then
			Sounds.play("BigSplash", body.water())
		end
	end)
end

return table.freeze(GiantEvolution)
