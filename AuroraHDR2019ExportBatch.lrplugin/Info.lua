menuItems = {
	{
		title = LOC("$$$/AuroraHDR2019/ExportMenuTitle=Batch Transfer to Aurora HDR 2019"),
		file = "ExportMenuItem.lua",
		enabledWhen = "photosAvailable"
	},
}

return {

	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'ai.strong.exportAuroraHDR2019BatcherPlugin',

	LrPluginName = LOC("$$$/AuroraHDR2019Extras/PluginName=Aurora HDR 2019 Batcher"),

	-- Add the menu item to the File menu.

	LrExportMenuItems = menuItems,  -- Add to File => Plugin-Extras
	LrLibraryMenuItems = menuItems, -- Add to Library => Plugin-Extras
	LrInitPlugin = "Startup.lua",
	LrShutdownPlugin = "Shutdown.lua",

	VERSION = { display = "1.0.1", }, -- Derived from AuroraHDR2019Plugin 1.0.1
}
