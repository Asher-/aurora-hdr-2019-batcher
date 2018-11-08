local LrTasks = import("LrTasks")
local LrPathUtils = import("LrPathUtils")
local LrXml= import("LrXml")
local LrFileUtils = import("LrFileUtils")
local LrApplication	= import "LrApplication"
local LrDate = import 'LrDate'

g_AuroraHDR2019_presets = {}
g_AuroraHDR2019_presetGroups = {}
g_AuroraHDR2019_presetsLoaded = false
g_AuroraHDR2019Batcher_collections = nil

function loadPresets()
	local standardTempDirPath = LrPathUtils.getStandardFilePath('temp')
	local presetsInfoFilePath = LrPathUtils.child(standardTempDirPath, "AuroraHDR2019ExtrasPresetsInfo.xml")
	LrFileUtils.delete(presetsInfoFilePath)

	local command =  "/Library/Application\\ Support/MacPhun\\ Software/AuroraHDR2019/Plug-Ins/AuroraHDR2019" .. " -MPExportPresets \"" .. presetsInfoFilePath .. "\"" .. " -MPWait" .. " -MPAppBundlePath \"" .. "/Applications/Aurora HDR 2019.app\""

	LrTasks.execute(command)

	local f = io.open(presetsInfoFilePath, 'r')
	if not f then
		return {}
	end
	local xml = f:read('*a')
	f:close()


	local root = LrXml.parseXml(xml)
	local parsedRoot = parseNode(root)
	if parsedRoot ~= nil then
		local count = 0
		for Index, Value in pairs( parsedRoot ) do
		  count = count + 1
		end

		local index = 1
		while index <= count do
			local groupName = parsedRoot[index]
			index = index + 1
			if index > count then break end
			local presets = parsedRoot[index]
			table.insert(g_AuroraHDR2019_presetGroups, groupName)
			table.insert(g_AuroraHDR2019_presets, presets)
			index = index + 1
		end
	end
	g_AuroraHDR2019_presetsLoaded = true
end

function parseNode(node)
	local result = nil
	local nodeName = node:name()
	if nodeName == "plist" then
		local count = node:childCount()
		if count == 1 then
			local child = node:childAtIndex(1)
			result = parseNode(child)
		end
	elseif nodeName == "string" then
		result = node:text()
	elseif nodeName == "array" then
		result = {}
		local count = node:childCount()
		local index = 1
		while index <= count do
			local parsedChild = parseNode(node:childAtIndex(index))
			if parsedChild ~= nil then
				table.insert(result, parsedChild)
			end
			index = index + 1
		end
	elseif nodeName == "dict" then
		result = {}
		local count = node:childCount()
		local index = 1
		while index <= count do
			local keyNode = node:childAtIndex(index)
			local keyNodeName = keyNode:name()
			if keyNodeName == "key" then
				local key = keyNode:text()
				index = index + 1
				if index > count then break end
				local value = parseNode(node:childAtIndex(index))
				if value ~= nil then
					result[key] = value
				end
			end
			index = index + 1
		end
	end

	return result
end

--Import Section--------------------------------------------------------------------------

function tryToImportFromFile(fileName)
	if LrFileUtils.exists(fileName) then
		LrTasks.startAsyncTask(function(context)
			local catalog = LrApplication.activeCatalog()
			local photo = nil;
			catalog:withWriteAccessDo("0",
				function(context)
					photo = catalog:addPhoto(fileName, nil, nil)
				  	if photo ~= nil then
						if g_AuroraHDR2019Batcher_keywords ~= nil then
							local currentKeywords = photo:getRawMetadata("keywords")
							if (numberOfElementsInArray(currentKeywords) == 0) and (numberOfElementsInArray(g_AuroraHDR2019Batcher_keywords) > 0) then
								for k, v in pairs(g_AuroraHDR2019Batcher_keywords) do
									photo:addKeyword(v)
								end
							end
							g_AuroraHDR2019Batcher_keywords = nil
						end
						if g_AuroraHDR2019Batcher_collections ~= nil then
							for k, v in pairs(g_AuroraHDR2019Batcher_collections) do
								v:addPhotos({photo})
							end
							g_AuroraHDR2019Batcher_collections = nil
						end
					end
				end
			)
			if photo ~= nil then
				catalog:setSelectedPhotos(photo, {photo})
			end

		end)
	end
end


local LrMobdebug = import("LrMobdebug")
LrMobdebug.on()
LrMobdebug.start()

local standardTempDirPath = LrPathUtils.getStandardFilePath('temp')
local importFileName = LrPathUtils.child(standardTempDirPath, "ImportAuroraHDR2019")

tryToImportFromFile(importFileName)

--g_AuroraHDR2019_isPluginRunning is used since async task can be running even after plug-in shutdown
g_AuroraHDR2019_isPluginRunning = 1

LrTasks.startAsyncTask(function()
	while g_AuroraHDR2019_isPluginRunning == 1 do
		if LrFileUtils.exists(importFileName) then
			local photoPath = LrFileUtils.readFile(importFileName)
			tryToImportFromFile(photoPath)
			LrFileUtils.delete(importFileName)
		end
		--sleep for 1 second
		LrTasks.sleep(1)
  end
end)

LrTasks.startAsyncTask(function()
  loadPresets()
end)
