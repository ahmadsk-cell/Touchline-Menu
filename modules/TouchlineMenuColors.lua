-- Bundled for Touchline Menu: original UIColors 1.1 by Zlac (credits below).
-- Only the palette and native-file roots are namespaced for this distribution.
-- The shipped ui_bin_colors.ini is empty: native colors are already in the assets.
-- PES 2021 ui text colors changer by Zlac, 2024-
-- Research: SoulBallZ, milos987, jovic1901, afandix, hyun93222
-- originally posted on evo web forums

local m = { }
m.version = "1.1"


local ui_colors_root = ".\\content\\touchline-menu\\"
m.ui_exe_colors_map = {}
local info_text = ""
local last_used_exe_colors_map = {}

m.ui_bin_colors_map = {}
local ui_bin_files_root = ".\\livecpk\\TouchlinePrologue2\\"

local RELOAD_MAPS_KEY = 0x30 -- 0 key (not the NUMPAD zero!!)
local DEL_TEXT_KEY = 0x2E

local detailed_logging = false  -- change to false to see less logging entries/or true to see detailed log messages
m.bins_processed = false

-- UTILITIES
local function trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

local function nil2str(value)
    if value ~= nil then
        return value
    else
        return "N/A"
    end
end

local function get_common_lib(ctx)
    return ctx.common_lib or _empty
end

-- log only if detailed logging is selected in variable detailed_logging
local function _log(msg)
	if detailed_logging == true then
		log(msg)
	end
end

local function split(s, inSplitPattern)
	local outResults = {}
	-- chop off the trailing comment, if present
	local theCommentStart = string.find( s, "#", 1 )
	local data = s
	if theCommentStart ~= nil then
		data = string.sub(s, 1, theCommentStart-1)
	end

   -- now do the splits by main separator (inSplitPattern)
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( data, inSplitPattern, theStart )
	while theSplitStart do
		outResults[#outResults+1] = trim(string.sub( data, theStart, theSplitStart-1 ))
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( data, inSplitPattern, theStart )
	end
	outResults[#outResults+1] = trim(string.sub( data, theStart ))
	return outResults
end

local function clear_table(t)
    for k,v in pairs(t) do
        t[k]=nil
    end
end

local function dump_table(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump_table(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

local function table_copy(t)
    local new_t = {}
    for k,v in pairs(t) do
        new_t[k] = v
    end
    return new_t
end

local function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

local function load_map_txt(ctx, filename, external_source)
    local delim = ","
	local data
	
	if not external_source then
		data = assert(io.lines(ui_colors_root .. filename))
		log(filename .. " found in " .. ui_colors_root)
	else
		if external_source == "MenuServer" then
			if ctx.MenuServer and ctx.MenuServer['menu_path'] then
				log("(load_map_txt) Called externally (menuserver), 'menu_path': " .. ctx.MenuServer['menu_path'])
				if file_exists(ctx.MenuServer['menu_path'] .. "\\" .. filename) then
					log("External " .. filename .. " found in " .. ctx.MenuServer['menu_path'])
					data = io.lines(ctx.MenuServer['menu_path'] .. "\\" .. filename)
				else
					log("External " .. filename .. " not found in " .. ctx.MenuServer['menu_path'])
					return nil
				end
			end
		end
	end

    --if string.lower(filename) == string.lower("map_exe.txt") then
    --    clear_table(m.ui_exe_colors_map)
    --end

	local t = {}
	if data then 
		for line in data do
			line = trim(string.gsub(line, "^\239\187\191", "")) -- removes UTF BOM bytes at the beginning of the first line in .txt file and leading/trailing whitespaces in every line
			local fields = split(line, delim)
			if #fields > 1 then
				for i=1,#fields do
					fields[i] = trim(fields[i])
				end

				if fields[1] ~= nil and fields[1] ~= "" then
					if tonumber(fields[1]) < 1 or tonumber(fields[1]) > 80 then
						log(string.format(" ==> invalid color_index %s in line '%s, %s'. Skipping this assignment", fields[1], fields[1], fields[2]))
					else
						if string.lower(filename) == string.lower("map_exe.txt") and fields[2] ~= nil then --and #fields[2] == 8 then
							if t[tonumber(fields[1])] ~= nil then
								table.insert(t[tonumber(fields[1])], fields[2])
							else
								t[tonumber(fields[1])] = { fields[2] }
							end
							log(string.format(" ==> UI color assignment::  color_index: %s, color_value: %s", fields[1], fields[2]))
						else
							log(string.format(" ==> invalid color_value %s for color_index %s. Skipping this assignment", fields[2], fields[1]))
						end
					end				
				end
			end
		end
	else
		log("Unable to read data from " .. filename)
	end
	
	return t
end


local function load_ini_file(ctx, filename, external_source)
	local data	
	
	if not external_source then
		data = assert(io.lines(ui_colors_root .. filename))
		log(filename .. " found in " .. ui_colors_root)
	else
		if external_source == "MenuServer" then
			if ctx.MenuServer and ctx.MenuServer['menu_path'] then
				log("(load_ini_file) Called externally (menuserver), 'menu_path': " .. ctx.MenuServer['menu_path'])
				if file_exists(ctx.MenuServer['menu_path'] .. "\\" .. filename) then
					log("External " .. filename .. " found in " .. ctx.MenuServer['menu_path'])
					data = io.lines(ctx.MenuServer['menu_path'] .. "\\" .. filename)
				else
					log("External " .. filename .. " not found in " .. ctx.MenuServer['menu_path'])
					return nil
				end
			end
		end
	end
	
	--if string.lower(filename) == string.lower("ui_bin_colors.ini") then
    --    clear_table(t)
    --end
	
	-- inspired by: https://santoslove.github.io/inifile.html
	local t = {}
	local sec
	for line in data do
		local sec_name = line:match("^%s*%[([^%]]+)%]%s*$")  -- should have a trimming effect as well (%s-)
		if sec_name then
			sec = sec_name
			t[sec] = t[sec] or {} --if section is nil, then it set to a new table
		end
		
		local key, val = line:match("^%s*(%w+)%s*=%s*(%S+)%s*$")  -- again, extra trimming and only one "word" with no whitespaces (%S+) inbetween as a value
		if key and val then
			if tonumber(val, 16) then  -- valid hex string? 
				if #val ~= 6 and #val ~= 8 then  -- we want only colors, so either 6 digit RRGGBB or 8 digit RRGGBBAA 
					log(string.format("Section [%s] property %s skipped because its value (%s) is not 6-digits or 8-digits long hex string", sec, key, val))
				else
					t[sec][key] = val
				end
			else
				log(string.format("Section [%s] property %s skipped because its value (%s) is not a valid hex string", sec, key, val))
			end
			--[[ for future reference and possible other 'native' data types ...
			if tonumber(val) then
				val = tonumber(val)
			end
			if val == "true" then 
				val = true 
			end
			if val == "false" then 
				val = false 
			end
			]]--
				
				
		
		end
	end
	--log(dump_table(t))
	return t
end


-- END UTILITIES


-- EXE
local function find_current_colors()
	-- AOB : 10 10 10 FF FF FF FF FF 00 44 93 FF
	return memory.search_process("\x10\x10\x10\xFF\xFF\xFF\xFF\xFF\x00\x44\x93\xFF")
end

local function invert_hex_color(color)
	local inv_color
	if #color == 8 then
		inv_color = tonumber(color:sub(7,8) .. color:sub(5,6) .. color:sub(3,4) .. color:sub(1,2), 16)
	elseif #color == 6 then
		inv_color = tonumber(color:sub(5,6) .. color:sub(3,4) .. color:sub(1,2), 16)
	end
	return inv_color
end


local function validate_memory(ctx)
	if not ctx.ui_colors_exe['addr'] then
		return true  -- first run, nothing to validate against 
	end	
	
	-- is the current content of the expected memory segment still consistent with color values?
	-- i.e. is the 'addr' still pointing at the correct region? (possibility of runtime relocation??)
	-- last known good dataset: in last_used_exe_colors_map table - compare it against content of memory region
	_log("Validation start ...")
	for col_ind, col_val in pairs(last_used_exe_colors_map) do
		local addr = ctx.ui_colors_exe['addr']
		local color_offset = addr + (col_ind - 1)*4
		local curr_color = string.lower(memory.hex(memory.unpack("b", memory.read(color_offset, 4))))

		-- log("color_index: " .. tostring(col_ind) .. ", value in map: " .. string.lower(col_val[1]) .. ", value in memory: " .. curr_color)
		if string.lower(col_val[1]) ~= curr_color then
			log(string.format("Validation failed at color_index %s - expected value %s is different from the current value %s in memory.\n\tNew colors won't be saved to memory, please restart the game to change color in safe way.", tostring(col_ind), string.lower(col_val[1]), curr_color))
			return false
		end
	end
	_log("Validation finished successfuly.")
	return true
end


function m.patch_memory(ctx, source)
	if source and source == "MenuServer" then
		log(string.format("'patch_memory' called from menu server (for tournamentID %s) ", tostring(ctx.tournament_id)))
	end
	
	local map
	if not source then
		map = m.ui_exe_colors_map
	else
		if source == "MenuServer" then
			map = load_map_txt(ctx, "map_exe.txt", "MenuServer")
		end
	end
	
	if not map then
		log("Data for patching memory not available, cannot change colors.")
		return false, "ERR_NO_MAP_DATA"
	end

    local addr = ctx.ui_colors_exe['addr'] or find_current_colors()
	if addr then
		if validate_memory(ctx) then
			if not ctx.ui_colors_exe['addr'] then
				ctx.ui_colors_exe = {['addr'] = addr} -- save offset for later reloads through overlay 
			end

			log(string.format("Patching colors in memory:: found entry point at: %s", memory.hex(addr)))
			--for col_ind, col_val in pairs(m.ui_exe_colors_map) do
			for col_ind, col_val in pairs(map) do
				local color_offset = addr + (col_ind - 1)*4
				local color_inv = invert_hex_color(col_val[1])
				_log(string.format("color_addr: %s (color_index: %s):: old color value: %s, new color value: %s", memory.hex(color_offset), col_ind, memory.hex(memory.unpack("b", memory.read(color_offset, 4))), string.lower(col_val[1])))
				memory.write(color_offset, memory.pack("u32", color_inv))	
			end
			log("Patching complete.")
			--last_used_exe_colors_map = table_copy(m.ui_exe_colors_map) -- save currently used colors for eventual memory validations
			last_used_exe_colors_map = table_copy(map) -- save currently used colors for eventual memory validations
		else
			log("Memory validation failed, cannot (re)apply color values.")
			return false, "ERR_VALIDATE"
		end
    else
		return false, "ERR_ENTRYPOINT"
    end
	
	return true
end
------------------------------------------


-- Bins

local function load_ui_bin_file(ctx, filename)
	local fullPath = ctx.sider_dir .. ui_bin_files_root .. filename
	local in1 = io.open(fullPath, "rb")
	if in1 then
		local bytes = in1:read("*all")
		in1:close()
		
		local unzlibbed_bytes, err = get_common_lib(ctx).try_unzlib(bytes) -- from commonlib.lua
		if unzlibbed_bytes and (not err or err == "ERR_NOT_ZLIBBED") then
			-- unzlibbed successfully ...
			_log(string.format("(load_ui_bin_file) Unzlibbed data retrieved for file %s:: len: %d", fullPath, #unzlibbed_bytes))
			return unzlibbed_bytes, err
		else
			log(string.format("(load_ui_bin_file) Error while unzlibbing %s: %s", fullPath, nil2str(err)))
			return nil, err
		end
	else
		log(string.format("(load_ui_bin_file) Cannot load file %s (not found).", fullPath))
		return nil, "ERR_BIN_NOT_FOUND"
	end
end

local function save_ui_bin_file(ctx, filename, bytes)
	local out1 = io.open(ctx.sider_dir .. ui_bin_files_root .. filename, "wb")
	if out1 then
		out1:write(bytes)
		out1:close()
	else
		log(string.format("(save_ui_bin_file) Cannot save file %s (not found).", filename))
	end
end


local function copy_bin_file(ctx, filename, source)
	local in1
	local fullPath = ""
	
	if source then
		--log("External ...")
		if source == "MenuServer" then
			--log("... menu server ...")
			if ctx.MenuServer['menu_path'] then  -- try using file from menu server (if it exists ...)
				_log("(copy_bin_file) Called externally (menuserver), 'menu_path': " .. ctx.MenuServer['menu_path'])
				_log(ctx.MenuServer['menu_path'] .. "\\" .. filename)
				fullPath = ctx.MenuServer['menu_path'] .. "\\" .. filename
				in1 = io.open(fullPath, "rb")
				if not in1 then  -- if menu server does not have that file, fall back to file from default DO_NOT_EDIT root
					_log("... but requested file cannot be found in menu server ... falling back to deafult file:")
					fullPath = ctx.sider_dir .. ui_bin_files_root .. "DO_NOT_EDIT\\" .. filename
					_log(fullPath)
					in1 = io.open(fullPath, "rb")
				end
			end
		end
	else
		fullPath = ctx.sider_dir .. ui_bin_files_root .. "DO_NOT_EDIT\\" .. filename
		in1 = io.open(fullPath, "rb")
	end
	
	
	if in1 then
		local bytes = in1:read("*all")
		in1:close()
		
		local out1 = io.open(ctx.sider_dir .. ui_bin_files_root .. filename, "wb")
		if out1 then
			out1:write(bytes)
			out1:close()
		else
			log(string.format("(copy_ui_bin_file - write) Cannot write over file %s (not found).", ctx.sider_dir .. ui_bin_files_root .. filename))
		end
	else
		log(string.format("(copy_ui_bin_file - read) Cannot copy file %s (not found).", fullPath))
	end
end

local function restore_default_bin_files(ctx, map, source)
	for filename, _ in pairs(map) do
		copy_bin_file(ctx, filename, source)
	end
end


function pack_bigendian_int_24_or_32(format, val)
	local n = format:find('I3') and 3 or format:find('I4') and 4
	if n then
		if n == 3 then
			return memory.pack("u8", val/0x10000) .. memory.pack("u8", val/0x100) .. memory.pack("u8", val%0x100)
		end
		if n == 4 then
			return memory.pack("u8", val/0x1000000) .. memory.pack("u8", val/0x10000) .. memory.pack("u8", val/0x100) .. memory.pack("u8", val%0x100)
		end
	end

end


local function encode_color_hexstr(color)
	if #color == 6 then
		return pack_bigendian_int_24_or_32("I3", tonumber(color, 16))
	elseif #color == 8 then
		return pack_bigendian_int_24_or_32("I4", tonumber(color, 16))
	end
end

function m.change_ui_bin_colors(ctx, source)
	if source and source == "MenuServer" then
		log(string.format("'change_ui_bin_colors' called from menu server (for tournamentID %s): ", tostring(ctx.tournament_id)))
	end
	
	local map
	if not source then
		map = m.ui_bin_colors_map
		restore_default_bin_files(ctx, map)
	else
		if source == "MenuServer" then
			map = load_ini_file(ctx, "ui_bin_colors.ini", "MenuServer")
			restore_default_bin_files(ctx, map, "MenuServer")
		end
	end
	
	if not map then
		log("Data for changing colors in bin files is not available, cannot change colors.")
		return
	end
	
	m.bins_processed = false
	for filename, properties in pairs(map) do
		if properties then
			local bytes, err = load_ui_bin_file(ctx, filename)
			if bytes then
				_log(string.format("Changing colors in bin file %s ...", filename))
				for offset, color in pairs(properties) do
					offset = tonumber(offset, 16)
					_log(string.format("\t\tcolor found at offset %s - replacing it with color %s", memory.hex(offset), color))
					bytes = bytes:sub(1, offset) .. encode_color_hexstr(color) .. bytes:sub(offset+#color/2+1, -1)	
				end
				save_ui_bin_file(ctx, filename, bytes)
			end
		end
	end
	m.bins_processed = true
	
end


local function read_bin_file_contents(ctx, filename, buff_addr, size, total_size, offset, cpk_name)
	-- -- but do be aware that sider returns 'filename' paths with single \ characters!!
	-- -- ... filepaths in UIColor maps use \\ ... so a little gsubbing is required to match filenames 
	-- if m.ui_bin_colors_map[filename:gsub([[\]], [[\\]])] then
		-- _log("UI file " .. filename .. " (re)loaded by the game")
	-- end
end



----------------------------------------


local function overlay_on(ctx)
    local text = string.format("version %s\n\nUI Colors commands:\nPress [0] to reload and reapply config files (map_exe.txt and ui_bin_colors.ini)\nPress [DEL] to clear info messages\n\n\n%s", m.version, info_text)
    return text
end


local function key_down(ctx, vkey)
	if vkey == RELOAD_MAPS_KEY then
        log("Starting manual reload of map files ... ")
		clear_table(m.ui_exe_colors_map)
        m.ui_exe_colors_map = load_map_txt(ctx, "map_exe.txt")
		
		clear_table(m.ui_bin_colors_map)
		m.ui_bin_colors_map = load_ini_file(ctx, "ui_bin_colors.ini")
		m.change_ui_bin_colors(ctx)

		info_text = info_text .. "map_exe.txt and ui_bin_colors.ini reloaded.\n\n"
        log("Manual reload of map files finished.")
		local result, err = m.patch_memory(ctx)
		if result == false then
			if err then
				if err == "ERR_VALIDATE" then
					info_text = info_text .. "Memory validation failed, changes from map_exe.txt are not applied! Restart the game to apply new colors.\n"
					log("Memory validation failed, changes from map.txt are not applied! Restart the game to apply new colors.")
				end
			end
		else
			info_text = info_text .. "New values from map files are reapplied.\nEffect of these changes may not be immediately visible on your current screen - if so, navigate away at least one step and then return.\n"
			log("New values from map_exe.txt re-applied in memory.")
		end
    elseif vkey == DEL_TEXT_KEY then
        info_text = ""
	end
end

 
function m.init(ctx)
	if ui_colors_root:sub(1,1)=='.' then
        ui_colors_root = ctx.sider_dir .. ui_colors_root
    end
	
	ctx.register("overlay_on", overlay_on)
    ctx.register("key_down", key_down)
	ctx.register("livecpk_read", read_bin_file_contents)
	
	ctx.ui_colors_exe = {['addr'] = nil, }
	ctx.ui_colors = m  -- to access module-level functions from this module (functions with "m." prefix) from other modules
	
	clear_table(m.ui_exe_colors_map)
	m.ui_exe_colors_map = load_map_txt(ctx, "map_exe.txt")
	local result, err = m.patch_memory(ctx) 
	if err and err == "ERR_ENTRYPOINT" then
		error("Cannot find memory entry point for UI colors, aborting.")
	end
	
	clear_table(m.ui_bin_colors_map)
	m.ui_bin_colors_map = load_ini_file(ctx, "ui_bin_colors.ini")
	
	m.change_ui_bin_colors(ctx)
	
end

return m