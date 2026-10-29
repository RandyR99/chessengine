interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

-- true if the annunciator is (or blinks) on within the given time
local function lit(name, seconds)
	local t = machine.time:as_double() + seconds
	repeat
		if output_value(name) ~= 0 then return true end
		emu.wait(0.05)
	until machine.time:as_double() > t
	return false
end

interface.turn = true
interface.invert = false
interface.selected = {}
interface.selected_cnt = 0
interface.level = 1
interface.cur_level = nil
interface.edit = false
interface.edit_moves = 0

function interface.get_module()
	if machine.system.name == "savant" then
		return "Novag Savant"
	elseif machine.system.name == "savant2" then
		return "Novag Savant II"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level_id = { 0x182418, 0x381010, 0x3c1818, 0x3c383c, 0x207c20, 0x1c1c3c, 0x181c18, 0x04103c, 0x181818, 0x183818 }
	repeat
		local levid = 0
		send_input(":IN.2", 0x04, 1) -- Set Level
		for x = 0, 7 do
			if (output_value(tostring(x) .. "." .. tostring(50 - (8 - 1) * 3)) == 1) then levid = levid | (1 << x)	end
			if (output_value(tostring(x) .. "." .. tostring(50 - (5 - 1) * 3)) == 1) then levid = levid | (1 << (8 + x))	end
			if (output_value(tostring(x) .. "." .. tostring(50 - (2 - 1) * 3)) == 1) then levid = levid | (1 << (16 + x))	end
		end
	until level_id[interface.level + 1] == levid
	send_input(":IN.1", 0x10, 1) -- Return
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	interface.selected = {}
	interface.selected_cnt = 0
	emu.wait(1)
	send_input(":IN.2", 0x08, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function setpiece(n)
	if     (n == 2) then send_input(":IN.1", 0x40, 1) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x04, 1) -- R
	elseif (n == 4) then send_input(":IN.0", 0x40, 1) -- B
	elseif (n == 5) then send_input(":IN.0", 0x04, 1) -- N
	elseif (n == 6) then send_input(":IN.2", 0x04, 1) -- P
	end
end

-- board square as shown on the LCD (the board turns round when the player has black)
local function lcd_square(x, y)
	if interface.invert then
		return 9 - x, 9 - y
	end
	return x, y
end

-- in Set Up mode: clear the board and enter the position of the plugin's board
local function setup_board()
	send_input(":IN.0", 0x80, 1) -- Clear Board
	emu.wait(1)
	-- only the two kings are left, wherever they stood
	local kings = {}
	for y = 1, 8 do
		for x = 1, 8 do
			local lx, ly = lcd_square(x, y)
			if output_value(tostring(lx - 1) .. "." .. tostring(50 - (ly - 1) * 3)) == 1 then
				local black = output_value(tostring(lx - 1) .. "." .. tostring(23 - (ly - 1) * 3)) == 1
				kings[black and -1 or 1] = { x = x, y = y }
			end
		end
	end
	local target = {}
	for y = 1, 8 do
		for x = 1, 8 do
			local p = get_piece_id(x, y)
			if p == 1 or p == -1 then target[p] = { x = x, y = y } end
		end
	end
	local function move_king(k, to)
		local fx, fy = lcd_square(kings[k].x, kings[k].y)
		local tx, ty = lcd_square(to.x, to.y)
		sb_press_square(":board", 1, fx, fy)
		sb_press_square(":board", 1, tx, ty)
		kings[k] = { x = to.x, y = to.y }
	end
	local function same(a, b) return a.x == b.x and a.y == b.y end
	if kings[1] and kings[-1] and target[1] and target[-1] then
		if same(target[1], kings[-1]) and same(target[-1], kings[1]) then
			-- the kings swap squares: park the white king on a square that stays empty
			for y = 1, 8 do
				for x = 1, 8 do
					if get_piece_id(x, y) == 0 and not same({ x = x, y = y }, kings[1]) and not same({ x = x, y = y }, kings[-1]) then
						move_king(1, { x = x, y = y })
						goto parked
					end
				end
			end
			::parked::
		end
		local first, second = 1, -1
		if same(target[1], kings[-1]) then first, second = -1, 1 end
		if not same(kings[first], target[first]) then move_king(first, target[first]) end
		if not same(kings[second], target[second]) then move_king(second, target[second]) end
	end
	-- the entry colour starts as the player's colour
	local colour = 1
	if lit("1.24", 0.5) or lit("2.24", 0.5) then colour = -1 end
	for y = 1, 8 do
		for x = 1, 8 do
			local p = get_piece_id(x, 9 - y)
			if math.abs(p) > 1 then
				if p * colour < 0 then
					send_input(":IN.1", 0x80, 1) -- Change Color
					colour = -colour
				end
				setpiece(math.abs(p))
				sb_press_square(":board", 1, lcd_square(x, 9 - y))
			end
		end
	end
end

function interface.edit_game(mode)
	if mode then
		interface.edit = true
		interface.edit_moves = 0
		return
	end
	interface.edit = false
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if interface.edit_moves % 2 == 1 then
		-- the side to move changes: swap sides and let the machine move (Set Up keeps the side to move)
		send_input(":IN.1", 0x80, 1) -- Change Color
		interface.invert = not interface.invert
		send_input(":IN.2", 0x10, 1) -- Go
		-- wait for Your Move (book moves come at once); a second Go cuts a long search short
		local t0 = machine.time:as_double()
		local forced = false
		emu.wait(0.5)
		repeat
			if lit("5.25", 1) then break end
			if not forced and machine.time:as_double() - t0 > 3 then
				send_input(":IN.2", 0x10, 1) -- Go: move now
				forced = true
			end
		until machine.time:as_double() - t0 > 60
	end
	send_input(":IN.2", 0x80, 1) -- Set Up
	setup_board()
	send_input(":IN.2", 0x80, 1) -- Set Up
	emu.wait(1)
	interface.selected = {}
	interface.selected_cnt = 0
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x04, 1) -- Sound on/off
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if mode == -1 then
			send_input(":IN.2", 0x10, 1) -- Go
			emu.wait(2)
		end
		send_input(":IN.2", 0x80, 1) -- Set Up
		send_input(":IN.0", 0x80, 1) -- Clear Board
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == -1 then
					sb_press_square(":board", 1, 5, 8)
					sb_press_square(":board", 1, x, y)
				elseif p == 1 then
					sb_press_square(":board", 1, 5, 1)
					sb_press_square(":board", 1, x, y)
				end
			end
		end
		local piece = 1
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if math.abs(p) > 1 then
					if p * piece < 0 then
						send_input(":IN.1", 0x80, 1) -- Change Color
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 1, x, 9 - y)
					piece = p
				end
			end
		end
		send_input(":IN.2", 0x80, 1) -- Set Up
		if mode == -1 then
			send_input(":IN.1", 0x80, 1) -- Change Color
			interface.invert = true
		end
		send_input(":IN.0", 0x04, 1) -- Sound on/off
	end
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x80, 1) -- Change Color
	send_input(":IN.2", 0x10, 1) -- Go
	interface.turn = not interface.turn
	interface.invert = not interface.invert
	machine.video.throttled = throttled_state
end

function interface.stop_play()
	send_input(":IN.2", 0x10, 1) -- Go
end

function interface.is_pos_selected(x, y, piece)
	local piece_id = get_piece_id(x, y)
	local selected = (piece_id == 0 and piece ~= 0) or (piece_id > 0 and piece <= 0) or (piece_id < 0 and piece >= 0)
	if (selected) then
		interface.selected[y*10+x] = piece_id
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

function interface.is_selected_int(x, y)
	local piece0 = output_value(tostring(x - 1) .. "." .. tostring(50 - (y - 1) * 3))
	local piece1 = output_value(tostring(x - 1) .. "." .. tostring(23 - (y - 1) * 3))
	if (interface.invert) then
		piece0 = output_value(tostring(8 - x) .. "." .. tostring(50 - (8 - y) * 3))
		piece1 = output_value(tostring(8 - x) .. "." .. tostring(23 - (8 - y) * 3))
	end
	local piece = 0
	if (piece0 == 1 and piece1 == 1) then		piece = -1
	elseif (piece0 == 1 and piece1 == 0) then	piece = 1
	end
	return interface.is_pos_selected(x, y, piece)
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.5)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.select_piece(x, y, event)
	if interface.edit then
		-- edit_game sets up the final position, just count the moves
		if event == "put" then
			interface.edit_moves = interface.edit_moves + 1
		end
		return
	end
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	if (interface.turn) then
		if (event == "get") then
			interface.from = { x = x, y = y }
			sb_select_piece(":board", 1, x, y, event)
		elseif (event == "put") then
			sb_select_piece(":board", 1, x, y, event)
			-- the machine sometimes misses a touch. Once the move is taken it computes
			-- and the FROM square is dark; a lifted piece blinks there, an untouched one is steady
			local from = interface.from
			for try = 1, 3 do
				if from == nil or lit("6.25", 2) then break end
				local n, on = 0, 0
				local t = machine.time:as_double() + 1
				repeat
					n = n + 1
					on = on + output_value(tostring(from.x - 1) .. "." .. tostring(50 - (from.y - 1) * 3))
					emu.wait(0.05)
				until machine.time:as_double() > t
				if on == 0 then break end
				if on == n then
					sb_select_piece(":board", 1, from.x, from.y, "get") -- FROM was missed
				end
				sb_select_piece(":board", 1, x, y, event)
			end
			interface.from = nil
		end
	end
	if (event == "put") then
		interface.turn = not interface.turn
		interface.selected = {}
		interface.selected_cnt = 0
		emu.wait(2)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "9" },
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
end

function interface.get_promotion(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local   piece =  tostring(output_value(tostring(x - 1) .. "." .. tostring(22 - (y - 1) * 3)))
	piece = piece .. tostring(output_value(tostring(x - 1) .. "." .. tostring(49 - (y - 1) * 3)))
	piece = piece .. tostring(output_value(tostring(x - 1) .. "." .. tostring(21 - (y - 1) * 3)))
	piece = piece .. tostring(output_value(tostring(x - 1) .. "." .. tostring(48 - (y - 1) * 3)))
	if     piece == "0110" then return 'q'
	elseif piece == "0100" then return 'r'
	elseif piece == "0011" then return 'b'
	elseif piece == "1000" then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.edit then
		return
	end
	if interface.turn == false and interface.get_promotion(x, y) ~= piece:lower() then
		send_input(":IN.2", 0x40, 1) -- Promote
		if     piece == "q" then send_input(":IN.1", 0x40, 1)
		elseif piece == "r" then send_input(":IN.1", 0x04, 1)
		elseif piece == "b" then send_input(":IN.0", 0x40, 1)
		elseif piece == "n" then send_input(":IN.0", 0x04, 1)
		end
	end
end

return interface
