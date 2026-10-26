--!strict
--[[
	UpdateClock

	Qué actualización toca según la hora del servidor (Config/Updates): la
	última que ya salió, la próxima y cuánto falta. Lo usan la cinta del
	contador (client/Interface/UpdateRibbon), la ventana NOVEDADES y el
	servidor para anotar cuál vio cada jugador (Retention/NewsService).
]]

local Workspace = game:GetService("Workspace")

local Updates = require(script.Parent.Config.Updates)

export type UpdateDef = Updates.UpdateDef
export type UpdateItem = Updates.UpdateItem

local UpdateClock = {}

function UpdateClock.now(): number
	return Workspace:GetServerTimeNow()
end

-- La última que ya salió (nil si todavía no salió ninguna).
function UpdateClock.current(): UpdateDef?
	local now, found = UpdateClock.now(), nil
	for _, update in Updates.list do
		if update.at <= now then
			found = update
		end
	end
	return found
end

-- La primera que todavía no sale (nil si no hay ninguna anunciada).
function UpdateClock.upcoming(): UpdateDef?
	local now = UpdateClock.now()
	for _, update in Updates.list do
		if update.at > now then
			return update
		end
	end
	return nil
end

-- ¿La última salió hace menos de freshHours? (la cinta dice «¡Nueva actualización!»)
function UpdateClock.fresh(): UpdateDef?
	local current = UpdateClock.current()
	if current and UpdateClock.now() - current.at < Updates.freshHours * 3600 then
		return current
	end
	return nil
end

-- «4d 12:30:05», «12:30:05» o «4:05».
function UpdateClock.format(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local days, hours = total // 86400, (total // 3600) % 24
	local minutes, secs = (total // 60) % 60, total % 60
	if days > 0 then
		return string.format("%dd %02d:%02d:%02d", days, hours, minutes, secs)
	elseif hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

return UpdateClock
