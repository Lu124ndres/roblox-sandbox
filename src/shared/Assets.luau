--!strict
--[[
	Assets

	Registro central de todos los rbxassetid del juego. Ningún otro módulo
	escribe un ID inline: siempre se referencian como Assets.UI.NombreDelAsset.

	Ventajas: un solo lugar para auditar qué assets usa el juego, reemplazar
	uno no exige buscar en todo el código, y los IDs faltantes son visibles.

	Si un asset todavía no existe, se deja como MISSING ("rbxassetid://0")
	y se anota en docs/ui-assets.md con su estado.

	Secciones:
		UI          Imágenes 2D de interfaz (paneles, botones, íconos). Origen: ForgeGUI.
		Meshes      MeshId de modelos importados desde Blender (fase 2).
		Textures    Texturas tileables (ForgeGUI) y texturas de mesh (Blender, fase 2).
					Las de mesh van con sufijo de canal: Color, Normal, Roughness.
		Animations  Reservado. Este proyecto anima por código (TweenService/CFrame);
					solo se usaría si una decisión en docs/decisiones.md lo cambia.

	Nomenclatura: claves en PascalCase, descriptivas (PanelBackground, no Img1).
]]

export type AssetMap = { [string]: string }

export type Assets = {
	MISSING: string,
	UI: AssetMap,
	Meshes: AssetMap,
	Textures: AssetMap,
	Animations: AssetMap,
}

local Assets: Assets = {
	-- Marcador para assets pendientes. Buscar "MISSING" lista lo que falta subir.
	MISSING = "rbxassetid://0",

	UI = {},

	Meshes = {
		-- Orca etapa 1. Fuente: assets/blender/OrcaE1.fbx (9,806 triángulos).
		OrcaE1 = "rbxassetid://116864238392648",
	},

	Textures = {
		-- SurfaceAppearance de la orca etapa 1. Fuente: assets/textures/OrcaE1_*.png.
		-- Sin mapa de metalicidad: el modelo no es metálico.
		OrcaE1Color = "rbxassetid://78747470199717",
		OrcaE1Normal = "rbxassetid://79662647526007",
		OrcaE1Roughness = "rbxassetid://86419609055550",
	},

	Animations = {},
}

return table.freeze(Assets)
