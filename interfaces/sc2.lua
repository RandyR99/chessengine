interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.level = 1
interface.cur_level = nil
interface.invert = false	-- board mirrored (ranks swapped, colors swapped)
interface.stm = 1		-- side to move: 1 white, -1 black
interface.pending = false	-- position must be set up before the next move
interface.editing = false

function interface.get_module()
	if machine.system.name == "sc2" then
		return "VEB Schachcomputer SC-2"
	elseif machine.system.name == "sc2a" then
		return "VEB Schachcomputer SC-2 v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67, 0x3f }
	send_input(":IN.0", 0x04, 0.5) -- L (Clear)
	local tries = 0
	repeat
		send_input(":IN.3", 0x01, 0.5) -- K (Level)
		tries = tries + 1
	until output_value("digit3") == lcd_num[interface.level] or tries > 20
	send_input(":IN.0", 0x04, 0.5) -- L (Clear)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.stm = 1
	interface.pending = false
	interface.editing = false
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

-- Position setup
-- The SC 2 has a problem mode (P), but after it the player always has the
-- white pieces and must move first. So the position is entered when the
-- next move is known: with the player's side as white (ranks mirrored if the
-- player has black), and if the machine has to move first, with one of the
-- player's pieces put back on a square it could have come from, followed by
-- that move.

local function attacked(b, x, y, s)
	-- is square x,y attacked by side s (1 = white, -1 = black) on board b
	local function at(i, j)
		if i < 1 or i > 8 or j < 1 or j > 8 then return nil end
		return b[j][i]
	end
	if at(x - 1, y - s) == 6 * s or at(x + 1, y - s) == 6 * s then return true end
	for _, d in ipairs({ {1,2},{2,1},{-1,2},{-2,1},{1,-2},{2,-1},{-1,-2},{-2,-1} }) do
		if at(x + d[1], y + d[2]) == 5 * s then return true end
	end
	for _, d in ipairs({ {1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1} }) do
		if at(x + d[1], y + d[2]) == 1 * s then return true end
		local diag = d[1] ~= 0 and d[2] ~= 0
		local i, j = x + d[1], y + d[2]
		while at(i, j) == 0 do i, j = i + d[1], j + d[2] end
		local p = at(i, j)
		if p == 2 * s or (diag and p == 4 * s) or (not diag and p == 3 * s) then return true end
	end
	return false
end

local function find_premove(b)
	-- find a white piece on S and an empty X, so that X-S is a legal white move
	-- and the position with the piece on X is legal (black not in check)
	local kx, ky
	for y = 1, 8 do for x = 1, 8 do if b[y][x] == -1 then kx, ky = x, y end end end
	local dirs = {
		[2] = { {1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1} },
		[3] = { {1,0},{-1,0},{0,1},{0,-1} },
		[4] = { {1,1},{1,-1},{-1,1},{-1,-1} },
	}
	local knight = { {1,2},{2,1},{-1,2},{-2,1},{1,-2},{2,-1},{-1,-2},{-2,-1} }
	local king = dirs[2]
	local function ok(sx, sy, x, y)
		if x < 1 or x > 8 or y < 1 or y > 8 or b[y][x] ~= 0 then return false end
		local p = b[sy][sx]
		b[y][x], b[sy][sx] = p, 0
		local legal = kx == nil or not attacked(b, kx, ky, 1)
		b[sy][sx], b[y][x] = p, 0
		return legal
	end
	-- prefer pieces whose move doesn't touch castling: N, B, Q, R, K, P
	for _, piece in ipairs({ 5, 4, 2, 3, 1, 6 }) do
		for sy = 1, 8 do
			for sx = 1, 8 do
				if b[sy][sx] == piece then
					local castle_piece = (piece == 1 and sx == 5 and sy == 1) or
						(piece == 3 and sy == 1 and (sx == 1 or sx == 8) and b[1][5] == 1)
					if not castle_piece then
						if piece == 5 or piece == 1 then
							for _, d in ipairs(piece == 5 and knight or king) do
								if ok(sx, sy, sx + d[1], sy + d[2]) then return sx, sy, sx + d[1], sy + d[2] end
							end
						elseif piece == 6 then
							if sy >= 3 and ok(sx, sy, sx, sy - 1) then return sx, sy, sx, sy - 1 end
						else
							for _, d in ipairs(dirs[piece]) do
								local x, y = sx + d[1], sy + d[2]
								while x >= 1 and x <= 8 and y >= 1 and y <= 8 and b[y][x] == 0 do
									if ok(sx, sy, x, y) then return sx, sy, x, y end
									x, y = x + d[1], y + d[2]
								end
							end
						end
					end
				end
			end
		end
	end
	return nil
end

local function setup_board(machine_first)
	-- the player gets white on the machine; mirror if the player has black
	local player = machine_first and -interface.stm or interface.stm
	interface.invert = (player == -1)
	local b = {}
	for y = 1, 8 do
		b[y] = {}
		for x = 1, 8 do
			local p = get_piece_id(x, interface.invert and 9 - y or y)
			b[y][x] = interface.invert and -p or p
		end
	end
	local sx, sy, px, py
	if machine_first then
		sx, sy, px, py = find_premove(b)
		if sx == nil then
			return false
		end
		b[py][px], b[sy][sx] = b[sy][sx], 0
	end

	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.3", 0x04, 1) -- R (Reset)
	emu.wait(1)
	interface.cur_level = -1
	interface.setlevel()
	send_input(":IN.3", 0x08, 1) -- P (Problem)
	local code = { 3, 1, 8, 6, 4, 2 } -- K Q R B N P -> key 3 (C), 1 (A), 8, 6, 4, 2
	for y = 1, 8 do
		for x = 1, 8 do
			local p = b[y][x]
			if p ~= 0 then
				interface.send_pos(x)
				interface.send_pos(y)
				if p > 0 then
					interface.send_pos(5) -- E (white)
				end
				interface.send_pos(code[math.abs(p)])
				send_input(":IN.0", 0x08, 0.5) -- Q (Enter)
			end
		end
	end
	send_input(":IN.3", 0x08, 1) -- P (Problem)
	if machine_first then
		interface.send_pos(px)
		interface.send_pos(py)
		interface.send_pos(sx)
		interface.send_pos(sy)
		send_input(":IN.0", 0x08, 1) -- Q (Enter)
	end
	machine.video.throttled = throttled_state
	interface.pending = false
	return true
end

function interface.set_pos(mode)
	if mode == 0 then
		return ""
	end
	interface.stm = mode
	interface.pending = true
end

function interface.edit_game(start)
	interface.editing = start
	if not start then
		interface.pending = true
	end
end

function interface.start_play(init)
	if interface.pending or (not init and interface.turn) then
		-- the machine has to move first from a set up position
		interface.turn = false
		setup_board(true)
	elseif (init) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		interface.turn = false
		send_input(":IN.3", 0x02, 1) -- W (White)
		emu.wait(0.5)
		send_input(":IN.0", 0x08, 1) -- Q (Enter)
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.is_selected(x, y)
	if interface.invert then
		y = 9 - y
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.1", 0x01, 0.5)
	elseif (p == 2)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 5)	then send_input(":IN.2", 0x01, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 7)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 8)	then send_input(":IN.2", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event == "put") then
		interface.stm = -interface.stm
	end
	if interface.editing then
		return
	end
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if interface.pending and interface.turn and event == "get" then
			-- the player moves first from a set up position
			setup_board(false)
		end
		if interface.invert then
			y = 9 - y
		end
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn) then
				send_input(":IN.0", 0x08, 1)
			end
			interface.turn = not interface.turn
		end
		machine.video.throttled = throttled_state
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "10" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 10) then
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
	-- nothing to press: a queen is assumed
end

return interface
