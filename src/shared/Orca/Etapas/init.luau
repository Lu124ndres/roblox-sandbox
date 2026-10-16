--!strict
--[[
	Etapas

	Un script de animación por etapa de la orca (cómo nada, respira, come y
	qué trucos hace). Se elige por la etapa del nombre del modelo (…E1..E4, el
	de ServerStorage: OrcaE<n> u OrcaFantasmaE<n>); sin etapa, la adulta.
]]

local Perfil = require(script.Perfil)

local BY_STAGE: { Perfil.Profile } = {
	require(script.OrcaBebe),
	require(script.OrcaJoven),
	require(script.OrcaAdulta),
	require(script.OrcaAnciana),
}

local Etapas = {}

function Etapas.forModel(name: string?): Perfil.Profile
	local stage = if name then tonumber(string.match(name, "E(%d)$")) else nil
	return BY_STAGE[stage or 3] or BY_STAGE[3]
end

return table.freeze(Etapas)
