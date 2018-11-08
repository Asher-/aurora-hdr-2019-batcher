local LrApplication = import("LrApplication")
local LrTasks = import("LrTasks")
local LrPathUtils = import("LrPathUtils")
local LrFileUtils = import("LrFileUtils")
local LrStringUtils = import("LrStringUtils")
local LrSelection = import("LrSelection")

--local LrMobdebug = import("LrMobdebug")

g_AuroraHDR2019Batcher_keywords = nil

function processBatchExport()
  local bracket = 8
  local max = 30

	local catalog = LrApplication.activeCatalog()
  local activePhoto = catalog:getTargetPhoto()

  for i=1,max do
      if activePhoto
      then
        LrSelection.deselectOthers()
        LrSelection.extendSelection( "right", bracket - 1 )
        processActivePhotos()
        LrSelection.deselectOthers()
        if attemptAdvanceMultiple( catalog, activePhoto, bracket ) == nil
        then
          LrSelection.selectNone()
          break
        end
      end
  end

end

function attemptAdvanceMultiple( catalog, activePhoto, count )
  for i=1,count do
    activePhoto = attemptAdvance( catalog, activePhoto )
    if activePhoto == nil
    then
      return nil
    end
  end
  return activePhoto
end

function attemptAdvance( catalog, activePhoto )
  LrSelection.nextPhoto()
	local nextActivePhoto = catalog:getTargetPhoto()
  if nextActivePhoto == activePhoto
  then
    return nil
  else
    return nextActivePhoto
  end
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

  local contained_collections = photo:getContainedCollections()

	if g_AuroraHDR2019Batcher_collections == nil then
		g_AuroraHDR2019Batcher_collections = contained_collections
	elseif contained_collections ~= nil then
		g_AuroraHDR2019Batcher_collections = intersectArrays(g_AuroraHDR2019Batcher_collections, contained_collections)
	end
end

function collectPhotoKeywords( photo )

  local photo_keywords = photo:getRawMetadata("keywords")

	if g_AuroraHDR2019Batcher_keywords == nil then
		g_AuroraHDR2019Batcher_keywords = photo_keywords
	elseif photo_keywords ~= nil then
		g_AuroraHDR2019Batcher_keywords = intersectArrays(g_AuroraHDR2019Batcher_keywords, photo_keywords)
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
  local importFileName = LrPathUtils.child(standardTempDirPath, "ImportAuroraHDRBatcher2019")
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

function intersectArrays(array1, array2)
	local result = {}
	local count = 0
	if array1 ~= nil and array2 ~= nil then
		for k1, v1 in pairs(array1) do
			for k2, v2 in pairs(array2) do
				if v1 == v2 then
					result[count] = v1
					count = count + 1
					break
				end
			end
		end
	end
	return result
end

LrTasks.startAsyncTask(processBatchExport)
