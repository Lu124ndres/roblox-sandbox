--!strict
--[[
	Remotes

	Crea la carpeta de RemoteEvents en ReplicatedStorage una sola vez, al
	primer require, y devuelve referencias tipadas. Los nombres salen de
	Protocol para que el cliente busque exactamente los mismos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local folder = Instance.new("Folder")
folder.Name = Protocol.RemotesFolder

local function makeEvent(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

local Remotes = {
	FishingUpdate = makeEvent(Protocol.Remotes.FishingUpdate),
	CastRequest = makeEvent(Protocol.Remotes.CastRequest),
	ReelIn = makeEvent(Protocol.Remotes.ReelIn),
	FeedRequest = makeEvent(Protocol.Remotes.FeedRequest),
	FeedResult = makeEvent(Protocol.Remotes.FeedResult),
	GiantFed = makeEvent(Protocol.Remotes.GiantFed),
	TrainingTick = makeEvent(Protocol.Remotes.TrainingTick),
	TrainingDenied = makeEvent(Protocol.Remotes.TrainingDenied),
	BuyUpgrade = makeEvent(Protocol.Remotes.BuyUpgrade),
	ShopResult = makeEvent(Protocol.Remotes.ShopResult),
	OpenShop = makeEvent(Protocol.Remotes.OpenShop),
	Notice = makeEvent(Protocol.Remotes.Notice),
	ClaimDaily = makeEvent(Protocol.Remotes.ClaimDaily),
	ClaimPlaytime = makeEvent(Protocol.Remotes.ClaimPlaytime),
	AdminCommand = makeEvent(Protocol.Remotes.AdminCommand),
	RestEnter = makeEvent(Protocol.Remotes.RestEnter),
	Rebirth = makeEvent(Protocol.Remotes.Rebirth),
	SaveSettings = makeEvent(Protocol.Remotes.SaveSettings),
	RedeemCode = makeEvent(Protocol.Remotes.RedeemCode),
	ClaimGroup = makeEvent(Protocol.Remotes.ClaimGroup),
	SetGift = makeEvent(Protocol.Remotes.SetGift),
	ChooseOutfit = makeEvent(Protocol.Remotes.ChooseOutfit),
	GiantAttack = makeEvent(Protocol.Remotes.GiantAttack),
	GiantHit = makeEvent(Protocol.Remotes.GiantHit),
}

folder.Parent = ReplicatedStorage

return table.freeze(Remotes)
