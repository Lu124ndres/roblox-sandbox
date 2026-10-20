--!strict
--[[
	Assets de la pantalla de carga (ReplicatedFirst/LoadingScreen).

	Va en su propio módulo, sin require, porque la pantalla de carga corre antes
	de que llegue el resto de ReplicatedStorage: espera solo este archivo con
	WaitForChild y no depende de que Assets/init y sus hermanos ya estén.

	Background: la isla al atardecer con los gigantes de bloques (minotauro,
	dragón y zorro de agua). La hizo la IA de Canva sobre los renders de los
	modelos v2; fuente en assets/ui/carga/ (docs/ui-assets.md).
]]

local Loading = {
	Background = "rbxassetid://107415033029925",
}

return table.freeze(Loading)
