--!strict
--[[
	GiantPortrait

	Retrato del monstruo actual a la izquierda del panel de hambre: su ícono
	de la hoja de íconos (Interface/Icons: orca, minotauro, dragón, zorro),
	que se mece un poco. Cambia solo cuando cambia el monstruo.
]]

local RunService = game:GetService("RunService")

local Icons = require(script.Parent.Parent.Interface.Icons)

local SWAY_SPEED, SWAY_DEGREES = 1.4, 4
-- Ícono de cada monstruo (Config.Giants.chain[...].id -> tipo en Icons).
local ICONS: { [string]: string } = {
	Orca = "orca",
	Minotauro = "minotaur",
	DragonMarino = "dragon",
	ZorroDeAgua = "fox",
	OrcaFantasma = "orca",
}

export type Portrait = { set: (giantId: string) -> () }

local GiantPortrait = {}

-- Tipo de ícono (Interface/Icons) de un gigante.
function GiantPortrait.iconFor(giantId: string): string
	return ICONS[giantId] or "orca"
end

-- `image`: el ImageLabel donde se pinta (lo arma HungerPanel).
function GiantPortrait.attach(image: ImageLabel): Portrait
	local shownId: string? = nil
	RunService.RenderStepped:Connect(function()
		if image.Visible then
			image.Rotation = math.sin(os.clock() * SWAY_SPEED) * SWAY_DEGREES
		end
	end)

	local function set(giantId: string)
		if giantId == shownId then
			return
		end
		shownId = giantId
		image.Visible = Icons.paint(image, GiantPortrait.iconFor(giantId))
	end

	return { set = set }
end

return GiantPortrait
