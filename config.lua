Config = {}

-- See readme.md for details on what the config options do.

--  Debug Options
Config.client_debug = false -- Default: false
Config.server_debug = false -- Default: false
--  Control defaults. 
--  Check below for valid things to set the controls to.
--  https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
Config.DefaultShiftUp = 'C'
Config.DefaultShiftDown = 'V'
Config.DefaultClutch = 'LSHIFT'
--  Difficulty Options
Config.ShiftingNoClutchMultiplier = 1.0 -- Default: 1.0
Config.ShiftingWithClutchMultiplier = 0.5 -- Default: 0.5    
Config.PenaliseReleasingClutchEarly = false -- Default: false
Config.StallThreshold = 0.22 -- Default: 0.22
Config.StallTimer = 1000 -- Default: 1000
Config.ClutchOnly = false -- Default: false
--  Config options
Config.CW_tuning_support = false -- Default: false
Config.AllowCommand = true -- Default: true
Config.CommandRestricted = true -- Default: true
Config.SuppressAutomaticReverseGear = true -- Default: true
Config.SuppressExtraGearFromGearboxUpgrade = false -- Default: false
Config.SuppressExtraGearOnlyForManuals = false -- Default: false
Config.RestartFromStallInExternalScript = false -- Default: false
Config.DoAnimations = true -- Default: true
Config.DoSoundEffectShiftStart = false -- Default: false
Config.DoSoundEffectShiftEnd = true -- Default: true
Config.CheckHighGear = false -- Default: false
Config.SpeedoAutoToggle = false -- Default: false
Config.RevLimiter = true  -- Default: true
Config.rpmReturnThreshold = 0.95 -- Default: 0.95
-- testing
Config.topspeedtest = false -- Debugging for last gear length fix Default: false
--  Examples of various difficulty settings.

--  Default Difficulty Settings (Using the clutch is optional)
--      Config.ShiftingNoClutchMultiplier = 1.0
--      Config.ShiftingWithClutchMultiplier = 0.5
--      Config.PenaliseReleasingClutchEarly = false
--      Config.StallThreshold = 0.22
--      Config.StallTimer = 1000
--  
--  Medium Difficulty Settings
--      Config.ShiftingNoClutchMultiplier = 1.5
--      Config.ShiftingWithClutchMultiplier = 0.5
--      Config.PenaliseReleasingClutchEarly = false
--      Config.StallThreshold = 0.22
--      Config.StallTimer = 1000
--
--  Hard Mode Settings (Important to release clutch at right time)
--      Config.ShiftingNoClutchMultiplier = 2.0
--      Config.ShiftingWithClutchMultiplier = 1.0
--      Config.PenaliseReleasingClutchEarly = true
--      Config.StallThreshold = 0.26
--      Config.StallTimer = 800
--  
--  Easy Mode Settings (No clutch mode)
--      Config.ShiftingNoClutchMultiplier = 1.0
--      Config.ShiftingWithClutchMultiplier = 1.0
--      Config.PenaliseReleasingClutchEarly = false
--      Config.StallThreshold = 0.00
--      Config.StallTimer = 1000
--  
--  Alternative Mode Settings (Shifting is near instant when using the clutch)
--      Config.ShiftingNoClutchMultiplier = 1.0
--      Config.ShiftingWithClutchMultiplier = 0.1
--      Config.PenaliseReleasingClutchEarly = false
--      Config.StallThreshold = 0.22
--      Config.StallTimer = 1000