local TweenService = game:GetService("TweenService")

local eventMessages = {
	Saved = "<font color=\"rgb(129, 200, 255)\">Saved</font> Temmate",
	Kills = "<font color=\"rgb(255, 0, 0)\">Killed</font> Survivor",
	Downed = "<font color=\"rgb(255, 142, 43)\">Downed</font> Survivor",
	Stuns = "<font color=\"rgb(255, 126, 126)\">Stunned</font> EXE %s",
	Revives = "<font color=\"rgb(119, 255, 88)\">Revived</font> Teammate %s",
	Heal = "<font color=\"rgb(0, 255, 0)\">Healed</font> Teammate %s",
	Escaped = "<font color=\"rgb(255, 255, 255)\">Escaped</font> Chase %s"
}

Color3.fromRGB(255, 142, 43)

local currentRank = "F"

local rankThresholds = {
	S = 1750,
	A = 1500,
	B = 950,
	C = 700,
	D = 500,
	F = 200
}

local rankPlaybackSpeeds = {
	S = 1.35,
	A = 1.15,
	B = 1,
	C = 0.8,
	D = 0.7,
	F = 0.5
}

function getRank(score)
	local rank = "F"
	
	for rankName, threshold in rankThresholds do
		if threshold <= score and rankThresholds[rank] < threshold then
			rank = rankName
		end
	end
	
	return rank
end

local Score = game.Players.LocalPlayer:WaitForChild("Score")
local currentScore = Score.Value

local function removeTags(text)
	return text:gsub("<br%s*/>", "\n"):gsub("<[^<>]->", "")
end

function txtpopup(message)
	local plainText = message:gsub("<br%s*/>", "\n"):gsub("<[^<>]->", "")
	local frame = script.Frame:Clone()
	local textLabel = frame.TextLabel
	
	frame.Parent = script.Parent.TXTBOX
	textLabel.Text = message
	textLabel.MaxVisibleGraphemes = 0
	
	TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()
	
	for i = 1, string.len(plainText) do
		textLabel.MaxVisibleGraphemes = textLabel.MaxVisibleGraphemes + 1
		task.wait(0.025)
	end
	
	task.delay(1.5, function()
		TweenService:Create(textLabel.UIStroke, TweenInfo.new(0.5), {
			Transparency = 1
		}):Play()
		
		TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			TextTransparency = 1
		}):Play()
	end)
	
	game:GetService("Debris"):AddItem(frame, 2.5)
end

game:GetService("ReplicatedStorage").Remotes:WaitForChild("ScoreEvent").OnClientEvent:Connect(function(eventType, points)
	if not eventMessages[eventType] then
		return
	end
	
	txtpopup((string.format(eventMessages[eventType], (string.format("+%d", (tonumber(points or 0)))))))
	currentScore = Score.Value
end)

Score.Changed:Connect(function(newScore)
	if Score.Value == 0 then
		currentScore = 0
		currentRank = "F"
		print("resetted")
		return
	end
	
	local newRank = getRank(newScore)
	
	if newRank == currentRank then
		return
	end
	
	script.Parent.RankUP.PlaybackSpeed = rankPlaybackSpeeds[newRank]
	script.Parent.RankUP:Play()
	
	local rankDisplay = script.RANK:Clone()
	rankDisplay.Parent = script.Parent
	rankDisplay.Text = newRank
	rankDisplay.Rotation = math.random(-10, 10)
	
	TweenService:Create(rankDisplay, TweenInfo.new(0.5), {
		Rotation = 0,
		Position = UDim2.new(0.085, 0, 0.698, 0)
	}):Play()
	
	task.delay(1.5, function()
		TweenService:Create(rankDisplay.UIStroke, TweenInfo.new(0.5), {
			Transparency = 1
		}):Play()
		
		TweenService:Create(rankDisplay, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			TextTransparency = 1
		}):Play()
		
		game:GetService("Debris"):AddItem(rankDisplay, 0.5)
	end)
	
	currentRank = newRank
end)
