local LrApplication = import("LrApplication")
local LrTasks = import("LrTasks")
local LrPathUtils = import("LrPathUtils")
local LrFileUtils = import("LrFileUtils")
local LrStringUtils = import("LrStringUtils")
g_AuroraHDR2019_extras_keyrwords = nil

LrTasks.startAsyncTask(function()
	local catalog = LrApplication.activeCatalog()
	local tPhoto = catalog:getTargetPhoto()
	if tPhoto
	then
		local tPhotoPath = tPhoto.path
		local standardTempDirPath = LrPathUtils.getStandardFilePath('temp')
		local importFileName = LrPathUtils.child(standardTempDirPath, "ImportAuroraHDR2019")

		if LrFileUtils.exists(importFileName)
		then
		  LrFileUtils.delete(importFileName)
		end
		local command = "/Library/Application\\ Support/MacPhun\\ Software/AuroraHDR2019/Plug-Ins/AuroraHDR2019 \"" .. tPhotoPath .. "\" -MPLightroomExtrasPluginResPath " .. importFileName
		local tPhotos = catalog:getTargetPhotos()
		g_AuroraHDR2019_extrasCollections = nil
		if tPhotos
		then
			local size = 0
			for index, photo in pairs(tPhotos) do
				size = size + 1
				if g_AuroraHDR2019_extrasCollections == nil then
					g_AuroraHDR2019_extrasCollections = photo:getContainedCollections()
				else
					g_AuroraHDR2019_extrasCollections = intersectArrays(g_AuroraHDR2019_extrasCollections, photo:getContainedCollections())
				end
				if g_AuroraHDR2019_extras_keyrwords == nil then
					g_AuroraHDR2019_extras_keyrwords = photo:getRawMetadata("keywords")
				else
					g_AuroraHDR2019_extras_keyrwords = intersectArrays(g_AuroraHDR2019_extras_keyrwords, photo:getRawMetadata("keywords"))
				end
			end
			if size > 1
			then
				local bracket = ""
				for index, photo in pairs(tPhotos) do
					local photoPath = photo.path
					bracket = bracket .. string.len(photoPath) .. ":" .. photoPath
				end
				if string.len(bracket) > 0 then
					command = command .. " -MPHDRBracket " .. LrStringUtils.encodeBase64(bracket)
				end
			end
		end
		LrTasks.execute(command)
	end
end)