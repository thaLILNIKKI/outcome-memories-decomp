-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local bannedUserIds = { 461403439 }

function kickPlayer(reason1, reason2)
	for _, object in workspace:GetChildren() do
		if not object:IsA("Terrain") then
			object:Destroy()
		end
	end
	game.Players.LocalPlayer:Kick(string.format("BANNED %s : %s", reason1, reason2))
end

local badAssetNames = { "proship" }

for _, userId in bannedUserIds do
	if game.Players.LocalPlayer:IsFriendsWith(userId) then
		kickPlayer("FOR BEING ASSOICATED WITH", game:GetService("Players"):GetNameFromUserIdAsync(userId) or "bad per son")
		continue
	end
	if game.Players.LocalPlayer.UserId == userId then
		kickPlayer("BECAUSE YOU ARE", " BLACK LISTED .")
	end
end

for _, assetId in { 81518530828984 } do
	if game:GetService("MarketplaceService"):PlayerOwnsAsset(game.Players.LocalPlayer, assetId) then
		local success, productInfo = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(assetId, Enum.InfoType.Asset)
		end)
		if success and productInfo then
			kickPlayer("OWNING ASSET CALLED:", productInfo.Name)
		end
	end
end

local humanoidDescription = game:GetService("Players"):GetHumanoidDescriptionFromUserId(game.Players.LocalPlayer.UserId)
if not humanoidDescription then
	return
end

for _, descriptionItem in humanoidDescription:GetChildren() do
	if descriptionItem:IsA("AccessoryDescription") then
		local productInfo = game:GetService("MarketplaceService"):GetProductInfo(descriptionItem.AssetId, Enum.InfoType.Asset)
		if productInfo then
			local creatorId = productInfo.Creator.Id
			
			if table.find(bannedUserIds, creatorId) then
				kickPlayer("HAVING ITEM MADE BY", game:GetService("Players"):GetNameFromUserIdAsync(creatorId) or "bad pers on")
			end
			
			for _, badName in badAssetNames do
				if string.find(string.lower(productInfo.Name), badName) then
					kickPlayer("HAVING BAD ASSET NAME:", productInfo.Name)
				end
			end
		end
	end
end
