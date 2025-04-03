## vlad_gears by vladimirkedrov
### Support Discord: https://discord.gg/4MfzRfR7zU

### Description
Creates a system that allows players to convert their vehicles from automatic into manual with shifting and clutch controlled by FiveM keybinds.

Available for any ground vehicle, excluding military, boat, aircraft ect.

Individual gears are not simulated; the vehicle actually changes gears while maintaining default GTA 5 gear ratios.

Enabling the system can be done either through a /manual_trans command that instantly toggles the manual_gearbox.

Alternatively the script can check for the CF_GEARBOX_MANUAL advanced flag, if it is present the manual gearbox will be enabled permanently without the need of a command.

The script is configurable to encourage different player behavior or to control what features are enabled or not. For example you can disable the need to use the clutch if you want to shift without needing to consider it.

### Requirements
Gamebuild 3095+ (ChopShop update)
baseevents (from cfx default resources)

### Support Discord
https://discord.gg/4MfzRfR7zU

### Features
#### Clutch simulation:
When pressed the car will rev dependent on vehicle throttle but only extremely minimal power will be applied to the wheels.

#### Dynamic shifting duration depending on clutch usage:

If you don’t use the clutch before shifting the vehicle will take longer to shift.

Optionally the shift duration will also increase if the clutch is released before the shift has completed depending on how close the shift was to completing.

Shift duration both for with and without clutch usage is configurable. By default the shift duration is the same as automatic when not using the clutch.


#### Synchronized current gear for all players:
Regardless of if the player is the driver or not the vehicle will sound like it is in the correct gear. (It won’t sound like it is stuck in 1st gear)

#### Rev Limiter:
Throttle will be cut when the vehicle reaches the end of the rpm range for each gear. 
When above the top speed for each gear the vehicle will slow down due to normal engine braking.

#### Engine stalling:
If the vehicle drops below a RPM threshold for longer than the duration set in the config the engine will shut off.

It will restart after shifting to 1st gear.

Stall only occurs in gears 2nd and above, RPM threshold and duration are configurable. (Disabling the stall feature is possible)

#### Animations:
When the player shifts their ped will play an animation. Works for RHD and LHD.

#### Sound effect:
Plays a sound when the vehicle shift starts or completes. In default configuration it only plays when the shift had completed.

#### Extra gear from upgrades remover.
In default GTA5 after adding any LS customs /carcols.meta gearbox upgrade the total amount of gears available to a vehicle will increase by 1.

As an optional feature the script will check if it has a gearbox upgrade and remove the extra gear it had gained.
Available for all vehicles or configurable to only apply  to vehicles with a manual gearbox.

#### Speedometer integration:
Due to how the neutral gear and the gear shift is simulated current gear indications may be wrong.

To alleviate this issue the script includes exported functions for speedometer resources to use that show the actual current gear.

Alternatively vlad_speedometer https://github.com/VladimirKedrov/vlad_speedometer includes integration options out of the box. 
As displayed in the preview video.

Also included is a user configurable event that triggers when the speedometer should be shown for a manual gearbox vehicle.
By default it is set to trigger an export from vlad_speedometer.


### How to enable manual gearbox.
#### Method 1
    Use jim-mechanic: Apply the "manual" upgrade to your vehicle and vlad_gears will enable while its applied.

#### Method 2

    Use /manual_trans command to toggle the manual transmission.
    However the vehicle will reset back to automatic after exiting the vehicle.
    Requires access to the ace_permission command.manual_trans

    Example ace permission configuration below:
    
    add_ace group.manual_gearbox_toggle command.manual_trans allow
    
    add_principal qbcore.god group.manual_gearbox_toggle
    (identifier is the ACE group you desire from your allow command)
    
    add_principal identifier.fivem:9999999 group.manual_gearbox_toggle
    (user identifier is used to allow command)

#### Method 3

    Add CF_GEARBOX_MANUAL advanced flag to the vehicles handling.meta- 
    -that you want to apply the manual gearbox to.

    Hexcode that you need is "400"
    If you need to find the hexcode for multiple flags at the same time use this tool.

    https://adam10603.github.io/GTA5VehicleFlagTool/ Under Advanced Flags, IKT lookup table.

    Add the hexcode to the advanced flags section under the "SubHandlingData".
    It should look like the below example.

    <SubHandlingData>
        <Item type="CCarHandlingData">
            <strAdvancedFlags>400</strAdvancedFlags>
        </Item> 
    </SubHandlingData>

    If you have other lines in the SubHandlingData Section you don't have to remove them.
    Just make sure the strAdvancedFlags line is set to 400 
    or whatever hexcode you create from the GTA5VehicleFlagTool.

    After this is complete then after you enter the vehicle it will-
    -have a manual transmission permanently enabled.

#### Method 4


### How to use vlad_gears exports
vlad_gears includes a export that returns the current gear.\
It fallsback to printing a 'not_manual' string if vlad_gears isn't controlling the gearbox.\
This is so you avoid having to get the vehicle id twice.\
Example implementaion is in https://github.com/VladimirKedrov/vlad_speedometer

    If you want to get the current gear or the target gear as a string then use:
        exports.vlad_gears:ReportDisplayGear -- Returns a string of R N 1 2 3 etc
        -- Reverse = 'N' Neutral = 'N'

    If you want to get the current gear or the target gear as a integer then use:
        exports.vlad_gears.ReportDisplayGearInteger() -- Returns a integer of -1 0 1 2 3
        -- Reverse = -1 , Neutral = 0 , Other gears are the same as normal.


### Configuration options explained

#### Default controls: (Rebind-able in FiveM Keybinds)
Change the default keybinds here, check below for valid things to set the controls to.\
https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/

    Config.DefaultShiftUp = 'Y'
    Config.DefaultShiftDown = 'X'
    Config.DefaultClutch = 'LCONTROL'

#### Command
    Config.AllowCommand = true -- Default: true
        When enabled the /manual_trans command will function.
        It will still however check to see if the player has the relevant permissions.

    Config.CommandRestricted = true -- Default: true
        When enabled the command will be ace permission restricted.

#### Difficulty Options
    Config.ShiftingNoClutchMultiplier = 1.0 -- Default: 1.0
        1.0 = Same amount of time as if the car was automatic.
        2.0 = Twice the amount of time.
        0.5 = Half the amount of time.

        When shifting without using the clutch before shifting,
        total time taken shifting is controlled by this multiplier. 
<b></b>

    Config.ShiftingWithClutchMultiplier = 0.5 -- Default: 0.5
        1.0 = Same amount of time as if the car was automatic.
        2.0 = Twice the amount of time.
        0.5 = Half the amount of time.
        When shifting while using the clutch before you shift, 
        total time taken shifting is controlled by this multiplier.
<b></b>

    Config.PenaliseReleasingClutchEarly = false -- Default: false
        While this is enabled if you release the clutch before the gearshift is complete.
        Total gearshift time will be equal to the ClutchMisusePenalty total shift time.

        However if the clutch is released after 50% of the gearshift is complete,
        then the total gearshift time will be 50% of the ClutchMisusePenalty total shift time.
<b></b>

    Config.StallThreshold = 0.22 -- Default: 0.22
        If rpm falls below this value while in 2nd and above gears the car will stall.
        RPM range is between 0.0 and 1.0.
        0.00 = Never stall
        0.25 = Stall when the rpm drops below 25% of max rpm.
<b></b>

    Config.StallTimer = 1000 -- Default: 1000
        Vehicle will stall if the vehicle stays below the rpm threshold for this amount of milliseconds
<b></b>

    Config.RevLimiter = true -- Defuault: true
        When enabled vehicles will not be able to exceed the top speed of the current gear.
<b></b>

    Config.ClutchOnly = false -- Default: false
        When enabled it is impossible to start a shift without first pressing the clutch.
<b></b>

#### Config options
    Config.CW_tuning_support = false -- Default: false
        This isn't functional, this is present only to integrate with a possible future cw-tuning update.
        If you use cw-tuning enable this to allow vlad_gears to check if the manual gearbox upgrade is applied.
        If the upgrade is present then vlad_gears will handle the gearbox.
<b></b>

    Config.SurpressAutomaticReverseGear = true -- Default: true
        Disable this if another script prevents the car from automatically shifting-
        -into reverse when it is near stopped.
<b></b>

    Config.SuppressExtraGearFromGearboxUpgrade = false -- Default: false
        When this is enabled cars do not gain a extra gear from gearbox upgrades.
        
    Config.SurpressExtraGearOnlyForManuals = false -- Default false
        Enable this to prevent gaining extra gears only if the vehicle has a manual transmission.
        
    Config.CheckHighGear = false -- Default: false
        When enabled the script will check the amount of gears the car should have constantly.
        When this is disabled the gearcount will only update after exiting and entering a vehicle.
        Keep it disabled to reduce resource consumption, enabled when testing upgrades.
<b></b>

    Config.RestartFromStallInExternalScript = false -- Default: false
        If you want to stop the car restarting from a stall when it enters 1st gear then enable this.
        You will need a external script to restart the engine if this is enabled.
<b></b>

    Config.DoAnimations = true -- Default: true
        Controls if animations are played when the player shifts.
<b></b>

    Config.DoSoundEffectShiftStart = false -- Default: false
        Triggers a sound effect when a shift has started.
    Config.DoSoundEffectShiftEnd = true -- Default: true
        Triggers a sound effect when a shift has completed.
<b></b>

    Config.SpeedoAutoToggle = false -- Default: false
        When enabled script will trigger the speedo_toggle event in events.lua.
        This occurs when the speedometer should be toggled.
        By default set to work with vlad_speedometer, change it in events.lua to what you need.

    Config.RevLimiter = true  -- Default: true
        Enforces speed caps per gear. Throttle will be disabled if rpm has reached maximum rpm.
<b></b>

    Config.rpmReturnThreshold = 0.95 -- Default: 0.95
        When using rev limiter: if the rpm reaches 1.0 or above (maximum rpm)-
        -The throttle will be cut until the rpm drops below the rpmReturnThreshold
        Reccomend changing this if you don't like the sound of the rev-limiter
        or if you want backfires to happen more or less frequently.
<b></b>

#### Debug Options

    Config.client_debug = false -- Default: false
        Client debug ui and F8 console output toggle.
     Interface will update after exiting and re-entering vehicle.
<b></b>

    Config.server_debug = false -- Default: false
        Server console debug output toggle.


### Examples of various difficulty settings.

##### Default Difficulty (Using the clutch is optional)
    Config.ShiftingNoClutchMultiplier = 1.0
    Config.ShiftingWithClutchMultiplier = 0.5
    Config.PenaliseReleasingClutchEarly = false
    Config.StallThreshold = 0.22
    Config.StallTimer = 1000

##### Hard Mode (Important to release clutch at right time)
    Config.ShiftingNoClutchMultiplier = 2.0
    Config.ShiftingWithClutchMultiplier = 1.0
    Config.PenaliseReleasingClutchEarly = true
    Config.StallThreshold = 0.26
    Config.StallTimer = 800

##### Easy Mode (No clutch mode)
    Config.ShiftingNoClutchMultiplier = 1.0
    Config.ShiftingWithClutchMultiplier = 1.0
    Config.PenaliseReleasingClutchEarly = false
    Config.StallThreshold = 0.00
    Config.StallTimer = 1000
    
##### Alternative Mode (Shifting is near instant when using the clutch)
    Config.ShiftingNoClutchMultiplier = 1.0
    Config.ShiftingWithClutchMultiplier = 0.1
    Config.PenaliseReleasingClutchEarly = false
    Config.StallThreshold = 0.22
    Config.StallTimer = 1000
