--!strict
--[[
	Codes

	Canje de códigos (remote RedeemCode). El texto se normaliza (mayúsculas,
	sin espacios), se busca en CodeList (un alias cuenta como su original), se revisa que no haya vencido ni se
	haya usado, se guarda como usado y se entrega el premio. El resultado
	llega al jugador como Notice "code".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CodeList = require(script.Parent.CodeList)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Rewards)

local MAX_LENGTH = 30

local Codes = {}

local function redeem(player: Player, raw: unknown)
	if type(raw) ~= "string" or #raw > MAX_LENGTH then
		return
	end
	local key = string.upper((string.gsub(raw, "%s", "")))
	local code = CodeList[key]
	if code and code.aliasOf then -- GIANTS es GIGANTES: se anota y se paga como el original
		key = code.aliasOf
		code = CodeList[key]
	end
	local save = PlayerData.read(player)
	if not save then
		return
	end
	if not code then
		Remotes.Notice:FireClient(player, "code", "invalid")
		return
	elseif code.expires and os.time() > code.expires then
		Remotes.Notice:FireClient(player, "code", "expired")
		return
	elseif save.codes[key] then
		Remotes.Notice:FireClient(player, "code", "used")
		return
	end
	PlayerData.edit(player, function(data)
		data.codes[key] = true
	end)
	Rewards.give(player, code, "codigos")
	Remotes.Notice:FireClient(
		player,
		"code",
		"ok",
		Rewards.describe(code, Config.Social.personalBoostMultiplier)
	)
end

function Codes.init()
	Remotes.RedeemCode.OnServerEvent:Connect(RateLimit.wrap("RedeemCode", 0.5, 3, redeem))
end

return Codes
