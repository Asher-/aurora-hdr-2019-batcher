local LrApplication = import("LrApplication")
local LrTasks = import("LrTasks")
local LrPathUtils = import("LrPathUtils")
local LrFileUtils = import("LrFileUtils")
local LrStringUtils = import("LrStringUtils")

g_AuroraHDR2019Batcher_keywords = nil

function processBatchExport()
  processActivePhotos()
end

function processActivePhotos()

	local catalog = LrApplication.activeCatalog()
	local activePhoto = catalog:getTargetPhoto()

	if activePhoto
	then
		initProcessActivePhotos()

		local photos = catalog:getTargetPhotos()
		if photos
		then
			if collectPhotoDetails( photos )
			then
				command = commandString( activePhoto, collectPhotoBracket( photos ) )
        LrTasks.execute(command)
			end
		end
	end
end

function initProcessActivePhotos()
	prepareTempFile()
	g_AuroraHDR2019Batcher_collections = nil
end

function collectPhotoDetails( photos )
	local size = 0
	for index, photo in pairs(photos) do
		size = size + 1
		collectPhotoCollections( photo )
		collectPhotoKeywords( photo )
	end
	return size
end

function collectPhotoCollections( photo )
	if g_AuroraHDR2019Batcher_collections == nil then
		g_AuroraHDR2019Batcher_collections = photo:getContainedCollections()
	else
		g_AuroraHDR2019Batcher_collections = intersectArrays(g_AuroraHDR2019Batcher_collections, photo:getContainedCollections())
	end
end

function collectPhotoKeywords( photo )
	if g_AuroraHDR2019Batcher_keywords == nil then
		g_AuroraHDR2019Batcher_keywords = photo:getRawMetadata("keywords")
	else
		g_AuroraHDR2019Batcher_keywords = intersectArrays(g_AuroraHDR2019Batcher_keywords, photo:getRawMetadata("keywords"))
	end
end

function collectPhotoBracket( photos )
	local bracket = ""
	for index, photo in pairs(photos) do
		local photoPath = photo.path
		bracket = bracket .. string.len(photoPath) .. ":" .. photoPath
	end
	return bracket
end

function commandString( activePhoto, bracket )
	local command = ""
  local activePhotoPath = activePhoto.path
	if string.len(bracket) > 0 then
    local importFileName = importTempFileName()
		local base_command = "/Library/Application\\ Support/MacPhun\\ Software/AuroraHDR2019/Plug-Ins/AuroraHDR2019 \"" .. activePhotoPath .. "\" -MPLightroomExtrasPluginResPath " .. importFileName
	  local bracketCommandString = "-MPHDRBracket " .. LrStringUtils.encodeBase64(bracket)
		command = base_command .. " " .. bracketCommandString
	end
	return command
end

function importTempFileName()
  local standardTempDirPath = LrPathUtils.getStandardFilePath('temp')
  local importFileName = LrPathUtils.child(standardTempDirPath, "ImportAuroraHDR2019")
  return importFileName
end

function prepareTempFile( importFileName )
    local importFileName = importTempFileName()

		if LrFileUtils.exists(importFileName)
		then
		  LrFileUtils.delete(importFileName)
		end

		return importFileName
end

LrTasks.startAsyncTask(processActivePhotos)
