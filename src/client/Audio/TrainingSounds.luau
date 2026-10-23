--!strict
--[[
	TrainingSounds

	Cada tick del entrenamiento (solo el jugador local) toca la nota siguiente
	de una escala pentatónica: con la racha la melodía sube, y eso engancha
	(toda nota de la pentatónica suena bien con la anterior, sin
	desafinar). Debajo, la burbuja de siempre. Cada STEPS ticks seguidos la
	escala llega arriba, suena un acorde de premio con un "fiu" que sube (el
	mismo golpe en que el pescador da el tirón grande, PumpRhythm) y vuelve a
	empezar. Si deja de entrenar más de STREAK_GAP segundos, la racha se
	reinicia (igual que el color del "+N", GainPopup).
]]

local Sounds = require(script.Parent.Sounds)

local SCALE = { 0, 2, 4, 7, 9, 12, 14, 16, 19, 21 } -- semitonos: pentatónica mayor, 2 octavas
local STEPS = #SCALE -- igual que el tirón grande de PumpRhythm (cada 10)
local STREAK_GAP = 1.5
local BASE_PITCH = 0.85 -- la primera nota, un poco grave

Sounds.define({
	PowerTing = { volume = 0.4 },
	PowerWhoosh = { volume = 0.45 },
	PowerReward = { volume = 0.55 },
})

local TrainingSounds = {}

local streak, lastAt = 0, -math.huge

function TrainingSounds.tick()
	local now = os.clock()
	streak = if now - lastAt <= STREAK_GAP then streak + 1 else 1
	lastAt = now
	local step = (streak - 1) % STEPS + 1
	local pitch = BASE_PITCH * 2 ^ (SCALE[step] / 12)
	Sounds.play("PowerTing", nil, pitch, 1, true)
	Sounds.play("PowerTick", nil, 0.9 + step * 0.04)
	if step == STEPS then
		Sounds.play("PowerWhoosh", nil, 1.1)
		task.delay(0.12, Sounds.play, "PowerReward", nil, 1, 1, true)
	end
end

return table.freeze(TrainingSounds)
