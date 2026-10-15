interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 63
interface.cur_level = nil
local promcode = 0

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local cl = interface.cur_level % 100
	local nl = interface.level % 100
	interface.cur_level = interface.level
	local dl = nl - cl

	send_input(":IN.1", 0x02, 0.5) -- Level
	if dl>90 then dl=dl-100
	elseif dl<-95 then dl=dl+100
	end
	while dl > 5 or dl < -9 do
		send_input(":IN.1", 0x02, 0.6) -- Level
		cl = (cl + 10) % 100
		dl = nl - cl
	end
	for i=1,math.abs(dl) do
		if dl > 0 then send_input(":IN.0", 0x10, 0.6) -- Fwd
		else send_input(":IN.1", 0x10, 0.6) -- Back
		end
	end
	send_input(":IN.0", 0x01, 0.5) -- Yes
end

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
	emu.wait(2)

	interface.cur_level = 63
	interface.setlevel()
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.5) -- Yes
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x80, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x80, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x40, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x40, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x20, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x20, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x04, 0.5) -- Position
		send_input(":IN.0", 0x01, 0.5) -- Yes
		send_input(":IN.0", 0x01, 0.5) -- Yes
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					setpiece(math.abs(p))
					if p*piece<0 then
						if p<0 then
							send_input(":IN.0", 0x10, 0.5) -- Black
						else
							send_input(":IN.1", 0x10, 0.5) -- White
						end
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		-- the colour selected last is the side to move
		if mode<0 then
			send_input(":IN.0", 0x10, 0.5) -- Black
		else
			send_input(":IN.1", 0x10, 0.5) -- White
		end
		send_input(":IN.0", 0x02, 0.5) -- No
--		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Yes
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x01, 0.5) -- Option
	send_input(":IN.0", 0x01, 0.5) -- Yes
	send_input(":IN.0", 0x02, 0.5) -- No
end

function interface.is_selected(x, y)
	return output_value(tostring(8-y) .. "." .. tostring(x-1)) ~= 0
end

function interface.select_piece(x, y, event)
	emu.wait(0.5)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "spin", "Level", "63", "1", "100"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 100) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	promcode = 1
	if     output_value("s1.14") ~= 0 then return "q"
	elseif output_value("s1.16") ~= 0 then return "r"
	elseif output_value("s1.17") ~= 0 then return "b"
	elseif output_value("s1.19") ~= 0 then return "n"
	end
end

function interface.promote(x, y, piece)
	if promcode == 0 then
		if     (piece == "q") then send_input(":IN.1", 0x80, 0.5)
		elseif (piece == "r") then send_input(":IN.0", 0x40, 0.5)
		elseif (piece == "b") then send_input(":IN.1", 0x40, 0.5)
		elseif (piece == "n") then send_input(":IN.1", 0x20, 0.5)
		end
	end
	promcode = 0
	sb_promote(":board", x, y, piece)
end

return interface
