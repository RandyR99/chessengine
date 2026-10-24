interface = {}

interface.level = 3
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setdigit(n)
	if     (n == 0) then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 1) then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 2) then send_input(":IN.0", 0x08, 0.5)
	elseif (n == 3) then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 4) then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 5) then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 6) then send_input(":IN.2", 0x08, 0.5)
	elseif (n == 7) then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 8) then send_input(":IN.3", 0x08, 0.5)
	elseif (n == 9) then send_input(":IN.2", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	send_input(":IN.1", 0x04, 0.5) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.setup_machine()
--	sb_reset_board(":board:board")
--	send_input(":RESET", 0x01, 0.5) -- RES
	emu.wait(1.0)

	interface.cur_level = 3
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.2", 0x01, 0.5) -- POS
		for i=1,14 do
			send_input(":IN.0", 0x04, 0.5) -- ENT
		end
		return (":board:board")
	else
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p>0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8-math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9-y)
					send_input(":IN.0", 0x04, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.0", 0x04, 0.5) -- ENT
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.3", 0x04, 0.5) -- MEM
	else
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.is_selected(x, y)
	local z = (x-1)+(y-1)*8
	return output_value("led"..tostring(z)) ~= 0x00
end

function interface.send_pos(p)
	if     (p == 1) then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 2) then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 3) then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 4) then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 5) then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 6) then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 7) then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 8) then send_input(":IN.3", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event == "get_castling" or event == "en_passant" or event == "capture") then
		emu.wait(1)
	end
	sb_select_piece(":board:board", 1, x, y, event)
	return
end

function interface.get_options()
	return { { "spin", "Level", "3", "0", "9"}, }
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
	send_input(":IN.1", 0x01, 0.5) -- INFO
	send_input(":IN.0", 0x02, 0.5) -- 1
	send_input(":IN.3", 0x01, 0.5) -- 0
	local d0 = 0
	local d3 = output_value("digit3") & 0x7f
	local d2 = output_value("digit2") & 0x7f
	if (d3 == 0x73 and d2 == 0x50) then -- display shows 'Pr'
		d0 = output_value("digit0") & 0x7f
	end
	send_input(":IN.1", 0x01, 0.5) -- INFO
	if     (d0 == 0x5e) then return "q"
	elseif (d0 == 0x31) then return "r"
	elseif (d0 == 0x38) then return "b"
	elseif (d0 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x02, 0.5)
	elseif (piece == "b") then send_input(":IN.1", 0x08, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x02, 0.5)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.0", 0x04, 0.5) -- ENT
	end
end

return interface
