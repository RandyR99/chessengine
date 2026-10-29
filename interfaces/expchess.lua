interface = load_interface("compan2")

-- Explorer Chess: same program as the Companion II, but 12 buttons; Set Up, Clear Board, PVP (multi move)
-- and Sound are second functions (2nd F + piece key / New Game / Play / Level)

local function second(port, mask)
	send_input(":IN.0", 0x10, 0.5) -- 2nd F
	send_input(port, mask, 1)
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local n = (interface.level - interface.cur_level + 9) % 9
	interface.cur_level = interface.level
	for i=0,n do
		send_input(":IN.1", 0x08, 0.5) -- Level
	end
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x80, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x80, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x01, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x02, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x20, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x40, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		second(":IN.1", 0x01) -- Set Up (2nd F + a piece key; the 2nd F light stays on)
		send_input(":IN.0", 0x08, 1) -- New Game = Clear Board in set up
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x04, 0.5) -- White/Black
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.0", 0x04, 0.5) -- White/Black
		end
		second(":IN.1", 0x01) -- Set Up (2nd F + Rook)
	end
end

function interface.edit_game()
	second(":IN.1", 0x10) -- PVP
	emu.wait(0.5)
end

return interface
