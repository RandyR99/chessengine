interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil
local hold = 0.5

function interface.get_module()
	if machine.system.name == "nmicro2" then
		return "Novag Micro Chess II"
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
	send_input(":IN.0", 0x10, hold) -- LEVEL
	emu.wait(0.75 - hold)
	local k = 8
	while output_value("0." .. tostring(k - 1)) == 0 do
		k = k - 1
	end
	k = (interface.level - k + 8) % 8
	for i = 1, k do
		send_input(":IN.0", 0x10, hold) -- LEVEL
		emu.wait(0.75 - hold)
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	hold = 0.5
	if machine.ioport.ports[":CPU"]:read() & 1 ~= 0 then -- 15MHz
		hold = 0.25
	end
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x04, hold) -- SET UP
		emu.wait(0.75 - hold)
		sb_clear_board(":board")
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local mem = machine.devices[":maincpu"].spaces["data"]
		local fig = {0x09, 0x0b, 0x0a, 0x0c, 0x0e, 0x0d, 0x00, 0x05, 0x06, 0x04, 0x02, 0x03, 0x01}
		local adr = 0x0040
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, y)
				local z = (mem:read_u8(adr + 8 * (x - 1) + y - 1)) & 0xf0|fig[p + 7]
				mem:write_u8(adr + 8 * (x - 1) + y - 1, z)
			end
		end
		local x0, y0, z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p == mode then
						x0 = x
						y0 = 9 - y
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_move_piece(":board", x, 9 - y)
					emu.wait(0.75 - hold)
				end
			end
		end
		if mode == -1 then
			send_input(":IN.0", 0x01, hold) -- B/W
			emu.wait(0.75 - hold)
		end
		send_input(":IN.0", 0x40, hold) -- King
		emu.wait(0.75 - hold)
		sb_press_square(":board", 0.5, x0, y0)
		sb_press_square(":board", 0.5, x0, y0)
		send_input(":IN.0", 0x80, hold) -- GO
		emu.wait(0.75 - hold)
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x80, hold) -- Go
	emu.wait(0.75 - hold)
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(x - 1)) ~= 0
	local yval = output_value("0." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 0.5, x, y, event)
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
	sb_promote(":board", x, y, "q")	-- the machine only takes a queen
end

return interface
