interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "c1"
interface.cur_level = nil
local throttled = true

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.1", 0x20, 0.5) -- Level
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x20, 0.5) -- Level
end

function interface.setup_machine()
	sb_reset_board(":board")
--	send_input(":IN.1", 0x08, 0.5) -- New Game
	emu.wait(1)

	interface.cur_level = "g1"
	interface.setlevel()
end

function interface.start_play()
	send_input(":IN.1", 0x10, 0.5) -- Move
end

function setcastling(c)
	local y=1
	local n=2
	if c==-1 then
		y=8
		n=1
	end
	if get_piece_id(5,y)~=c then
		for i=1,n do
			sb_press_square(":board", 0.5, 5, y)
		end
	else
		if get_piece_id(1,y)~=3*c then
			for i=1,n do
				sb_press_square(":board", 0.5, 1, y)
			end
		end
		if get_piece_id(8,y)~=3*c then
			for i=1,n do
				sb_press_square(":board", 0.5, 8, y)
			end
		end
	end

end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x80, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Set Up
		return (":board")
	else
		setcastling(1)
		setcastling(-1)
		local z=1
		if mode==-1 then
			z=8
		end
		for i=1,3 do
			sb_press_square(":board", 0.5, 4, z)
		end
		local fig = {0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local ram = machine.devices[":maincpu"].spaces["data"]
		local adr = 0x40 -- board, rank by rank from a1
		for x=1,8 do
			for y=1,8 do
				local p=get_piece_id(x,y)
				local z=fig[p+7]
				ram:write_u8(adr+8*(y-1)+x-1,z)
			end
		end
		send_input(":IN.1", 0x40, 0.5) -- Set Up
		send_input(":IN.1", 0x80, 0.5) -- Sound
	end
end

function interface.edit_game()
	local tmp = interface.level:sub(1,1)
	if     tmp == "c" then tmp = "a"
	elseif tmp == "d" then tmp = "b"
	elseif tmp == "a" then tmp = "c"
	elseif tmp == "b" then tmp = "d"
	end
	interface.level = tmp..interface.level:sub(2,2)
	throttled = machine.video.throttled
	machine.video.throttled = false
	interface.setlevel()
	machine.video.throttled = throttled
end

function interface.is_selected(x, y)
	if output_value("4.a") ~= 0 then
		return
	end
	local xval = output_value("1." .. x - 1) ~= 0
	local yval = output_value("0." .. y - 1) ~= 0
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
	return {{"string", "Level", "c1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[cd][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
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
