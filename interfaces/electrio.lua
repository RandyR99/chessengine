interface = {}

interface.level = 1
interface.cur_level = nil
local ram = emu.item(machine.devices[':maincpu'].items['0/00000000-0000ffff'])

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	ram:write(0x18,interface.level-1)
	machine:popmessage("Level " .. tostring(interface.level))
end

function interface.setup_machine()
	sb_reset_board(":board0")
	emu.wait(5)

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play()
	send_input(":IN.0", 0x04, 1) -- Play
end

if false then -- not reliable!
function interface.set_pos(mode)
	if mode == 0 then
		return (":board0")
	else
		if (mode == -1) then
			send_input(":IN.0", 0x10, 1) -- Multi Move
			sb_press_square(":board0", 1, 1, 2) -- a2
			sb_press_square(":board0", 1, 1, 3) -- a3
			send_input(":IN.0", 0x10, 1) -- Multi Move
		end
		local fig = {0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		for x=1,8 do
			for y=1,8 do
				local p=get_piece_id(x,y)
				local z=fig[p+7]
				ram:write(16*(x-1)+y-1,z)
			end
		end
	end
end
end

function interface.edit_game()
	send_input(":IN.0", 0x10, 1) -- Multi Move
end

function interface.is_selected(x, y)
	local xval = output:get_value("0."..tostring(8 - x)) ~= 0
	local yval = output:get_value("0."..tostring(y + 7)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board0", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board0", x, y)
	else
		sb_select_piece(":board0", 0.5, x, y, event)
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
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

function interface.test_promotion(x, y)
	emu.wait(0.5)
	local p=ram:read(16*(x-1)+y-1)&0x07
	if     p == 0x05 then return "Q"
	elseif p == 0x04 then return "R"
	elseif p == 0x03 then return "B"
	elseif p == 0x02 then return "N"
	else return "Q"
	end
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		emu.wait(1.5)
		promotion_error(piece)
		sb_promote(":board0", x, y, "q")
	else
		sb_promote(":board0", x, y, piece)
 	end
end

return interface
