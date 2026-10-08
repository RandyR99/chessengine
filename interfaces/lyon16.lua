interface = load_interface("alm16")

interface.level = "NORML 01"

function interface.get_module()
	return "Mephisto Lyon (16 Bit)"
end

function interface.get_author()
	return "Richard Lang"
end

-- Helper function to read a specific range of characters from DDRAM
function read_lcd_range(start_idx, end_idx)
    local dev = machine.devices[':display:hd44780']
    if not dev then return "" end
    
    local state_item = dev.items["0/m_ddram"]
    if not state_item then return "" end
    
    local wrapped_mem = emu.item(state_item)
    local str = ""
    for i = start_idx, end_idx do
        str = str .. string.char(wrapped_mem:read(i))
    end
    return str
end

function interface.set_pos(mode)
	if mode == 0 then
		if (machine.ioport.ports[":FAKE"]:read() ~= 0x01) then
			machine.ioport.ports[":FAKE"]:field(0x01):set_value(1)
			machine:soft_reset()
			emu.wait(1)
		end
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY2", 0x0100, 0.5)	-- RIGHT
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY1", 0x0100, 0.5)	-- LEFT
		return (":board:board")
	else
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		if mode == -1 then
			send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		end
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
	end
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY1", 0x0200, 0.5)	-- ENT
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "NORML 01" },
	}
end

function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		-- 1. Reset any latent input states with an initial CL
		send_input(":KEY3", 0x0200, 0.6) -- CL
		emu.wait(0.2)
		
		-- 2. Execute your verified macro sequence to surface evaluation stats
		send_input(":KEY2", 0x0100, 0.5) -- RIGHT
		send_input(":KEY1", 0x0200, 0.6) -- ENT
		send_input(":KEY3", 0x0100, 0.6) -- DOWN
		send_input(":KEY3", 0x0100, 0.6) -- DOWN
		
		-- Pacing pause to let the emulated LCD redraw character registers completely
		emu.wait(0.4)
		
		local ddram = read_lcd_range(0x00, 0x7F)
		local info = nil
		local score_field = ""

		-- Explicitly check for opening book markers on the display
		if ddram:sub(66, 69) == "THEO" or ddram:sub(2, 5) == "BOOK" then
			info = "info score cp book"
		else
			-- Clean up numeric decimal formats (e.g. "+0.25") into clean centipawns
			score_field = ddram:sub(65, 69):gsub("%.", "")
			score_field = score_field:match("^([^/]+)") or score_field
			score_field = score_field:gsub(" ", "")
		end

		local depth_field = ddram:sub(1, 2):gsub(" ", "")
		local pv_field = string.lower(ddram:sub(70, 112))
		
		-- Clean up trailing branch ply markers or layout notations
		pv_field = pv_field:gsub("=%d+/%d+", "")
		
		-- TRUNCATION FIX: Isolate strictly the first machine move from the PV layout data block
		pv_field = pv_field:match("%s*(%S+)") or ""

		-- Safety Filter: If menu letters like "CO" are caught mid-refresh, escape cleanly
		if score_field:match("[A-Za-z]") or score_field:match("^%s*$") then
			send_input(":KEY3", 0x0200, 0.6) -- CL
			send_input(":KEY3", 0x0200, 0.6) -- CL
			machine.video.throttled = throttled_state
			return nil
		end

		-- Assemble standard UCI communication string if data layout is clean
		if info == nil then
			info = "info score cp " .. score_field .. " depth " .. depth_field .. " pv " .. pv_field
		end
		
		-- 3. Symmetric Menu Unwinding: Clear twice to close info mode and restore the default view
		emu.wait(0.2)
		send_input(":KEY3", 0x0200, 0.6) -- CL
		send_input(":KEY3", 0x0200, 0.6) -- CL
		
		machine.video.throttled = throttled_state
		return info
	end
end

return interface
