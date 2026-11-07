-- Rotating Display of the Fidelity 68000 Elite family (feagv4 and its clones, premiere): switched on at setup, then
-- the display changes every second while the machine thinks: the moves ("d7d5"), the score in centipawns for the
-- machine (dot after the second character, output 5.7; "-9.99" is its limit) and the moves examined followed by the
-- ply depth ("12 6")
local rotating = {}

local function display_value(name)
	local out = machine.devices[":display"]:output(name)
	return out ~= nil and out:get() or 0
end

-- manual chart: squares A2-H2 on the second OPTION page; call it right after a CLEAR, with the options closed
function rotating.setup()
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	send_input(":IN.0", 0x02, 1) -- option
	emu.wait(0.2)
	for _, x in ipairs({ 1, 2, 3, 5, 6, 7 }) do -- A2 turns the time off, the others are off after power-on
		sb_press_square(":board", 1, x, 2)
		emu.wait(0.5)
	end
	-- OPTION opens the page used last, and edit_game needs the game options ("OPn1") for Monitor Mode
	for _ = 1, 3 do
		if display_value("digit6") == 0x3f and display_value("digit5") == 0x73 then
			break
		end
		send_input(":IN.0", 0x02, 1) -- option
		emu.wait(0.2)
	end
	send_input(":IN.1", 0x01, 1) -- clear
	emu.wait(0.2)
end

local function led_on(x, y)
	local out = machine.devices[":"]:output((y - 1) .. "." .. (7 + x))
	return out ~= nil and out:get() ~= 0
end

-- the human window (digits 1 0 2 3) names the OPTION page: GAME dISP PUAL LOAd SAUE dELE, then GAME again
local function vancouver_page(a, b, c, d)
	return display_value("digit1") == a and display_value("digit0") == b and display_value("digit2") == c
		and display_value("digit3") == d
end

-- Premiere with the Vancouver program (manual: Display Options chart): the computer's rotating display is on the
-- "dISP" page, rank 1: A1 depth, B1 score, C1-G1 moves of the main line, H1 the move being searched. Nothing on
-- rank 1 is on after power-on, only the move time (E2), which always stays in the rotation.
function rotating.setup_vancouver()
	for _ = 1, 7 do
		send_input(":IN.0", 0x02, 1) -- option
		emu.wait(0.2)
		if vancouver_page(0x5e, 0x06, 0x6d, 0x73) then -- dISP
			break
		end
	end
	if vancouver_page(0x5e, 0x06, 0x6d, 0x73) then
		for x = 1, 5 do -- depth, score, first 3 moves
			if not led_on(x, 1) then
				sb_press_square(":board", 1, x, 1)
				emu.wait(0.5)
			end
		end
		-- OPTION opens the page used last, and the game options ("GAME") need to come first for Monitor Mode
		for _ = 1, 6 do
			send_input(":IN.0", 0x02, 1) -- option
			emu.wait(0.2)
			if vancouver_page(0x3d, 0x77, 0x37, 0x79) then -- GAME
				break
			end
		end
	end
	send_input(":IN.1", 0x01, 1) -- clear
	emu.wait(0.2)
end

local segment_digit = { [0x3f] = 0, [0x06] = 1, [0x5b] = 2, [0x4f] = 3, [0x66] = 4, [0x6d] = 5, [0x7d] = 6, [0x07] = 7,
	[0x7f] = 8, [0x67] = 9, [0x6f] = 9 }
local segment_file = { [0x77] = "a", [0x7c] = "b", [0x39] = "c", [0x5e] = "d", [0x79] = "e", [0x71] = "f", [0x3d] = "g",
	[0x76] = "h" }

-- vancouver: the Premiere's Vancouver program shows the depth with a dot ("05.17" = 5 plies, selective 17) and the
-- score without one ("-887", " 063")
function rotating.reader(vancouver)
	local score, depth, seldepth, pv
	local last_text, last_page, last_was_move, moves

	return function(on)
		if not on then
			score, depth, seldepth, pv = nil, nil, nil, nil
			last_text, last_page, last_was_move, moves = nil, nil, false, nil
			return nil
		end
		local v = {}
		for i, digit in ipairs({ 6, 5, 7, 8 }) do
			v[i] = display_value("digit" .. digit) & 0x7f
		end
		local dot = display_value("5.7") ~= 0
		local text = v[1] .. "," .. v[2] .. "," .. v[3] .. "," .. v[4] .. (dot and "." or "")
		if text == last_text and text ~= last_page then -- still there at the next read: the digits change one by one
			last_page = text
			local d = { segment_digit[v[1]], segment_digit[v[2]], segment_digit[v[3]], segment_digit[v[4]] }
			local is_score = dot or v[1] == 0x40
			if vancouver then
				is_score = not dot and (v[1] == 0 or v[1] == 0x40 or d[1] ~= nil)
			end
			local is_move = not is_score and not (vancouver and dot) and segment_file[v[1]] and d[2]
				and segment_file[v[3]] and d[4]
			if is_move then
				local move = segment_file[v[1]] .. d[2] .. segment_file[v[3]] .. d[4]
				moves = (last_was_move and moves) and (moves .. " " .. move) or move
				pv = moves
			elseif vancouver and dot then
				if d[1] and d[2] and d[3] and d[4] then
					depth, seldepth = d[1] * 10 + d[2], d[3] * 10 + d[4]
				end
			elseif is_score then
				if d[2] and d[3] and d[4] and (v[1] == 0 or v[1] == 0x40 or d[1]) then
					local value = (d[1] or 0) * 1000 + d[2] * 100 + d[3] * 10 + d[4]
					score = v[1] == 0x40 and -value or value
				end
			elseif vancouver then
				-- another page (none expected with rank 1 A1-E1 only)
			elseif v[3] == 0 and d[4] and d[4] > 0 then -- ply 0 shows before the first iteration
				depth = d[4]
			elseif d[3] and d[4] then
				depth = d[3] * 10 + d[4]
			end
			last_was_move = is_move and true or false
		end
		last_text = text
		return { score = score, depth = depth, seldepth = seldepth, pv = pv }
	end
end

return rotating
