interface = {}

interface.level = "1"
interface.cur_level = nil
interface.edit = false

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local lev1 = interface.cur_level
	local lev2 = interface.level
	interface.cur_level = interface.level
	local level = interface.level
	local n = (lev2 - lev1 + 16) % 16
	if output:get_value("0.7") ~= 0 then
		n = n + 1
	end
	for i=1,n do
		send_input(":IN.1", 0x08, 0.5) -- Level
	end
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
--	send_input(":IN.1", 0x10, 0.5)	-- New

	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x20, 0.5)	-- Set Up
		send_input(":IN.1", 0x08, 0.5)	-- Level
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						if p>0 then
							send_input(":IN.1", 0x80, 0.5) -- White
						else
							send_input(":IN.1", 0x40, 0.5) -- Black
						end
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x40>>math.abs(p), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode==1 then
			send_input(":IN.1", 0x80, 0.5) -- White
		else
			send_input(":IN.1", 0x40, 0.5) -- Black
		end
		send_input(":IN.1", 0x04, 0.5)	-- Take Back
	end
end

function interface.edit_game(on)
	interface.edit = on
end

function interface.start_play(init)
	send_input(":IN.1", 0x02, 0.5)	-- Play
end

function interface.is_selected(x, y)
	local xval = output:get_value("0." .. tostring(x - 1)) ~= 0
	local yval = output:get_value("1." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
		if interface.edit and event == "put" then
			send_input(":IN.1", 0x04, 0.5)	-- Take Back
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "16"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 16) then
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
	sb_promote(":board", x, y, "q")	-- TODO
end

return interface
