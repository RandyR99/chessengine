interface = {}

interface.level = 1
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	repeat
		send_input(":IN.1", 0x80, 0.6) -- Level
		local cur_level = 0
		for y=0,7 do
			if output:get_value("1." .. tostring(7 - y)) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until cur_level == interface.level
end

function interface.setup_machine()
	sb_reset_board(":board")
    send_input(":RESET", 0x01, 0.6) -- New Game
	emu.wait(1.0)

	interface.cur_level = 1
	interface.setlevel()
end

if false then -- not reliable!
function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local ram = emu.item(machine.devices[':maincpu'].items['0/00000000-0000ffff'])
		local fig = {0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		for x=1,8 do
			for y=1,8 do
				local p=get_piece_id(x,y)
				local z=fig[p+7]
				ram:write(16*(x-1)+y-1,z)
			end
		end
		if mode==-1 then
			ram:write(0xf5,0x02)
		end
	end
end
end

function interface.start_play(init)
	send_input(":IN.1", 0x20, 1) -- Reverse Play
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = output:get_value("0." .. tostring(8 - x)) ~= 0
	local yval = output:get_value("1." .. tostring(8 - y)) ~= 0
	return xval and yval
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

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote_special(piece)
	if     (piece == "r") then send_input(":IN.0", 0x08, 0.6)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 0.6)
	elseif (piece == "n") then send_input(":IN.0", 0x20, 0.6)
	end
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
end

return interface
