--!strict
--[[
	Admin/AdminModeration

	Órdenes del panel de moderación sobre el jugador elegido. Como AdminPlayer:
	reciben (objetivo, valor, admin). No se aplican a otro administrador.
		kick      texto opcional: lo saca del servidor con ese motivo
		ban       minutos (0 = para siempre): BanAsync en todo el juego
		mute      no puede escribir en el chat hasta salir; unmute lo devuelve
		freeze    no se puede mover; unfreeze lo suelta
		respawn   reaparece en el spawn
	Para quitar un baneo (el jugador ya no está): `unban` en Admin/AdminFun.
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Admins = require(script.Parent.Admins)
local AdminPlayer = require(script.Parent.AdminPlayer)

local MAX_REASON = 120
local DEFAULT_REASON = "Un administrador te sacó del servidor"
local BAN_REASON = "Baneado por un administrador"
local MAX_BAN_MINUTES = 60 * 24 * 365

local muted: { [number]: boolean } = {}

local function notAdmin(target: Player, admin: Player)
	assert(target == admin or not Admins.is(target), "no se puede con otro administrador")
end

local function reason(value: unknown, fallback: string): string
	if type(value) == "string" and #value > 0 then
		return string.sub(value, 1, MAX_REASON)
	end
	return fallback
end

-- Puede o no escribir en todos los canales del chat.
local function setChat(player: Player, canSend: boolean)
	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then
		return
	end
	for _, channel in channels:GetChildren() do
		if channel:IsA("TextChannel") then
			local source = channel:FindFirstChild(player.Name)
			if source and source:IsA("TextSource") then
				source.CanSend = canSend
			end
		end
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local HANDLERS: { [string]: AdminPlayer.Handler } = {
	kick = function(target, value, admin)
		assert(target ~= admin, "no te puedes sacar a ti")
		notAdmin(target, admin)
		target:Kick(reason(value, DEFAULT_REASON))
		return "Expulsado"
	end,
	ban = function(target, value, admin)
		assert(target ~= admin, "no te puedes banear a ti")
		notAdmin(target, admin)
		local minutes = math.floor(AdminPlayer.number(value, 0, MAX_BAN_MINUTES))
		local ok, err = pcall(function()
			Players:BanAsync({
				UserIds = { target.UserId },
				Duration = if minutes == 0 then -1 else minutes * 60,
				DisplayReason = BAN_REASON,
				PrivateReason = `Panel admin: {admin.Name}`,
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)
		assert(ok, `no se pudo banear: {err}`)
		return if minutes == 0 then "Baneado para siempre" else `Baneado {minutes} min`
	end,
	mute = function(target, _value, admin)
		notAdmin(target, admin)
		muted[target.UserId] = true
		setChat(target, false)
		return "Silenciado"
	end,
	unmute = function(target)
		muted[target.UserId] = nil
		setChat(target, true)
		return "Puede volver a escribir"
	end,
	freeze = function(target, _value, admin)
		notAdmin(target, admin)
		local root = rootOf(target)
		assert(root, "no tiene personaje")
		root.Anchored = true
		return "Congelado"
	end,
	unfreeze = function(target)
		local root = rootOf(target)
		assert(root, "no tiene personaje")
		root.Anchored = false
		return "Descongelado"
	end,
	respawn = function(target)
		target:LoadCharacter()
		return "Reapareció"
	end,
}

-- Un silenciado sigue así si el chat le crea un canal nuevo; se olvida al salir.
TextChatService.DescendantAdded:Connect(function(child)
	if child:IsA("TextSource") and muted[child.UserId] then
		child.CanSend = false
	end
end)
Players.PlayerRemoving:Connect(function(player)
	muted[player.UserId] = nil
end)

return table.freeze({ HANDLERS = HANDLERS })
