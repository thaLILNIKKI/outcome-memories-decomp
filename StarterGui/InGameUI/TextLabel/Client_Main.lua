while task.wait() do
	local ping = game:GetService("Players").LocalPlayer:GetNetworkPing() * 2000
	local textLabel = script.Parent
	local format = string.format
	textLabel.Text = format("%s MS", (tostring((math.round(ping)))))
end
