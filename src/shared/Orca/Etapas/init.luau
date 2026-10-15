--!strict
--[[
	Etapas

	Un script de animación por etapa de la orca (cómo nada, respira, come y
	qué trucos hace). Se elige por el nombre del modelo (OrcaE1..E4, el de
	ServerStorage); un modelo desconocido usa el de la adulta.
]]

local Perfil = require(script.Perfil)

local BY_MODEL: { [string]: Perfil.Profile } = {
	OrcaE1 = require(script.OrcaBebe),
	OrcaE2 = require(script.OrcaJoven),
	OrcaE3 = require(script.OrcaAdulta),
	OrcaE4 = require(script.OrcaAnciana),
}

local Etapas = {}

function Etapas.forModel(name: string?): Perfil.Profile
	return BY_MODEL[name or ""] or BY_MODEL.OrcaE3
end

return table.freeze(Etapas)
