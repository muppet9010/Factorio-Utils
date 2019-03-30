local function UpdateSetting(settingName)
    --if settingName == "xxxxx" or settingName == nil then
    --	local x = tonumber(settings.global["xxxxx"].value)
    --end
end

local function CreateGlobals()
    global.Mod = global.Mod or {}
end

local function OnStartup()
    CreateGlobals()
    UpdateSetting(nil)
end

local function OnSettingChanged(event)
    UpdateSetting(event.setting)
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)