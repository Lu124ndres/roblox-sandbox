--!strict
--[[
	BootLooks

	Cómo se ve cada par de botas de la tienda (mismo orden que
	Config.Shop.Boots): color de la bota y del detalle, suela, material,
	alto de la caña (0 = sandalia), si brilla y un adorno propio que arma
	BootBuilder: alas, rayos, llamas, cristales, estrellas o aletas.
]]

export type BootExtra = "wings" | "bolts" | "flames" | "crystals" | "stars" | "fins" | "none"

export type BootLook = {
	color: Color3,
	accent: Color3,
	sole: Color3,
	material: Enum.Material,
	shaft: number,
	glow: boolean,
	extra: BootExtra,
}

local rgb = Color3.fromRGB
local M = Enum.Material

local function look(
	color: Color3,
	accent: Color3,
	sole: Color3,
	material: Enum.Material,
	shaft: number,
	glow: boolean,
	extra: BootExtra
): BootLook
	return {
		color = color,
		accent = accent,
		sole = sole,
		material = material,
		shaft = shaft,
		glow = glow,
		extra = extra,
	}
end

local BootLooks: { BootLook } = {
	look(rgb(190, 140, 90), rgb(120, 80, 40), rgb(90, 60, 30), M.Fabric, 0, false, "none"), -- sandalias
	look(
		rgb(255, 210, 90),
		rgb(255, 120, 80),
		rgb(250, 250, 250),
		M.SmoothPlastic,
		0.5,
		false,
		"none"
	), -- playa
	look(rgb(30, 50, 100), rgb(250, 250, 250), rgb(40, 30, 25), M.Fabric, 1.1, false, "none"), -- marinero
	look(
		rgb(230, 40, 50),
		rgb(255, 255, 255),
		rgb(30, 30, 30),
		M.SmoothPlastic,
		0.7,
		false,
		"bolts"
	), -- veloces
	look(
		rgb(200, 240, 255),
		rgb(255, 255, 255),
		rgb(150, 200, 230),
		M.SmoothPlastic,
		0.9,
		false,
		"wings"
	), -- viento
	look(rgb(40, 40, 60), rgb(255, 230, 60), rgb(20, 20, 30), M.Metal, 1.0, true, "bolts"), -- rayo
	look(
		rgb(255, 140, 130),
		rgb(255, 240, 220),
		rgb(200, 90, 90),
		M.SmoothPlastic,
		0.9,
		false,
		"fins"
	), -- coral
	look(rgb(110, 80, 50), rgb(200, 170, 110), rgb(60, 40, 25), M.Wood, 1.4, false, "none"), -- explorador
	look(rgb(190, 235, 255), rgb(255, 255, 255), rgb(120, 180, 220), M.Ice, 1.2, true, "crystals"), -- hielo
	look(rgb(50, 30, 26), rgb(255, 110, 30), rgb(25, 18, 16), M.CrackedLava, 1.2, true, "flames"), -- lava
	look(
		rgb(170, 230, 255),
		rgb(255, 255, 255),
		rgb(120, 160, 255),
		M.Glass,
		1.1,
		true,
		"crystals"
	), -- cristal
	look(rgb(30, 20, 70), rgb(255, 240, 150), rgb(10, 10, 30), M.SmoothPlastic, 1.1, true, "stars"), -- cometa
	look(rgb(34, 20, 50), rgb(190, 100, 255), rgb(15, 10, 25), M.Metal, 1.3, true, "fins"), -- abismo
	look(rgb(255, 215, 90), rgb(255, 255, 255), rgb(200, 150, 40), M.Foil, 1.0, true, "wings"), -- Hermes
}

return BootLooks
