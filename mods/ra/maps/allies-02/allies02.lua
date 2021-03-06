ConstructionVehicleReinforcements = { "mcv" }
ConstructionVehiclePath = { ReinforcementsEntryPoint.Location, DeployPoint.Location }

JeepReinforcements = { "e1", "e1", "e1", "jeep" }
JeepPath = { ReinforcementsEntryPoint.Location, ReinforcementsRallyPoint.Location }

TruckReinforcements = { "truk", "truk", "truk" }
TruckPath = { TruckEntryPoint.Location, TruckRallyPoint.Location }

TimerTicks = DateTime.Minutes(10)

SendConstructionVehicleReinforcements = function()
	local mcv = Reinforcements.Reinforce(player, ConstructionVehicleReinforcements, ConstructionVehiclePath)[1]
end

SendJeepReinforcements = function()
	Media.PlaySpeechNotification(player, "ReinforcementsArrived")
	Reinforcements.Reinforce(player, JeepReinforcements, JeepPath, DateTime.Seconds(1))
end

RunInitialActivities = function()
	Harvester.FindResources()
end

MissionAccomplished = function()
	Media.PlaySpeechNotification(player, "MissionAccomplished")
end

MissionFailed = function()
	Media.PlaySpeechNotification(player, "MissionFailed")
end

ticked = TimerTicks
Tick = function()
	ussr.Resources = ussr.Resources - (0.01 * ussr.ResourceCapacity / 25)

	if ukraine.HasNoRequiredUnits() then
		SendTrucks()
		player.MarkCompletedObjective(ConquestObjective)
	end

	if player.HasNoRequiredUnits() then
		player.MarkFailedObjective(ConquestObjective)
	end

	if ticked > 0 then
		UserInterface.SetMissionText("The convoy arrives in " .. Utils.FormatTime(ticked), TimerColor)
		ticked = ticked - 1
	elseif ticked == 0 then
		FinishTimer()
		SendTrucks()
		ticked = ticked - 1
	end
end

FinishTimer = function()
	for i = 0, 5, 1 do
		local c = TimerColor
		if i % 2 == 0 then
			c = HSLColor.White
		end

		Trigger.AfterDelay(DateTime.Seconds(i), function() UserInterface.SetMissionText("The convoy arrived!", c) end)
	end
	Trigger.AfterDelay(DateTime.Seconds(6), function() UserInterface.SetMissionText("") end)
end

ConvoyOnSite = false
SendTrucks = function()
	if not ConvoyOnSite then
		ConvoyOnSite = true
		ConvoyObjective = player.AddPrimaryObjective("Escort the convoy")
		Media.PlaySpeechNotification(player, "ConvoyApproaching")
		Trigger.AfterDelay(DateTime.Seconds(3), function()
			ConvoyUnharmed = true
			local trucks = Reinforcements.Reinforce(france, TruckReinforcements, TruckPath, DateTime.Seconds(1),
				function(truck)
					Trigger.OnIdle(truck, function() truck.Move(TruckExitPoint.Location) end)
				end)
			count = 0
			Trigger.OnEnteredFootprint( { TruckExitPoint.Location }, function(a, id)
				if a.Owner == france then
					count = count + 1
					a.Destroy()
					if count == 3 then
						player.MarkCompletedObjective(ConvoyObjective)
						Trigger.RemoveFootprintTrigger(id)
					end
				end
			end)
			Trigger.OnAnyKilled(trucks, ConvoyCasualites)
		end)
	end
end

ConvoyCasualites = function()
	Media.PlaySpeechNotification(player, "ConvoyUnitLost")
	if ConvoyUnharmed then
		ConvoyUnharmed = false
		Trigger.AfterDelay(DateTime.Seconds(1), function() player.MarkFailedObjective(ConvoyObjective) end)
	end
end

ConvoyTimer = function(delay, notification)
	Trigger.AfterDelay(delay, function()
		if not ConvoyOnSite then
			Media.PlaySpeechNotification(player, notification)
		end
	end)
end

WorldLoaded = function()
	player = Player.GetPlayer("Greece")
	france = Player.GetPlayer("France")
	ussr = Player.GetPlayer("USSR")
	ukraine = Player.GetPlayer("Ukraine")

	Trigger.OnObjectiveAdded(player, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "New " .. string.lower(p.GetObjectiveType(id)) .. " objective")
	end)
	Trigger.OnObjectiveCompleted(player, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective completed")
	end)
	Trigger.OnObjectiveFailed(player, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective failed")
	end)
	Trigger.OnPlayerLost(player, MissionFailed)
	Trigger.OnPlayerWon(player, MissionAccomplished)

	ConquestObjective = player.AddPrimaryObjective("Secure the area.")

	Trigger.AfterDelay(DateTime.Seconds(1), function() Media.PlaySpeechNotification(allies, "MissionTimerInitialised") end)

	RunInitialActivities()

	SendConstructionVehicleReinforcements()
	Trigger.AfterDelay(DateTime.Seconds(5), SendJeepReinforcements)
	Trigger.AfterDelay(DateTime.Seconds(10), SendJeepReinforcements)

	Camera.Position = ReinforcementsEntryPoint.CenterPosition
	TimerColor = player.Color

	ConvoyTimer(DateTime.Seconds(3), "TenMinutesRemaining")
	ConvoyTimer(DateTime.Minutes(5), "WarningFiveMinutesRemaining")
	ConvoyTimer(DateTime.Minutes(6), "WarningFourMinutesRemaining")
	ConvoyTimer(DateTime.Minutes(7), "WarningThreeMinutesRemaining")
	ConvoyTimer(DateTime.Minutes(8), "WarningTwoMinutesRemaining")
	ConvoyTimer(DateTime.Minutes(9), "WarningOneMinuteRemaining")
end
