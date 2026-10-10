interface = {}

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

local mate_piece = nil
interface.level = "P2"
interface.cur_level = nil

function interface.get_module()
	return "Consumenta Conchess"
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local cur_level = (interface.cur_level .. "6"):sub(1,2)
	local level = (interface.level .. "6"):sub(1,2)
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local count = 1
	if (level:sub(2,2) ~= cur_level:sub(2,2) and level:sub(1,1):match("[TM]")) then
		count = 2
	end
	send_input(":IN.0", 0x40, 0.5) -- Level
	emu.wait(0.5)
	for i = 1, count do
		send_input(":IN.1", 0x01 << (tonumber(level:sub(2,2)) - 1), 0.5)
	end
	emu.wait(0.5)
	send_input(":IN.0", 0x02, 0.5) -- Stop
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "P2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x01, 0.5) -- Clear
		send_input(":IN.0", 0x80, 0.5) -- Continue
		send_input(":IN.0", 0x20, 0.5) -- 4 Arrows
		send_input(":IN.0", 0x01, 0.5) -- Clear
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 0
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece <= 0 then
						if p > 0 then
							send_input(":IN.1", 0x40, 0.5) -- White
						else
							send_input(":IN.1", 0x80, 0.5) -- Black
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.1", 0x40 >> math.abs(p), 0.5)
					end
					sb_select_piece(":board", 1, x, 9 - y, "get")
					sb_select_piece(":board", 1, x, 9 - y, "put")
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":IN.1", 0x40, 0.5) -- White
		else
			send_input(":IN.1", 0x80, 0.5) -- Black
		end
		send_input(":IN.0", 0x02, 0.5) -- Stop
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.0", 0x40, 0.5) -- 2 Arrows
		emu.wait(0.5)
		send_input(":IN.0", 0x10, 0.5) -- Referee
		emu.wait(0.5)
		send_input(":IN.0", 0x02, 0.5) -- Stop
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	else
		interface.start_play()
	end
end

function interface.start_play(init)
	if (led_on("9.7")) then
		send_input(":IN.1", 0x80, 0.5) -- Black
	elseif (led_on("9.6")) then
		send_input(":IN.1", 0x40, 0.5) -- White
	end
end

function interface.stop_play()
	send_input(":IN.0", 0x02, 1) -- Stop
end

local function square_lit(x, y)
	return led_on(tostring(9 - x) .. "." .. (y - 1))
end

-- When capturing en passant the machine blinks the captured pawn next to the
-- capturing one before it shows the destination; don't report it as a target.
local function ep_victim(x, y)
	local p = get_piece_id(x, y)
	if (p == 6 and y == 4) or (p == -6 and y == 5) then
		for dx = -1, 1, 2 do
			if x + dx >= 1 and x + dx <= 8 and get_piece_id(x + dx, y) == -p and square_lit(x + dx, y) then
				return true
			end
		end
	end
	return false
end

function interface.is_selected(x, y)
	return square_lit(x, y) and not ep_victim(x, y)
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "P2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):upper() -- trim
		if (level:match("^L[1-5]$")) then
			level = "P" .. level:sub(2,2)
		elseif (level:match("^L[6-9]$") or level:match("^L10$")) then
			level = "T" .. tostring(tonumber(level:sub(2,3)) - 5)
		elseif (level:match("^[PT][1-5]$") == nil and level:match("^[AM]$") == nil) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local piece = nil
	if (not led_on("0.6")) then -- mate announcement!
		for i = 0, 5 do
			if     (led_on("9.4")) then piece = 'q'
			elseif (led_on("9.3")) then piece = 'r'
			elseif (led_on("9.2")) then piece = 'b'
			elseif (led_on("9.1")) then piece = 'n'
			end
			if piece ~= nil then
				break
			end
			emu.wait(0.1)
		end
		mate_piece = piece
		return nil
	end
	piece = mate_piece
	mate_piece = nil
	for i = 0, 5 do
		if     (led_on("9.4")) and (piece ~= 'q') then return 'q'
		elseif (led_on("9.3")) and (piece ~= 'r') then return 'r'
		elseif (led_on("9.2")) and (piece ~= 'b') then return 'b'
		elseif (led_on("9.1")) and (piece ~= 'n') then return 'n'
		end
		emu.wait(0.2)
	end
	return piece
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q" or piece == "Q") then send_input(":IN.1", 0x10, 0.5)
	elseif (piece == "r" or piece == "R") then send_input(":IN.1", 0x08, 0.5)
	elseif (piece == "b" or piece == "B") then send_input(":IN.1", 0x04, 0.5)
	elseif (piece == "n" or piece == "N") then send_input(":IN.1", 0x02, 0.5)
	end
end

return interface
