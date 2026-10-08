interface = {}

interface.level = "NORML 01"
interface.cur_level = nil

-- Helper function to read a specific range of characters from DDRAM
local function read_lcd_range(start_idx, end_idx)
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

function interface.get_module()
	if machine.system.name == "berlinp" then
		return "Mephisto Berlin Pro"
	elseif machine.system.name == "berlinpl" then
		return "Mephisto Berlin Pro (London)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Richard Lang"
end

function proglevel(level)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local n,z1,z2,h1,h2,dir,dif,mod,int = 0
	
	while (n < 4 and level:match("%s%d%d/%d%d:%d%d") ~= nil) do
		local temp = level:sub(2,9)
		level = level:sub(10)
		send_input(":KEY", 0x01, 0.6) -- ENT
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		send_input(":KEY", 0x01, 0.6) -- ENT
		
		z1 = read_lcd_range(0x43, 0x44)
		if (z1 == "AL") then
			z1 = 0
			h1 = 60 * (tonumber(read_lcd_range(0x4b, 0x4c))) + tonumber(read_lcd_range(0x4e, 0x4f))
		else
			z1 = tonumber(z1)
			h1 = 60 * (tonumber(read_lcd_range(0x49, 0x4a))) + tonumber(read_lcd_range(0x4c, 0x4d))
		end
		z2 = tonumber(temp:sub(1,2))
		h2 = 60 * tonumber(temp:sub(4,5)) + tonumber(temp:sub(7,8))
		if (z2 > 90 or h2 == 0 or h2 > 5400 or tonumber(temp:sub(7,8)) > 59) then
			machine.video.throttled = throttled_state
			return
		end
		if (z2 < z1) then
			dir = -1
		else
			dir = 1
		end
		dif = math.abs(z2 - z1)
		mod = dif % 10
		int = (dif - mod) / 10
		if (mod > 5) then
			mod = mod - 10
			int = int + 1
		end
		for i = 1, int do
			if (dir > 0) then
				send_input(":KEY", 0x04, 0.6) -- UP
				z1 = z1 + 10
			else
				send_input(":KEY", 0x08, 0.6) -- DOWN
				z1 = z1 - 10
			end
		end
		if (z1 > 90) then
			mod = z2 - 91
		elseif (z1 < 0) then
			mod = z2 + 1
		else
			mod = dir * mod
		end
		for i = 1, math.abs(mod) do
			if (mod > 0) then
				send_input(":KEY", 0x20, 0.6) -- RIGHT
			else
				send_input(":KEY", 0x10, 0.6) -- LEFT
			end
		end
		send_input(":KEY", 0x01, 0.6) -- ENT
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		send_input(":KEY", 0x01, 0.6) -- ENT
		if (h2 > h1) then
			dir = 1
		else
			dir = -1
		end
		dif = math.abs(h2 - h1)
		mod = dif % 30
		int = (dif - mod) / 30
		if (mod > 15) then
			mod = mod - 30
			int = int + 1
		end
		for i = 1, int do
			if (dir > 0) then
				send_input(":KEY", 0x04, 0.6) -- UP
				h1 = h1 + 30
			else
				send_input(":KEY", 0x08, 0.6) -- DOWN
				h1 = h1 - 30
			end
		end
		if (h1 >= 5400) then
			mod = h2 - 5400
		elseif (h1 <= 1) then
			mod = h2 - 1
		else
			mod = dir * mod
		end
		for i = 1, math.abs(mod) do
			if (mod > 0) then
				send_input(":KEY", 0x20, 0.6) -- RIGHT
			else
				send_input(":KEY", 0x10, 0.6) -- LEFT
			end
		end
		n = n + 1
	end
	machine.video.throttled = throttled_state
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x08, 0.6) -- DOWN
	send_input(":KEY", 0x20, 0.6) -- RIGHT
	send_input(":KEY", 0x20, 0.6) -- RIGHT
	send_input(":KEY", 0x01, 0.6) -- ENT
	send_input(":KEY", 0x01, 0.6) -- ENT
	
	local ddram = read_lcd_range(0x07, 0x09)
	while (ddram:match(interface.level:sub(1, 3)) == nil) do
		send_input(":KEY", 0x08, 0.6) -- DOWN
		ddram = read_lcd_range(0x07, 0x09)
	end
	if (interface.level:sub(1, 5) == "PROGR") then
		proglevel(interface.level:sub(6))
	else
		ddram = read_lcd_range(0x0c, 0x0e)
		while (tonumber(ddram) ~= tonumber(interface.level:sub(6, 8))) do
			send_input(":KEY", 0x20, 0.6) -- RIGHT
			ddram = read_lcd_range(0x0c, 0x0e)
		end
	end
	send_input(":KEY", 0x01, 0.6) -- ENT
	send_input(":KEY", 0x02, 0.6) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board:board")
	emu.wait(1)
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x08, 0.6) -- DOWN
	send_input(":KEY", 0x20, 0.6) -- RIGHT
	send_input(":KEY", 0x01, 0.6) -- ENT
	machine.video.throttled = throttled_state
	interface.cur_level = ""
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY", 0x02, 0.6)	-- CL
		send_input(":KEY", 0x02, 0.6)	-- CL
		send_input(":KEY", 0x08, 0.6)	-- DOWN
		send_input(":KEY", 0x08, 0.6)	-- DOWN
		send_input(":KEY", 0x01, 0.6)	-- ENT
		send_input(":KEY", 0x20, 0.6)	-- RIGHT
		send_input(":KEY", 0x01, 0.6)	-- ENT
		send_input(":KEY", 0x10, 0.6)	-- LEFT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY", 0x01, 0.6)	-- ENT
		local piece=1
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":KEY", 0x08, 0.6)	-- DOWN
					end
					local n = math.abs(p) - math.abs(piece)
					for i = 1, math.abs(n) do
						if n > 0 then
							send_input(":KEY", 0x20, 0.6)	-- RIGHT
						else
							send_input(":KEY", 0x10, 0.6)	-- LEFT
						end
					end
					sb_press_square(":board:board", 0.6, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":KEY", 0x08, 0.6)	-- DOWN
		end
		send_input(":KEY", 0x02, 0.6)	-- CL
		send_input(":KEY", 0x02, 0.6)	-- CL
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x02, 0.6)	-- CL
	send_input(":KEY", 0x02, 0.6)	-- CL
	send_input(":KEY", 0x08, 0.6)	-- DOWN
	send_input(":KEY", 0x08, 0.6)	-- DOWN
	send_input(":KEY", 0x08, 0.6)	-- DOWN
	send_input(":KEY", 0x20, 0.6)	-- RIGHT
	send_input(":KEY", 0x01, 0.6)	-- ENT
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x20, 0.6) -- RIGHT
	send_input(":KEY", 0x01, 0.6) -- ENT
	machine.video.throttled = throttled_state
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x02, 0.6) -- CL
	send_input(":KEY", 0x01, 0.6) -- ENT
	machine.video.throttled = throttled_state
end

function interface.is_selected(x, y)
	local led_idx = (y - 1) * 8 + (x - 1)
	local led_name = "led" .. tostring(led_idx)
	local led_state = machine.devices[":"]:output(led_name)
	return led_state and led_state:get() ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "NORML 01" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		value = value:gsub("_", " ")
		local levstr = value:sub(1, 5)
		levstr = levstr:upper()
		levstr = levstr:gsub("\xc4", "A"):gsub("\xe4", "A"):gsub("ä", "A"):gsub("Ä", "A")
		local levnum = tonumber(value:sub(6, 8))
		if (levstr == "DAUER") then
			levnum = -1
		elseif (levstr == "NORML" or levstr == "TURN " or levstr == "ANFAN" or levstr == "HANDC" or levstr == "BLITZ") then
			if (levnum < 0 or levnum > 9) then
				return
			end
		elseif (levstr == "MATT ") then
			if (levnum < 1 or levnum > 16) then
				return
			end
		elseif (levstr == "TIEFE") then
			if (levnum < 0 or levnum > 30) then
				return
			end
		elseif (levstr == "PROGR") then
			levnum = value:sub(6):match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
			levnum = levnum:upper():gsub("ALLE", "00"):gsub(" IN ", "/")
		else
			return
		end
		if (levnum == -1) then
			interface.level = levstr
		else
			interface.level = levstr .. " " .. tostring(levnum)
		end
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local ddram = read_lcd_range(0x00, 0x7F)
	local line0 = ddram:sub(0x01, 0x10)
	local line1 = ddram:sub(0x41, 0x50)
	if     (line1:find('\x01') or line1:find('\x09')) then return 'q'
	elseif (line1:find('\x02') or line1:find('\x0a')) then return 'r'
	elseif (line1:find('\x03') or line1:find('\x0b')) then return 'b'
	elseif (line1:find('\x04') or line1:find('\x0c')) then return 'n'
	elseif (line0:find('\x01') or line0:find('\x09')) then return 'q'
	elseif (line0:find('\x02') or line0:find('\x0a')) then return 'r'
	elseif (line0:find('\x03') or line0:find('\x0b')) then return 'b'
	elseif (line0:find('\x04') or line0:find('\x0c')) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board:board", x, y, piece)
	local right = -1
	if	   (piece == "q") then right = 0
	elseif (piece == "r") then right = 1
	elseif (piece == "b") then right = 2
	elseif (piece == "n") then right = 3
	end
	if (right ~= -1) then
		for i = 1, right do
			send_input(":KEY", 0x20, 1) -- RIGHT
		end
		send_input(":KEY", 0x01, 1) -- ENT
	end
	machine.video.throttled = throttled_state
end

function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		-- 1. Open active evaluation summary overlay
		send_input(":KEY", 0x02, 0.6) -- CL
		send_input(":KEY", 0x02, 0.6) -- CL
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		send_input(":KEY", 0x01, 1.0) -- ENT

		-- 2. Cycle right three times to surface the pure evaluation/pawn-units panel page
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		send_input(":KEY", 0x20, 0.6) -- RIGHT
		
		local ddram = read_lcd_range(0x00, 0x7F)
		local info = nil
		local score_field = ""

		-- Explicitly check for opening book markers
		if (ddram:sub(66, 69)) == "THEO" then
			info = "info score cp book"
		else
			score_field = ddram:sub(65, 69):gsub("%.", "")
			score_field = score_field:match("^([^/]+)") or score_field
			score_field = score_field:gsub(" ", "")
		end

		local depth_field = ddram:sub(1, 2):gsub(" ", "")
		local pv_field = string.lower(ddram:sub(70, 112))
		
		-- Clean up tracking markers and branch annotations
		pv_field = pv_field:gsub("=%d+/%d+", "")
		
		-- TRUNCATION FIX: Isolate strictly the first machine move from the PV array string block
		pv_field = pv_field:match("%s*(%S+)") or ""

		-- Safety Filter: If standard calc has alpha configurations, drop frame gracefully
		local lead_char = ddram:sub(65, 65)
		if info == nil and lead_char ~= " " and lead_char ~= "-" and not lead_char:match("%d") then
			send_input(":KEY", 0x02, 0.6) -- CL
			machine.video.throttled = throttled_state
			return nil
		end

		-- Build complete UCI telemetry line if standard calculation frame
		if info == nil then
			info = "info score cp " .. score_field .. " depth " .. depth_field .. " pv " .. pv_field
		end
		
		-- 3. Clear window overlay overlay completely back to background calculating view loop
		send_input(":KEY", 0x02, 0.6) -- CL
		
		machine.video.throttled = throttled_state
		return info
	end
end

return interface
