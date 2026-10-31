interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 0
interface.cur_level = nil

function interface.get_module()
	return "VEB Chess-Master Diamond"
end

function interface.get_author()
	return "Dieter Schultze & Rüdiger Worbs"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(1)
	send_input(":IN.1", 0x01, 1) -- Monitor
	emu.wait(1)
	local lcd_num = { 0x00ff, 0x400c, 0x377, 0x023f, 0x38c, 0x03bb, 0x03fb, 0x020f, 0x3ff, 0x03bf }
	if interface.cur_level >= 10 then
		send_input(":IN.1", 0x02, 0.5) -- Vieww
		emu.wait(1)
		send_input(":IN.0", 0x20, 0.5) -- Selection/Dialogue
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
		send_input(":IN.1", 0x01, 0.5) -- Monitor
		emu.wait(1)
	end
	if interface.level >= 10 then
		send_input(":IN.0", 0x08, 0.5) -- Match/Time
		emu.wait(1)
		local level = interface.level - 10
		if level >= 1 then
			repeat
				send_input(":IN.0", 0x01, 1) -- Move Fore
				emu.wait(1)
				level = level - 1
			until level == 0
		end
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
	else
		send_input(":IN.0", 0x10, 0.5) -- Parameter / Information
		emu.wait(1)
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
		while output_value("digit0") ~= lcd_num[interface.level + 1] do
			send_input(":IN.0", 0x01, 0.5) -- Move Fore
			emu.wait(1)
		end
		send_input(":IN.1", 0x01, 0.5) -- Monitor
		emu.wait(1)
	end
	interface.cur_level = interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 0
	interface.setlevel()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	-- Score einschalten
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(0.5)
	send_input(":IN.1", 0x01, 1) -- Monitor
	emu.wait(0.5)
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(0.5)
	send_input(":IN.0", 0x20, 1) -- Selection/Dialogue
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x01, 1) -- Monitor (leave the score display)
		send_input(":IN.0", 0x04, 1) -- Board
		sb_clear_board(":board")
		send_input(":IN.0", 0x80, 1) -- Enter
		machine.video.throttled = throttled_state
		return (":board")
	else
		local ram = machine.devices[":maincpu"].spaces["program"]
		local fig = {0x81,0x82,0x83,0x84,0x85,0x86,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local adr = 0x8315
		local brd = {{  3, 5, 4, 2, 1, 4, 5, 3 },
			         {  6, 6, 6, 6, 6, 6, 6, 6 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         { -6,-6,-6,-6,-6,-6,-6,-6 },
			         { -3,-5,-4,-2,-1,-4,-5,-3 }}
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				if p ~= 0 and p ~= brd[y][x] then
					z = z | 0x40
				end
				ram:write_u8(adr + 10 * (y - 1) + x - 1, z)
			end
		end
		if mode == 1 then
			ram:write_u8(0x83a1,0x00)
			ram:write_u8(0x83a2,0x80)
		else
			ram:write_u8(0x83a1,0x80)
			ram:write_u8(0x83a2,0x00)
		end
		send_input(":IN.1", 0x01, 0.5) -- Monitor
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5) -- Monitor (leave the score display, the manual starts from "Y")
	send_input(":IN.0", 0x20, 0.5) -- Selection
	send_input(":IN.0", 0x80, 0.5) -- Enter: referee mode on/off
	send_input(":IN.1", 0x01, 0.5) -- Monitor
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x80, 1) -- Enter
end

function interface.stop_play()
	send_input(":IN.0", 0x80, 1) -- Enter
end

function interface.is_selected(x, y)
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "0", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
	-- Score einschalten
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x02, 0.5) -- View
	emu.wait(1)
	send_input(":IN.0", 0x20, 0.5) -- Selection/Dialogue
	emu.wait(1)
	machine.video.throttled = throttled_state
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit0") & 0xffff
	if     (d0 == 0xf730) then return "q"
	elseif (d0 == 0x93b4) then return "r"
	elseif (d0 == 0xd432) then return "b"
	elseif (d0 == 0x91bf) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board", x, y, piece)
	local right = -1
	if     (piece == "q") then right = 0
	elseif (piece == "r") then right = 1
	elseif (piece == "b") then right = 2
	elseif (piece == "n") then right = 3
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		interface.select_piece(x, y, "")
		send_input(":IN.0", 0x80, 1)
		interface.select_piece(x, y, "")
	end
	if (right ~= -1) then
		for i = 1, right do
			send_input(":IN.0", 0x01, 1)
		end
		send_input(":IN.0", 0x80, 1)
	end
	machine.video.throttled = throttled_state
end

-- show_info without key presses (the old reader stepped through the main line with Move Fore while the machine
-- thought; a press could land just as the move appears and hide it). setlevel/set_option leave the display on the
-- evaluation (View + Selection), which it shows in tenths of a pawn for the machine while it searches ('- 9.0',
-- '+ 0.3'); the
-- best move so far is in RAM at 0x8074/0x8075 (10x12 board, a1 = 21; found by RAM dumps during the search). No depth
-- or longer main line is kept.
local seg = { [0x00ff] = 0, [0x400c] = 1, [0x0377] = 2, [0x023f] = 3, [0x038c] = 4, [0x03bb] = 5, [0x03fb] = 6,
	[0x020f] = 7, [0x03ff] = 8, [0x03bf] = 9 }
local stale = nil
local first = true
local valued = false -- each search starts with ' 0.0' until it has an evaluation

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local from, to = sp:read_u8(0x8074), sp:read_u8(0x8075)
	local text = ""
	for i = 3, 0, -1 do
		local v = output_value("digit" .. i)
		local d = seg[v & 0xffff]
		if v & 0xffff == 0 then
			text = text .. " "
		elseif v & 0xffff == 0x0300 then
			text = text .. "-"
		elseif v & 0xffff == 0x0f00 then
			text = text .. "+"
		elseif d then
			text = text .. d .. ((v & 0x10000 ~= 0) and "." or "")
		else
			text = text .. "?"
		end
	end
	local raw = from .. " " .. to .. " " .. text
	if not on or first then
		first = false -- RAM still holds the last search before this session's first player turn
		stale = raw
		valued = false
		return nil
	end
	if raw == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local info = {}
	local function square(v)
		v = v - 21
		if v >= 0 and v < 80 and v % 10 < 8 then
			return string.char(0x61 + v % 10) .. (v // 10 + 1)
		end
	end
	if square(from) and square(to) then
		info.pv = { square(from) .. square(to) }
	end
	local sign, pawns, tenths = text:match("^([%-+]?) *(%d+)%.(%d)$")
	if pawns then
		local cp = tonumber(pawns) * 100 + tonumber(tenths) * 10
		valued = valued or cp ~= 0
		if valued then
			info.score = sign == "-" and -cp or cp
		end
	end
	if not info.pv and not info.score then
		return nil
	end
	return info
end

interface.info_every = 1 -- show_info only reads RAM and the display

return interface
