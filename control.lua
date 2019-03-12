UpdateSetting = function(settingName)
	--if settingName == "xxxxx" or settingName == nil then
	--	local x = tonumber(settings.global["xxxxx"].value) 
	--end
end


CreateGlobals = function()
	if global.MOD == nil then global.MOD = {} end
end


OnStartup = function()
	CreateGlobals()
	UpdateSetting(nil)
end


OnSettingChanged = function(event)
	UpdateSetting(event.setting)
end


script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)