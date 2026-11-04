interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.level = 1
interface.cur_level = nil
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

-- MCU data RAM (160 x 4 bits)
local function ram()
	return machine.devices[":maincpu"].spaces["data"]
end

function interface.get_module()
	return "SciSys Mini Chess"
end

function interface.get_author()
	return "David Levy & Mark Taylor"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	send_input(":IN.4", 0x01, 0.6) -- Level
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cfg = ioport.ports[":IN.4"]:read()
	if (cfg == 4 or cfg == 5) then
		send_input(":IN.4", 0x04, 0.6) -- MM off
	end
	interface.turn = true
	send_input(":IN.3", 0x01, 1)  -- New Game
	machine.video.throttled = throttled_state
	interface.cur_level = (cfg % 2) + 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local fig = {0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x00, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01}
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				ram():write_u8(16 * (x - 1) + y - 1, z)
			end
		end
		-- castling rights (0x8b: 1 = O-O white, 2 = O-O-O white, 4 = O-O black, 8 = O-O-O black)
		-- the ROM trusts these bits without checking the rook, so set only those whose king and rook are home
		local castling = 0
		if get_piece_id(5, 1) == 1 then
			if get_piece_id(8, 1) == 3 then castling = castling | 0x01 end
			if get_piece_id(1, 1) == 3 then castling = castling | 0x02 end
		end
		if get_piece_id(5, 8) == -1 then
			if get_piece_id(8, 8) == -3 then castling = castling | 0x04 end
			if get_piece_id(1, 8) == -3 then castling = castling | 0x08 end
		end
		ram():write_u8(0x008b, castling)
		if mode == 1 then
			ram():write_u8(0x00c5, 0x01)
			ram():write_u8(0x0009, 0x0f)
			ram():write_u8(0x000b, 0x00)
			ram():write_u8(0x000d, 0x0f)
			ram():write_u8(0x000e, 0x00)
		else
			ram():write_u8(0x00c5, 0x02)
			ram():write_u8(0x0009, 0x00)
			ram():write_u8(0x000b, 0x0f)
			ram():write_u8(0x000d, 0x00)
			ram():write_u8(0x000e, 0x0f)
		end
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	send_input(":IN.4", 0x04, 0.5) -- MM
	interface.edit = on
	emu.wait(0.5)
end

function interface.start_play(init)
	interface.turn = not interface.turn
	send_input(":IN.3", 0x04, 0.6) -- Enter
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x01, 0.6)
	elseif (p == 2)	then send_input(":IN.0", 0x02, 0.6)
	elseif (p == 3)	then send_input(":IN.0", 0x04, 0.6)
	elseif (p == 4)	then send_input(":IN.1", 0x01, 0.6)
	elseif (p == 5)	then send_input(":IN.1", 0x02, 0.6)
	elseif (p == 6)	then send_input(":IN.1", 0x04, 0.6)
	elseif (p == 7)	then send_input(":IN.2", 0x01, 0.6)
	elseif (p == 8)	then send_input(":IN.2", 0x02, 0.6)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn or interface.edit) then
				send_input(":IN.3", 0x04, 0.6) -- Enter
				emu.wait(0.4)
			end
			if (not interface.edit) then
				interface.turn = not interface.turn
			end
		end
		machine.video.throttled = throttled_state
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 2) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
		local piece = ram():read_u8(16 * (x - 1) + y - 1)
	if     piece == 0x05 then return 'q'
	elseif piece == 0x04 then return 'r'
	elseif piece == 0x03 then return 'b'
	elseif piece == 0x02 then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	-- the machine always promotes to a queen by itself, nothing to enter
	promotion_error(piece)
end

return interface
