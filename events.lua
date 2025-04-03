-- If you don't use vlad_speedo change the export to another speedometer resources toggle export
AddEventHandler('vlad_gears:speedo_toggle', function(state)
    exports.vlad_speedometer:ToggleSpeedoExternal(state)
end)

-- Event will be triggered when manual gearbox is active and state will = true
-- Or will be triggered when exiting vehicle and state will = false

-- If you want to change what sound is played you can edit this event.
AddEventHandler('vlad_gears:sound', function(vehicle)
    PlaySoundFromEntity(-1, "COLLECT_IN_BAG", vehicle, "NIGEL_1D_SOUNDSET", false, 0)
end)
