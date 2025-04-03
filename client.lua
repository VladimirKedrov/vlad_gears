-- vlad_gears - manual transmission and clutch control
-- 
-- Copyright (C) 2025  VladimirKedrov
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- Startup variables
local debug = Config.client_debug
local penalty = Config.ShiftingNoClutchMultiplier
local stall_threshold = Config.StallThreshold
local stop_extra_gear = Config.SuppressExtraGearFromGearboxUpgrade
local penalise_early_clutch = Config.PenaliseReleasingClutchEarly
local shifting_with_clutch_mult = Config.ShiftingWithClutchMultiplier
local restart_from_external_script = Config.RestartFromStallInExternalScript
local doAnimations = Config.DoAnimations
local doSoundEffectShiftStart = Config.DoSoundEffectShiftStart
local doSoundEffectShiftEnd = Config.DoSoundEffectShiftEnd
local suppressExtraGearOnlyForManuals = Config.SuppressExtraGearOnlyForManuals
local suppressAutomaticReverseGear = Config.SuppressAutomaticReverseGear
local checkHighGear = Config.CheckHighGear
local doSpeedoToggleEvent = Config.SpeedoAutoToggle
local doRevLimiter = Config.RevLimiter
local clutch_only = Config.ClutchOnly
local rpmReturnThreshold = Config.rpmReturnThreshold
local shift_time_up = 0          -- Shift Time
local shift_time_down = 0        -- Shift Time
local vehicle = nil              -- Current Vehicle
local timestep_ms = 0            -- Current framerate
local shiftdir = 0               -- Shift time control
local stalled = false            -- Engine Stall
local restarted = true           -- Engine Stall
local target_gear = 0            -- Startup Sequence.
local currently_shifting = false -- Neutral simulation.
local gearcount = 1              -- Extra gear from upgrade prevention
local storage_gear = 0           -- Gearshift
local current_gear = 0           -- Gearshift
local rhd = false                -- Animations
local vehNet = 0                 -- Statebags
local ent = 0                    -- Statebags
local stall_limit = Config.StallTimer
local stall_limit_frametime = 0
local stall_timer = 0
local toggled = false
local inVeh = false
local processGearbox = false
local display_gear = 0
local modified = false
local limiter = false
local flagged = false

-- TEST
local topspeedtest = Config.topspeedtest

-- Keybinds section
local clutch_pedal_pushed = false
local request_upshift = false
local request_downshift = false
-- Make sure a + and - exist otherwise problems occur
RegisterCommand('+clutch', function()
	clutch_pedal_pushed = true
end, false)
RegisterCommand('-clutch', function()
	clutch_pedal_pushed = false
end, false)
RegisterCommand('+upshift', function()
	TriggerEvent('vlad_gears:upshift')
end, false)
RegisterCommand('-upshift', function()

end, false)
RegisterCommand('+downshift', function()
	TriggerEvent('vlad_gears:downshift')
end, false)
RegisterCommand('-downshift', function()

end, false)
local shift_up = Config.DefaultShiftUp
local shift_down = Config.DefaultShiftDown
local clutch = Config.DefaultClutch
RegisterKeyMapping('+upshift', 'Shift Up', 'keyboard', shift_up)
RegisterKeyMapping('+downshift', 'Shift Down', 'keyboard', shift_down)
RegisterKeyMapping('+clutch', 'Clutch Control', 'keyboard', clutch)
--RegisterKeyMapping('~!+clutch', 'Clutch Control - Alternate Key', 'keyboard', 'RCONTROL') -- Alternate keybinding
-- Bitwise tool to check handling flags
local OR, XOR, AND = 1, 3, 4
local function bitOper(a, b, oper)
	local r, m, s = 0, 2 ^ 31
	repeat
		s, a, b = a + b + m, a % m, b % m
		r, m = r + m * oper % (s - a - b), m / 2
	until m < 1
	return r
end
-- Gear setter function
local setGear = GetHashKey('SET_VEHICLE_CURRENT_GEAR') & 0xFFFFFFFF
local function SetVehicleCurrentGear(veh, gear)
	Citizen.InvokeNative(setGear, veh, gear)
end
-- Gearbox function
local function Vlad_SET_TRANSMISSION_REDUCED_GEAR_RATIO(veh3, value)
	return Citizen.InvokeNative(0x337EF33DA3DDB990, veh3, value)
end
-- Max Revs function
local function Vlad_SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS(veh4, value)
	return Citizen.InvokeNative(0x5AE614ECA5FDD423, veh4, value)
end
-- BaseShift Timer
local remainingPercentage = 0
local function countdownTimer(milliseconds)
	-- Convert minutes to seconds
	-- Loop through the countdown timer
	local origin_ms = milliseconds
	while milliseconds >= 0 do
		-- Calculate the remaining minutes and seconds
		local remainingMilliseconds = milliseconds
		-- Print the remaining time
		remainingPercentage = (remainingMilliseconds / origin_ms)
		-- Decrement the seconds by 1
		milliseconds = milliseconds - 1
		-- Delay the execution for 1 milisecond
		Citizen.Wait(1)
	end
	-- Print "Countdown complete!" when the timer reaches 0
	remainingPercentage = 0
end
-- Penalty Timer
local remainingPercentage2 = 0
local function countdownTimer2(milliseconds2)
	-- Convert minutes to seconds
	-- Loop through the countdown timer
	local origin_ms = milliseconds2
	while milliseconds2 >= 0 do
		-- Calculate the remaining minutes and seconds
		local remainingMilliseconds = milliseconds2
		-- Print the remaining time
		remainingPercentage2 = (remainingMilliseconds / origin_ms)
		-- Decrement the seconds by 1
		milliseconds2 = milliseconds2 - 1
		-- Delay the execution for 1 milisecond
		Citizen.Wait(1)
	end
	-- Print "Countdown complete!" when the timer reaches 0
	remainingPercentage2 = 0
end
-- Triggered by serverside command
RegisterNetEvent('vlad_gears:toggle')
AddEventHandler('vlad_gears:toggle', function()
	if inVeh then
		if not GetVehicleClass(vehicle) == 21 or 16 or 15 or 14 or 13 then
			if not toggled then
				toggled = true
				TriggerEvent('vlad_gears:enabled')
			else
				toggled = false
			end
		else
			print('This vehicle is not a car, bike or quadbike')
		end
	else
		print('Not in Vehicle')
	end
	if debug then
		print('attempted to toggle manual gearbox')
	end
end)
-- Enables the toggle method activation
RegisterNetEvent('vlad_gears:activate')
AddEventHandler('vlad_gears:activate', function()
	toggled = true
	TriggerEvent('vlad_gears:enabled')
end)
-- Extra event to make sure everything is off
RegisterNetEvent('vlad_gears:deactivate')
AddEventHandler('vlad_gears:deactivate', function()
	flagged = false
	toggled = false
	processGearbox = false
	-- doesn't need to trigger :enabled since the thread handles shutdown itself.
end)
-- Triggered when entering vehicle by baseevents
RegisterNetEvent('vlad_gears:entered_listener')
AddEventHandler('vlad_gears:entered_listener', function(currentVehicle, currentSeat, netId)
	inVeh = true
	--vehicle = currentVehicle
	vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
	--seatIndex = currentSeat
	--cur_netId = netId
	Origin_driveforce = 0
	Origin_fDriveInertia = 0
	Origin_driveforce    = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
	Origin_fDriveInertia = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveInertia')
	Origin_fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
	if Config.CW_tuning_support then
		if exports['cw-tuning']:vehicleIsManual(vehicle) then
			toggled = true
			if debug then
				print('cw-tuning check succeeded')
			end
		end
	end
	TriggerEvent('vlad_gears:enabled')
end)
-- Triggered when exiting vehicle by baseevents
RegisterNetEvent('vlad_gears:exited_listener')
AddEventHandler('vlad_gears:exited_listener', function(currentVehicle, currentSeat, netId)
	if debug then
		print('exit ori') print(Origin_driveforce)
	end
	SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', Origin_driveforce)
	SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', Origin_fInitialDriveMaxFlatVel)
	inVeh = false
	flagged = false
	toggled = false
	processGearbox = false
end)
-- Upshift event
if clutch_only then
	AddEventHandler('vlad_gears:upshift', function()
		if processGearbox then
			if clutch_pedal_pushed then
				if debug then
					print('request_upshift')
				end
				if target_gear + 1 <= gearcount then
					if doAnimations then
						TriggerEvent('8bit_handling:gearChange', rhd)
					end
					if doSoundEffectShiftStart then
						TriggerEvent('vlad_gears:sound', vehicle)
					end
					request_upshift = true
				end
			end
		end
	end)
else
	AddEventHandler('vlad_gears:upshift', function()
		if processGearbox then
			if debug then
				print('request_upshift')
			end
			if target_gear + 1 <= gearcount then
				if doAnimations then
					TriggerEvent('8bit_handling:gearChange', rhd)
				end
				if doSoundEffectShiftStart then
					TriggerEvent('vlad_gears:sound', vehicle)
				end
				request_upshift = true
			end
		end
	end)
end
-- Downshift event
if clutch_only then
	AddEventHandler('vlad_gears:downshift', function()
		if processGearbox then
			if clutch_pedal_pushed then
				if debug then
					print('request_downshift')
				end
				if target_gear - 2 >= -1 then
					if doAnimations then
						TriggerEvent('8bit_handling:gearChange', rhd)
					end
					if doSoundEffectShiftStart then
						TriggerEvent('vlad_gears:sound', vehicle)
					end
					request_downshift = true
				end
			end
		end
	end)
else
	AddEventHandler('vlad_gears:downshift', function()
		if processGearbox then
			if debug then
				print('request_downshift')
			end
			if target_gear - 2 >= -1 then
				if doAnimations then
					TriggerEvent('8bit_handling:gearChange', rhd)
				end
				if doSoundEffectShiftStart then
					TriggerEvent('vlad_gears:sound', vehicle)
				end
				request_downshift = true
			end
		end
	end)
end
-- Timer for BaseShiftSpeed
AddEventHandler('vlad_gears:shift', function(shiftdir)
	if debug then
		print(shiftdir)
	end
	if shiftdir == 1 then
		if shifting_with_clutch_mult > 0 then
			countdownTimer((shift_time_up / timestep_ms) * shifting_with_clutch_mult)
		else
			countdownTimer(2)
		end
	elseif shiftdir == -1 then
		if shifting_with_clutch_mult > 0 then
			countdownTimer((shift_time_down / timestep_ms) * shifting_with_clutch_mult)
		else
			countdownTimer(2)
		end
	end
end)
-- Timer for Penalty Shift Speed
AddEventHandler('vlad_gears:penalty', function(shiftdir)
	--print(shiftdir)
	if shiftdir == 1 then
		if penalty > 0 then
			if not (ShiftingWithClutchMultiplier == 0) then
				countdownTimer2(((shift_time_up / timestep_ms) * remainingPercentage) * penalty)
			else
				countdownTimer2((shift_time_up / timestep_ms) * penalty)
			end
		else
			countdownTimer2(1)
		end
	elseif shiftdir == -1 then
		if penalty > 0 then
			countdownTimer2(((shift_time_down / timestep_ms) * remainingPercentage) * penalty)
		else
			countdownTimer2(1)
		end
	end
end)
-- Vehicle Stall event
AddEventHandler('vlad_gears:stall', function()
	-- Add check here for vehicle damage script compatability.
	if GetIsVehicleEngineRunning(vehicle) then
		if not IsVehicleEngineStarting(vehicle) then
			SetVehicleEngineOn(vehicle, false, true, true)
			SetVehicleCurrentGear(vehicle, target_gear)
			stalled = true
			restarted = false
		end
	end
end)
-- Vehicle restart event
AddEventHandler('vlad_gears:restart', function()
	if not GetIsVehicleEngineRunning(vehicle) then
		if not IsVehicleEngineStarting(vehicle) then
			SetVehicleEngineOn(vehicle, true, false, false)
			SetVehicleCurrentGear(vehicle, 1)
			stalled = false
			restarted = true
		end
	end
end)
-- Animations
local animList = {
	['lhd'] = {
		animDict = "veh@driveby@first_person@passenger_rear_right_handed@smg",
		animName = "outro_90r",
	},
	['rhd'] = {
		animDict = "veh@driveby@first_person@passenger_rear_left_handed@smg",
		animName = "outro_90l",
	}
}
AddEventHandler("8bit_handling:gearChange", function(hand)
	if processGearbox then
		if hand then
			hand = 'rhd'
		else
			hand = 'lhd'
		end
		RequestAnimDict(animList[hand].animDict)
		while not HasAnimDictLoaded(animList[hand].animDict) do
			Wait(0)
		end
		TaskPlayAnim(PlayerPedId(), animList[hand].animDict, animList[hand].animName, 8.0, 1.0, 500, 48, 0, 0, 0, 0)
		Wait(1000)
		StopAnimTask(PlayerPedId(), animList[hand].animDict, animList[hand].animName, 1.0)
	end
end)
-- Exports
exports('ReportCurrentGear', function()
	if inVeh and processGearbox then
		if target_gear == 0 then
			return 'N'
		elseif target_gear == -1 then
			return 'R'
		else
			return tostring(target_gear)
		end
	else
		return 'not_manual'
	end
end)
exports('ReportCurrentGearInteger', function()
	if inVeh and processGearbox then
		return target_gear
	else
		return 'not_manual'
	end
end)
exports('ReportDisplayGearInteger', function(veh)
	if inVeh and processGearbox then
		return display_gear
	else
		return 'not_manual'
	end
end)
exports('ReportDisplayGear', function()
	if inVeh and processGearbox then
		if display_gear == 0 then
			return 'N'
		elseif display_gear == -1 then
			return 'R'
		else
			return tostring(display_gear)
		end
	else
		return 'not_manual'
	end
end)
exports('ReportTargetGear', function()
	if inVeh and processGearbox then
		if storage_gear == 0 then
			return 'N'
		elseif storage_gear == -1 then
			return 'R'
		else
			return tostring(storage_gear)
		end
	else
		return 'not_manual'
	end
end)
exports('ReportTargetGearInteger', function()
	if inVeh and processGearbox then
		return storage_gear
	else
		return 'not_manual'
	end
end)
-- Syncronise Gears Section
AddStateBagChangeHandler('sync_gear', nil, function(bagName, key, value, _unused, replicated)
	if not value then return end
	local entity = GetEntityFromStateBagName(bagName)
	if entity == 0 then return end
	if debug then
		print('value: ' .. value)
	end
	local veh2 = GetVehicleIndexFromEntityIndex(entity)
	if debug then
		print(veh2)
	end
	--if not GetPedInVehicleSeat(veh2, -1) == PlayerPedId() then
	SetVehicleCurrentGear(veh2, value)

	--end
	if debug then
		print('detected_statebag_change')
	end
end)
-- Gearbox section
RegisterNetEvent('vlad_gears:enabled')
AddEventHandler('vlad_gears:enabled', function()
	if debug then
		print('vlad_gears:enabled')
	end
	--vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
	if (GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()) then
		-- Remove extra gear from upgrades section.
		if not suppressExtraGearOnlyForManuals then
			if stop_extra_gear == true then
				local is_gearbox_upg = GetVehicleMod(vehicle, 13)
				if is_gearbox_upg ~= -1 then
					local target_total_gears = GetVehicleHighGear(vehicle)
					SetVehicleHighGear(vehicle, (target_total_gears - 1))
				end
			end
		end
		if toggled then
			processGearbox = true
		else
			-- Determines if CF_GEARBOX_MANUAL is contained in advancedflags
			local flag_check = bitOper(GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags'), 1024, AND)
			if debug then
				print('flag_check: ' .. flag_check)
			end
			if flag_check == 1024 then
				processGearbox = true
				flagged = true
			else
				processGearbox = false
				flagged = false
			end
		end
		if debug then
			print('processGearbox: ')
			print(processGearbox)
		end
		if processGearbox then
			if doSpeedoToggleEvent then
				TriggerEvent('vlad_gears:speedo_toggle', true)
			end
			if debug then
				print('inVeh: ')
				print(inVeh)
			end
			if inVeh then
				-- Statebags
				vehNet = NetworkGetNetworkIdFromEntity(vehicle)
				ent = Entity(NetToVeh(vehNet))
				ent.state:set('sync_gear', current_gear, true)
				-- Manual Gearbox enabler
				Vlad_SET_TRANSMISSION_REDUCED_GEAR_RATIO(vehicle, true)
				-- RHD / LHD
				local steeringwheel = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'steeringwheel'))
				local left_right = GetOffsetFromEntityGivenWorldCoords(vehicle, steeringwheel)
				if left_right.x > 0 then rhd = true else rhd = false end
				-- Remove extra gear from upgrades section, only when manual check has passed.
				if suppressExtraGearOnlyForManuals then
					if stop_extra_gear == true then
						local is_gearbox_upg = GetVehicleMod(vehicle, 13)
						if is_gearbox_upg ~= -1 then
							local target_total_gears = GetVehicleHighGear(vehicle)
							SetVehicleHighGear(vehicle, (target_total_gears - 1))
						end
					end
				end
				local transmod_index       = -1
				local transmod_value       = 0
				local transmod_ms_up       = 0.0
				local transmod_ms_down     = 0.0
				local transmod_percent     = 0.0
				local shift_mult_up        = 0.0
				local shift_mult_down      = 0.0
				stall_timer                = 0
				-- Gets the shifting related handling.meta values
				--origin_hbrake          = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce')
				shift_mult_up              = GetVehicleHandlingFloat(vehicle, 'CHandlingData','fClutchChangeRateScaleUpShift')
				shift_mult_down            = GetVehicleHandlingFloat(vehicle, 'CHandlingData','fClutchChangeRateScaleDownShift')
				-- Converts the shift multipliers to miliseconds car needs to take to shift
				gearcount                  = GetVehicleHighGear(vehicle)
				shift_time_up              = ((0.9 / shift_mult_up) * 1000)
				shift_time_down            = ((0.9 / shift_mult_down) * 1000)
				-- Gearbox ugrades section.
				transmod_index             = GetVehicleMod(vehicle, 13)
				if transmod_index == -1 then
					transmod_value = 0
				else
					transmod_value = GetVehicleModModifierValue(vehicle, 13, transmod_index) * 0.01
				end
				transmod_percent = 1 + (transmod_value * 4)
				if transmod_percent > 1 then
					transmod_ms_up = shift_time_up / transmod_percent
					transmod_ms_down = shift_time_down / transmod_percent
				else
					transmod_ms_up = 0
					transmod_ms_down = 0
				end
				-- Modified shifttime depending on gearbox upgrades.
				shift_time_up = shift_time_up - transmod_ms_up
				shift_time_down = shift_time_down - transmod_ms_down
				-- Makes the car start in 1st
				target_gear = 1
				display_gear = 1
				local started = false
				local moved = false
				local clutch_active = false
				local clutch_ready = false
				local clutch_timer = 0
				local timer_target = 500 / timestep_ms
				-- Loop Section
				Citizen.CreateThread(function()
					while processGearbox do
						Citizen.Wait(1)
						if toggled or flagged then
							if not started then
								if GetIsVehicleEngineRunning(vehicle) then
									SetVehicleCurrentGear(vehicle, 1)
									target_gear = 1
									storage_gear = target_gear
									started = true
									if debug then
										print('started')
									end
								end
							end
							if not moved then
								if not topspeedtest then
									--ModifyVehicleTopSpeed(vehicle, (0))
								end
								moved = true
							end
							EnableControlAction(0, 363, false)
							EnableControlAction(0, 364, false)
							DisableControlAction(0, 363, true)
							DisableControlAction(0, 364, true)
							local rpm = GetVehicleCurrentRpm(vehicle)
							timestep_ms = (Timestep() * 1000)
							stall_limit_frametime = stall_limit / timestep_ms
							current_gear = GetVehicleCurrentGear(vehicle)
							-- Maximum gear
							if checkHighGear then
								gearcount = GetVehicleHighGear(vehicle)
							end
							-- UpShift
							if request_upshift then
								if debug then
									print('upshift_request_received')
								end
								target_gear = storage_gear
								if target_gear == -1 then
									target_gear = target_gear + 2
									shiftdir = shiftdir + 2
								elseif target_gear >= 1 then
									if target_gear <= gearcount then
										target_gear = target_gear + 1
										shiftdir = shiftdir + 1
									end
								end
								TriggerEvent('vlad_gears:shift', shiftdir)
								if not clutch_pedal_pushed then
									TriggerEvent('vlad_gears:penalty', shiftdir)
								end
								currently_shifting = true
								storage_gear = target_gear
								TriggerEvent('vlad_gears:shift', shiftdir)
								if not clutch_pedal_pushed then
									TriggerEvent('vlad_gears:penalty', shiftdir)
								end
								request_upshift = false
							end
							-- Downshift
							if request_downshift then
								if debug then
									print('downshift_request_received')
								end
								target_gear = storage_gear
								if target_gear == 1 then
									target_gear = target_gear - 2
									shiftdir = shiftdir - 2
								elseif target_gear >= 2 then
									target_gear = target_gear - 1
									shiftdir = shiftdir - 1
								end
								currently_shifting = true
								storage_gear = target_gear
								TriggerEvent('vlad_gears:shift', shiftdir)
								if not clutch_pedal_pushed then
									TriggerEvent('vlad_gears:penalty', shiftdir)
								end
								request_downshift = false
							end
							-- Display gear
							if not currently_shifting then
								display_gear = target_gear - shiftdir
								shiftdir = 0
							end
							-- Clutch Release Penalty
							if penalise_early_clutch then
								if IsControlJustReleased(0, 354) then
									TriggerEvent('vlad_gears:penalty', shiftdir)
								end
							end
							-- Shift duration
							if (remainingPercentage > 0) or (remainingPercentage2 > 0) then
								clutch_active = true
							else
								if clutch_pedal_pushed == true then
									clutch_active = true
								else
									clutch_active = false
									target_gear = storage_gear
								end
							end
							-- Shift Finished
							if (remainingPercentage == 0) and (remainingPercentage2 == 0) then
								if doSoundEffectShiftEnd then
									if currently_shifting == true then
										TriggerEvent('vlad_gears:sound', vehicle)
										display_gear = target_gear
									end
								end
								currently_shifting = false
								if ent.state.sync_gear ~= current_gear then
									ent.state:set('sync_gear', current_gear, true)
									if debug then
										print('Changed the statebag value')
									end
								end
							end
							-- Rev Limiter
							if doRevLimiter then
								--Vlad_SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS(vehicle, 1.0)
								if rpm >= 1.0 then
									limiter = true
								elseif rpm < rpmReturnThreshold then
									limiter = false
								end
								if limiter then
									if current_gear == -1 then
										DisableControlAction(0, 72, true)
									else
										DisableControlAction(0, 71, true)
									end
									--SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', 0.0)
								else
									--SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', origin_driveforce)
								end
							end
							-- Clutch ready timer
							timer_target = 500 / timestep_ms
							if clutch_timer < timer_target then
								clutch_timer = clutch_timer + 1
							end
							if clutch_timer >= timer_target then
								clutch_ready = true
							end
							-- Clutch simulation
							if clutch_ready then
								if clutch_active == true then
									local target_rpm = GetVehicleThrottleOffset(vehicle)
									--SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', 0.0001)
									if Origin_driveforce then
										SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', 0.0)
									end
									if current_gear == 0 then
										if not limiter then
											if rpm < -target_rpm then
												--SetVehicleCurrentRpm(vehicle, target_rpm)
												SetVehicleCurrentRpm(vehicle, (rpm + (-target_rpm * (Origin_fDriveInertia * 0.02))))
											end
										end
									else
										if not limiter then
											if rpm < target_rpm then
												--local delay = target_rpm 
												--SetVehicleCurrentRpm(vehicle, target_rpm)
												SetVehicleCurrentRpm(vehicle, (rpm + (target_rpm * (Origin_fDriveInertia * 0.02))))
											end
										end
									end
								else
									if not limiter then
										if Origin_driveforce then
											SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', Origin_driveforce)
										end
									end
								end
								SetVehicleMod(vehicle, 11, GetVehicleMod(vehicle, 11), false)
							end
							-- Gear Setting Section
							if current_gear ~= target_gear then
									if target_gear == -1 then
										if currently_shifting == false then
											SetVehicleCurrentGear(vehicle, 0)
										end
									elseif target_gear >= 1 then
										if currently_shifting == false then
											SetVehicleCurrentGear(vehicle, target_gear)
										end
									end
								else
							end
							-- Disable reverse section
							if suppressAutomaticReverseGear then
								local speed_vector = GetEntitySpeedVector(vehicle, true)
								if target_gear == -1 then -- while in reverse
									if speed_vector.y > -2.00 then
										DisableControlAction(0, 71, true)
									end
								else -- while in forward
									if speed_vector.y < 0.50 then
										DisableControlAction(0, 72, true)
									end
								end
							end
							-- Engine Stall Section
							if current_gear >= 2 then
								if rpm < stall_threshold then
									if not (stall_timer > (stall_limit_frametime + 1)) then
										stall_timer = stall_timer + 1
									end
									if stall_timer > stall_limit_frametime then
										if stalled == false then
											TriggerEvent('vlad_gears:stall')
											if debug then
												print('stalled')
											end
										end
									end
								else
									stall_timer = 0
								end
							end
							-- Engine shutdwon section
							if stalled then
								if IsVehicleEngineStarting(vehicle) then
									SetVehicleEngineOn(vehicle, false, true, true)
								end
								if current_gear ~= target_gear then
									if current_gear == 0 then
										target_gear = 1
										stalled = false
									end
									if target_gear == -1 then
										SetVehicleCurrentGear(vehicle, 0)
									elseif target_gear == 0 then
										SetVehicleCurrentGear(vehicle, 1)
									else
										SetVehicleCurrentGear(vehicle, target_gear)
									end
								end
							else
								--if IsVehicleEngineStarting(vehicle) then
								--	if current_gear == 0 then
								--		SetVehicleCurrentGear(vehicle, 1)
								--	end
								--end
							end
							-- Engine restart section
							if not restart_from_external_script then
								if target_gear == 1 then
									if currently_shifting == false then
										if restarted == false then
											stall_timer = 0
											-- Might want to add a wait before this to make sure it doesn't spam.
											-- Probably doesn't need to be checked eveyframe
											-- Might not actually be spamable.
											TriggerEvent('vlad_gears:restart')
											if debug then
												print('restarted engine')
											end
										end
									end
								end
							end
							-- Stall compatability Section
							if GetIsVehicleEngineRunning(vehicle) then
								stalled = false
								restarted = true
							end
							-- Last gear length fix
							if not currently_shifting then
								if current_gear == gearcount then
									if modified == false then
										if debug then
											print('modified up')
										end
										if not topspeedtest then
											--ModifyVehicleTopSpeed(vehicle, 0.888)
											SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', (Origin_fInitialDriveMaxFlatVel * 0.888))
											--SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', (Origin_fInitialDriveMaxFlatVel * 200))
										end
										modified = true
										if debug then
											print('mod' .. GetVehicleTopSpeedModifier(vehicle))
										end
									end
								else
									if modified == true then
										if debug then
											print('modified down')
										end
										if not topspeedtest then
											--ModifyVehicleTopSpeed(vehicle, (1))
											SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', (Origin_fInitialDriveMaxFlatVel))
										end
										--ModifyVehicleTopSpeed(vehicle, (-topspeedremove))
										modified = false
										if debug then
											print('mod:' .. GetVehicleTopSpeedModifier(vehicle))
										end
									end
								end
						end
						else -- When manual should be disabled shutdown and cleanup
							if doSpeedoToggleEvent then
								TriggerEvent('vlad_gears:speedo_toggle', false)
							end
							target_gear = 1
							if modified == true then
								if not topspeedtest then
									--ModifyVehicleTopSpeed(vehicle, (0))
								end
								modified = false
							end
							--if limiter then
							--	EnableControlAction(0, 71, true)
							--end
							Vlad_SET_TRANSMISSION_REDUCED_GEAR_RATIO(vehicle, false)
							flagged = false
							toggled = false
							processGearbox = false
						end
					end
				end)
			end
		else
			Vlad_SET_TRANSMISSION_REDUCED_GEAR_RATIO(vehicle, false)
			local temp = true
			if temp then
				-- if GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce') ~= 0 then
				if Origin_driveforce ~= 0 then
					if debug then
						print(Origin_driveforce)
					end
					SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', Origin_driveforce)
				end
			end
		end
	end
end)
