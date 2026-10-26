--!strict
--[[
	Updates

	Actualizaciones semanales (docs/roadmap.md): salen los sábados a las 9:00
	de México. Cada una abre su contenido sola a la hora `at` (unix UTC, hora
	del servidor) con el candado de fecha de lo que trae (peces limitados,
	`season` de los gigantes). La lee shared/UpdateClock:
		- la cinta bajo la barra de hambre cuenta hasta la próxima y después
		  avisa «¡Nueva actualización!» durante `freshHours`
		- la ventana NOVEDADES muestra la última (o la próxima, como adelanto)
		  y se abre sola una vez por jugador cuando sale
	Agregar una: una entrada más al final, en orden de fecha. `icon` es un
	nombre de Interface/Icons. Los textos van traducidos en Lang/Dict/Novedades.
]]

export type UpdateItem = { icon: string, title: string, text: string }
export type UpdateDef = { id: string, at: number, title: string, items: { UpdateItem } }
export type UpdatesConfig = { freshHours: number, list: { UpdateDef } }

local Updates: UpdatesConfig = {
	freshHours = 48,
	list = {
		{
			id = "2026-10-31",
			at = 1793458800, -- sábado 31 de octubre, 9:00 de México
			title = "Final de Halloween",
			items = {
				{
					icon = "orca",
					title = "Orca fantasma",
					text = "Vuelve a la ruleta solo este fin de semana",
				},
				{
					icon = "fish",
					title = "Pez esqueleto",
					text = "Pez legendario limitado: solo hasta el lunes",
				},
				{
					icon = "ticket",
					title = "Código por likes",
					text = "Lleguemos a la meta de likes y se libera un código",
				},
				{
					icon = "crown",
					title = "Admin abuse",
					text = "Eventos x10 en vivo la primera hora",
				},
			},
		},
	},
}

return Updates
