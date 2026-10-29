interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local ram = machine.devices[':maincpu'].spaces['data'] -- 8050 internal RAM, board at 0x80 + 16 * (x - 1) + y - 1

interface.turn = true
interface.selected = {}
interface.selected_cnt = 0
interface.level = 1
interface.cur_level = nil
interface.init = false
interface.edit = false
interface.underpromote = false

function interface.get_module()
	return "Mattel Computer Chess"
end

function interface.get_author()
	return "Julio Kaplan & Craig Barnes"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		local lev2 = output_value("1.2.20")
		local lev3 = output_value("1.3.20")
		local lev4 = output_value("1.7.20")
		if (1 + lev2 + lev3 + lev4 ~= interface.level) then
			send_input(":IN.0", 0x10, 0.2) -- LEVEL
		end
	until 1 + lev2 + lev3 + lev4 == interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.selected = {}
	interface.selected_cnt = 0
	if (interface.init) then
		machine:soft_reset() -- the driver clears the saved LCD board on reset
	end
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.init = true
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local fig = {0x18,0x0c,0x09,0x0a,0x0b,0x0d,0x00,0x05,0x03,0x02,0x01,0x04,0x10}
		local adr = 0x0080
		send_input(":IN.2", 0x08, 0.25) -- Clear
		send_input(":IN.2", 0x04, 0.25) -- Enter Pos.
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				ram:write_u8(adr + 16 * (x - 1) + y - 1, z)
			end
		end
		-- white to move; for black let COLOR switch the side (writing 0xed/0xee alone isn't enough for player moves)
		ram:write_u8(0x00ed, 0x01)
		ram:write_u8(0x00ee, 0x00)
		if mode ~= 1 then
			send_input(":IN.2", 0x10, 0.25) -- Color
		end
		send_input(":IN.0", 0x08, 0.25) -- P. vs. M.
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	if on == true then
		interface.edit = true
		send_input(":IN.0", 0x02, 0.25) -- P. vs. P.
	else
		interface.edit = false
		send_input(":IN.0", 0x08, 0.25) -- P. vs. M.
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.1", 0x02, 1) -- MOVE
end

function interface.stop_play()
end

function interface.is_pos_selected(x, y, piece)
	local piece_id = get_piece_id(x, y)
	local selected = (piece_id == 0 and piece ~= 0) or (piece_id > 0 and piece <= 0) or (piece_id < 0 and piece >= 0)
	if (selected) then
		interface.selected[y * 10 + x] = piece_id
	end

	-- ignore the rook in castling
	if     (y == 1 and (x == 8 or x == 6) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+7] == 0 and interface.selected[1*10+8] ==  3)) then	return false	-- white kingside castling
	elseif (y == 1 and (x == 1 or x == 4) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+3] == 0 and interface.selected[1*10+1] ==  3)) then	return false	-- white queenside castling
	elseif (y == 8 and (x == 8 or x == 6) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+7] == 0 and interface.selected[8*10+8] == -3)) then	return false	-- black kingside castling
	elseif (y == 8 and (x == 1 or x == 4) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+3] == 0 and interface.selected[8*10+1] == -3)) then	return false	-- black queenside castling

	-- ignore en-passant capture
	elseif (y == 5 and x < 8 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x+1)] ==  6) then	return false	-- white en passant
	elseif (y == 5 and x > 1 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x-1)] ==  6) then	return false	-- white en passant
	elseif (y == 4 and x < 8 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x+1)] == -6) then	return false	-- black en passant
	elseif (y == 4 and x > 1 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x-1)] == -6) then	return false	-- black en passant
	end

	if (x == 1 and y == 1) then
		interface.selected_cnt = interface.selected_cnt + 1
	end
	if (interface.selected_cnt >= 25) then
		interface.selected_cnt = 0
		interface.selected = {}
	end

	-- wait complete scan before report selections
	if (interface.selected_cnt <= 3) then
		return false
	end
	return selected
end

function interface.is_selected(x, y)
	local ytag = 1
	local xtag = { 0, 1, 2, 3, 7, 6, 5, 4 }
	if (y > 4) then
		ytag = 0
		xtag =  { 3, 2, 1, 0, 7, 6, 5, 4 }
	end
	local piece0 = output_value(ytag .. "." .. xtag[x] .. "." .. tostring(19 - ((y - 1) & 3) * 5))
	local piece1 = output_value(ytag .. "." .. xtag[x] .. "." .. tostring(16 - ((y - 1) & 3) * 5))
	local piece2 = output_value(ytag .. "." .. xtag[x] .. "." .. tostring(18 - ((y - 1) & 3) * 5))
	local piece3 = output_value(ytag .. "." .. xtag[x] .. "." .. tostring(15 - ((y - 1) & 3) * 5))
	local piece = 0
	if ((piece0 + piece1) ~= 0 and (piece2 + piece3) ~= 0) then	piece = -1
	elseif ((piece0 + piece1) ~= 0 and (piece2 + piece3) == 0) then	piece = 1
	end
	return interface.is_pos_selected(x, y, piece)
end

local function move_cursor(x, y)
	-- 0x41: cursor square, 0x80 + 16 * (x - 1) + y - 1
	for i = 1, 20 do
		local c = ram:read_u8(0x41) - 0x80
		local cx = (c >> 4) + 1
		local cy = (c & 0x0f) + 1
		if     x < cx then send_input(":IN.1", 0x08, 0.7) -- LEFT
		elseif x > cx then send_input(":IN.1", 0x04, 0.7) -- RIGHT
		elseif y < cy then send_input(":IN.1", 0x80, 0.7) -- DOWN
		elseif y > cy then send_input(":IN.1", 0x10, 0.7) -- UP
		else break
		end
	end
end

function interface.select_piece(x, y, event)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (interface.turn) then
		if (event == "get" or event == "put") then
			if (event == "get") then
				send_input(":IN.1", 0x08, 0.7) -- LEFT: activates the cursor without moving it
			end
			move_cursor(x, y)
			if (event == "get") then
				send_input(":IN.1", 0x02, 0.7) -- MOVE
			else
				send_input(":IN.2", 0x02, 0.7) -- ENTER
				emu.wait(1)
			end
		end
	end
	if (event == "put") then
		if (not interface.edit) then
			interface.turn = not interface.turn
		end
		interface.selected = {}
		interface.selected_cnt = 0
		emu.wait(2)
	end
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "4" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 4) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local adr = 0x0080
	local piece = (ram:read_u8(adr + 16 * (x - 1) + y - 1)) & 0x07
	if     piece == 0x03 then return 'q'
	elseif piece == 0x02 then return 'r'
	elseif piece == 0x01 then return 'b'
	elseif piece == 0x04 then return 'n'
	end
	return nil
end

-- the machine always promotes to a queen; another piece is set with ENTER POSITION afterwards.
-- In Player vs Machine the machine would start thinking at once, so switch to Player vs Player first.
function interface.promote_special(piece)
	if interface.turn and not interface.edit and piece ~= "q" then
		interface.underpromote = true
		send_input(":IN.0", 0x02, 0.25) -- P. vs. P.
		emu.wait(0.5)
	end
end

function interface.promote(x, y, piece)
	local code = ({ q = 0x03, r = 0x02, b = 0x01, n = 0x04 })[piece:lower()]
	if piece == piece:upper() or code == nil or code == 0x03 then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if y == 1 then
		code = code + 0x08 -- black
	end
	local adr = 0x0080 + 16 * (x - 1) + y - 1
	send_input(":IN.1", 0x08, 0.7) -- LEFT: activate the cursor
	move_cursor(x, y)
	-- holding ENTER POSITION cycles through the chessmen
	local field = ioport.ports[":IN.2"]:field(0x04)
	field:set_value(1)
	for i = 1, 400 do
		if ram:read_u8(adr) == code then
			break
		end
		emu.wait(0.02)
	end
	field:set_value(0)
	emu.wait(0.5)
	send_input(":IN.2", 0x08, 0.25) -- Clear: remove the cursor
	if interface.underpromote then
		interface.underpromote = false
		send_input(":IN.0", 0x08, 0.25) -- P. vs. M.
		send_input(":IN.1", 0x02, 1) -- MOVE: machine plays
	end
	interface.selected = {}
	interface.selected_cnt = 0
	machine.video.throttled = throttled_state
end

return interface
