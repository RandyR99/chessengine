interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.color = "B"
interface.level = "10"
interface.cur_level = nil
interface.levelnum = 1
local lastx = 0
local lasty = 0
interface.score = "0.00"
interface.pv = ""
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

-- read len bytes of main RAM (0x0000-0x3fff) as a string
local function ram_block(addr, len)
	local space = machine.devices[":maincpu"].spaces["program"]
	local s = ""
	for i = 0, len - 1 do
		s = s .. string.char(space:read_u8(addr + i))
	end
	return s
end

function interface.get_module()
	return "SciSys Chess Champion Mark V"
end

function interface.get_author()
	return "David Broughton & Mark Taylor"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level or interface.levelnum == 0) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if interface.levelnum > 1 then
		level = level:sub(level:find("%s") + 1)
	end
	send_input(":IN.4", 0x08, 0.25) -- CE
	local mode = 1
	for i = 2, 4 do
		if (output_value("0.7." .. tostring(12 - i)) ~= 0x00) then
			mode = i
			break
		end
	end
	mode = (interface.levelnum - mode + 4) % 4
	for i = 0, mode do
		send_input(":IN.4", 0x10, 0.25) -- Mode
	end
	local k = 0
	for i = 1, level:len() do
		local d = level:sub(i,i)
		if d == " " or d == "/" then
			if k == 15 then
				break
			end
			send_input(":IN.4", 0x04, 0.25) -- Enter
			k = k + 1
		elseif string.match(d, "%d") then
			local v = tonumber(d)
			if v <= 5 then
				send_input(":IN.2", 1 << v, 0.25)
			else
				send_input(":IN.3", 1 << (v - 6), 0.25)
			end
		end
	end
	send_input(":IN.4", 0x04, 0.25) -- Enter
	if interface.levelnum == 4 then
		send_input(":IN.4", 0x08, 0.25) -- CE
	end
	send_input(":IN.4", 0x20, 0.25) -- Start Clock
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.color = "B"
	emu.wait(5.0)
	send_input(":IN.0", 0x02, 0.5) -- New Game
	emu.wait(0.5)
	send_input(":IN.3", 0x08, 0.5) -- Yes
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = "" -- not nil: setlevel() does nothing while cur_level is nil
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x01, 0.5) -- ENTER POSITION
		send_input(":IN.7", 0x01, 0.5) -- SOUND
		send_input(":IN.3", 0x08, 0.5) -- YES
		send_input(":IN.3", 0x08, 0.5) -- CB/YES
		send_input(":IN.3", 0x08, 0.5) -- YES
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == 0 then
					send_input(":IN.2", 0x01, 0.5) -- CS/NO
				else
					if p * piece < 0 then
						if p > 0 then
							send_input(":IN.3", 0x02, 0.5) -- White
						else
							send_input(":IN.3", 0x04, 0.5) -- Black
						end
					end
					interface.send_pos(7 - math.abs(p))
					piece = p
				end
			end
		end
		send_input(":IN.4", 0x04, 0.5) -- ENTER
		if mode * piece < 0 then
			send_input(":IN.2", 0x01, 0.5) -- NO
		else
			send_input(":IN.3", 0x08, 0.5) -- YES
		end
		send_input(":IN.4", 0x04, 0.5) -- ENTER
		send_input(":IN.7", 0x01, 0.5) -- SOUND
		send_input(":IN.4", 0x04, 0.5) -- ENTER
		if mode == 1 then
			interface.color = "B"
		else
			interface.color = "W"
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on == true then
		send_input(":IN.1", 0x20, 0.5) -- stop clock
	else
		send_input(":IN.4", 0x20, 0.5) -- start clock
	end
	interface.edit = on
end

function interface.start_play(init)
	if (interface.color == "W") then
		interface.color = "B"
	else
		interface.color = "W"
	end
	interface.turn = false
	send_input(":IN.4", 0x02, 0.25) -- Go
end

function interface.stop_play()
	if (not interface.turn) then send_input(":IN.4", 0x02, 0.25) -- Go
		emu.wait(0.5)
		send_input(":IN.3", 0x08, 0.25) -- Yes
	end
end

function interface.is_selected(x, y)
	if (output_value("0.7.11") ~= 0x00) then
		return false
	end -- COMPUTING?
	local ply = 1
	interface.color = "W"
	local ddram = ram_block(0x3e6f, 0x11)
	if ddram:sub(5, 5) == "@" then -- what is my color?
		ply = 8
		interface.color = "B"
		ddram = ddram:sub(8, 12)
	else
		ply = 1
		ddram = ddram:sub(5, 9)
		interface.color = "W"
	end
	ddram = (ddram:gsub("@", ""):gsub(":", ""))
	if ddram:sub(1, 4) == "O-O-" then -- "0-0-", computer castles queenside
		if (x == 5 or x == 3) and (y == ply) then
			return true
		else
			return false
		end
	end
	if ddram:sub(1, 3) == "O-O" then -- "0-0:", computer castles kingside
		if (x == 5 or x == 7) and (y == ply) then
			return true
		else
			return false
		end
	end
	local d0, d1, d2, d3, d4
	d0 = ddram:byte(1)
	d1 = ddram:byte(2)
	d2 = ddram:byte(3)
	d3 = ddram:byte(4)
	d4 = ddram:byte(5)
	local xval = {0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48}
	local yval = {0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38}
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d3 and yval[y] == d4)
end

function interface.send_pos(p)
	if (p == 1) then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 2) then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 3) then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 4) then send_input(":IN.2", 0x10, 0.5)
	elseif (p == 5) then send_input(":IN.2", 0x20, 0.5)
	elseif (p == 6) then send_input(":IN.3", 0x01, 0.5)
	elseif (p == 7) then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 8) then send_input(":IN.3", 0x04, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn or interface.edit) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "get" or event == "get_castling") then
			lastx = x
			lasty = y
		elseif (event == "put") then
			local move_type = get_move_type(lastx, lasty, x, y)
			if (interface.turn or interface.edit) then
				if move_type ~= "promotion" and move_type ~= "capture_promotion" then
					send_input(":IN.4", 0x04, 1) -- Enter
				end
			end
			if (interface.edit) then
				if (interface.color == "W") then
					interface.color = "B"
				else
					interface.color = "W"
				end
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "10" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		interface.levelnum = 0
		value = value:gsub("_", " ")
		local level = string.upper(value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ")) -- trim
		local n = tonumber(level)
		if (n ~= nil and n >= 0 and n <= 999) then
			interface.levelnum = 1
		elseif (level:sub(1, 8) == "PROBLEM " or level:sub(1, 5) == "MATE " or level:sub(1, 5) == "MATT ") then
			n = tonumber(level:sub(level:find("%s") + 1))
			if (n ~= nil and n >= 1 and n <= 7) then
				interface.levelnum = 2
			end
		elseif (level:sub(1, 6) == "SPEED " or level:sub(1, 6) == "BLITZ ") then
			n = tonumber(level:sub(7))
			if (n ~= nil and n >= 0 and n <= 999) then
				interface.levelnum = 3
			end
		elseif (level:sub(1, 6) == "TOURN " or level:sub(1, 5) == "TURN ") then
			interface.levelnum = 4
		end
		if (interface.levelnum ~= 0) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local ddram = ram_block(0x3e70, 0x10)
	local p
	if (interface.color == "B") then
		p = ddram:byte(12) -- piece for black promotion
	else
		p = ddram:byte(9) -- piece for white promotion
	end
	if     (p == 0x51) then return 'q'
	elseif (p == 0x52) then return 'r'
	elseif (p == 0x42) then return 'b'
	elseif (p == 0x4e) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if     (piece == "q") then send_input(":IN.2", 0x20, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x10, 0.5)
	elseif (piece == "b") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "n") then send_input(":IN.2", 0x04, 0.5)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.4", 0x04, 1) -- Enter
	end
end

function interface.show_pv_after_move_player()
	if output_value("0.7.11") == 1 then
		send_input(":IN.1", 0x08, 0.2) -- Analysis
	end
end

function interface.show_info(on)
   if on then
		local ddram = ram_block(0x3e6F, 0x10)
		if (ddram:sub(2,3)) ~= "NO" and (ddram:sub(2,3)) ~= "EI" and (ddram:sub(2,3)) ~= "AS" then
			if (output_value("0.7.11") ~= 0x00) then
				interface.score = ddram:sub(10,14):gsub(":", " ") .. "0"
				interface.pv = ddram:sub(1,10):gsub(":", " ")
				emu.wait(0.2)
				if output_value("0.7.11") ~= 0x00 then
					return "info score cp " .. interface.score .. " depth 1" .. " pv " .. string.lower(interface.pv)
				end
			else
				return
			end
		end
	end
end

return interface
