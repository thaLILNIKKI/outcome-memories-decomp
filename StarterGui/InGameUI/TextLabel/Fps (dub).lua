task.wait(5)

local GameVersion = workspace.GameProperties.GameVersion
local PlaceVersion = game.PlaceVersion

script.Parent.Text = string.format("Server Version:%s", PlaceVersion)

while task.wait(2) do
	if GameVersion ~= game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Updated then
		script.Parent.Text = string.format("Server Version:%s (OUTDATED SERVER) ", PlaceVersion)
	end
end
