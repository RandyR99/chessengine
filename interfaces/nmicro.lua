interface = {}

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "Novag Micro Chess"
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local level = interface.cur_level
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x02, 0.5) -- Sound
	emu.wait(0.25)
	send_input(":IN.0", 0x01, 0.5) -- Set Level
	emu.wait(0.25)
	local k = (interface.level - level + 8) % 8
	for i = 1, k do
		send_input(":IN.0", 0x01, 0.5) -- Set Level
		emu.wait(0.3)
	end
	send_input(":IN.0", 0x08, 0.5) -- Go
	emu.wait(0.25)
	send_input(":IN.0", 0x02, 0.5) -- Sound
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x80, 0.5) -- New Game
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

--[[
function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x40, 0.5) -- SET UP
		sb_clear_board(":board")
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = emu.item(machine.devices[':maincpu'].items['0/0000-ffff'])
		local fig = {0x06, 0x04, 0x03, 0x05, 0x02, 0x01, 0x00, 0x0f, 0x0e, 0x0b, 0x0d, 0x0c, 0x0a}
		local adr = 0x0fc0
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				local z = (ram:read(adr + 8 * (y - 1) + x - 1)) & 0xf0|fig[p + 7]
				ram:write(adr + 8 * (y - 1) + x - 1, z)
			end
		end
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_move_piece(":board", x, 9 - y)
					emu.wait(0.5)
				end
			end
		end
		send_input(":IN.0", 0x08, 0.5) -- GO
		emu.wait(0.5)
		if mode == 1 then
			send_input(":IN.0", 0x40, 0.5) -- SET UP
			send_input(":IN.0", 0x10, 0.5) -- B/W
			send_input(":IN.0", 0x08, 0.5) -- GO
			emu.wait(0.5)
		end
	end
	machine.video.throttled = throttled_state
end
--]]

function interface.start_play(init)
	send_input(":IN.0", 0x08, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval,yval
	if (x < 7) then
		xval = output:get_indexed_value("0.", (x - 1)) ~= 0
	else
		xval = output:get_indexed_value("1.", (x - 3)) ~= 0
	end
	if (y > 2) then
		yval = output:get_indexed_value("2.", (8 - y)) ~= 0
	else
		yval = output:get_indexed_value("1.", (2 - y)) ~= 0
	end
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
		emu.wait(0.3)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q") -- TODO
end

return interface
