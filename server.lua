local debug = Config.server_debug
local doCommand = Config.AllowCommand
local commandRestricted = Config.CommandRestricted

RegisterNetEvent('baseevents:enteredVehicle')
AddEventHandler('baseevents:enteredVehicle', function(currentVehicle, currentSeat, displayName, netId)
	local playerId = source
	TriggerClientEvent('vlad_gears:entered_listener', playerId)
	if debug then
		print('vlad_gears:server-enabled')
	end
end)

RegisterNetEvent('baseevents:leftVehicle')
AddEventHandler('baseevents:leftVehicle', function(currentVehicle, currentSeat, displayName, netId)
	local playerId = source
	TriggerClientEvent('vlad_gears:exited_listener', playerId)
	if debug then
		print('vlad_gears:server-disabled')
	end
end)

if doCommand then
	if commandRestricted then
		RegisterCommand('manual_trans', function(source)
			if (source > 0) then
			TriggerClientEvent('vlad_gears:toggle', source)
			end
			if debug then
				print(source..' Attempted to toggle manual gearbox')
			end
		end, true)
	else
		RegisterCommand('manual_trans', function(source)
			if (source > 0) then
			TriggerClientEvent('vlad_gears:toggle', source)
			end
			if debug then
				print(source..' Attempted to toggle manual gearbox')
			end
		end, false)
	end
end