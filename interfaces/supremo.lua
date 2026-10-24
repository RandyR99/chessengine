interface = load_interface("nsnova")

local function ram_block(tag, offset, len)
	local share = machine.memory.shares[tag]
	local s = ""
	for i = 0, len - 1 do
		s = s .. string.char(share:read_u8(offset + i))
	end
	return s
end

function interface.get_module()
	return "Novag Supremo"
end

function interface.get_author()
	return "David Kittinger"
end

function interface.show_info(on)
	if on then
		local ddram = ram_block(":maincpu:internal_ram", 0x80, 0x05)
		if (digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2))) == "d " then
			interface.depth = digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))
		elseif digit_ascii(ddram:byte(1)) == " " or digit_ascii(ddram:byte(1)) == "-" then
			interface.score = (digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2)) .. digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))):gsub(" ","")
		elseif digit_ascii(ddram:byte(1)) == "a" or digit_ascii(ddram:byte(1)) == "b" or digit_ascii(ddram:byte(1)) == "c" or digit_ascii(ddram:byte(1)) == "d" or digit_ascii(ddram:byte(1)) == "e" or digit_ascii(ddram:byte(1)) == "f" or digit_ascii(ddram:byte(1)) == "g" or digit_ascii(ddram:byte(1)) == "h" then
			interface.pv = digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2)) .. digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))
		end
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end

function digit_ascii(digit)
	if     digit == nil                     then return (" ")
	elseif digit == 215 or digit == 215 + 8 then return ("0")
	elseif digit == 6 or digit == 6 + 8     then return ("1")
	elseif digit == 227 or digit == 227 + 8 then return ("2")
	elseif digit == 167 or digit == 167 + 8 then return ("3")
	elseif digit == 54 or digit == 54 + 8   then return ("4")
	elseif digit == 181 or digit == 181 + 8 then return ("5")
	elseif digit == 253 - 8 or digit == 253 then return ("6")
	elseif digit == 15 - 8 or digit == 15   then return ("7")
	elseif digit == 255 - 8 or digit == 255 then return ("8")
	elseif digit == 183 or digit == 183 + 8 then return ("9")
	elseif digit == 32 or digit == 40       then return ("-")
	elseif digit == 227 - 8 or digit == 227 then return ("a")
	elseif digit == 127 - 8 or digit == 127 then return ("A")
	elseif digit == 100 or digit == 100 + 8 then return ("n")
	elseif digit == 161 or digit == 161 + 8 then return ("on")
	elseif digit == 182 or digit == 182 + 8 then return ("Y")
	elseif digit == 252 - 8 or digit == 252 then return ("b")
	elseif digit == 217 - 8 or digit == 217 then return ("c")
	elseif digit == 238 - 8 or digit == 238 then return ("d")
	elseif digit == 249 - 8 or digit == 249 then return ("e")
	elseif digit == 121 - 8 or digit == 121 then return ("f")
	elseif digit == 221 - 8 or digit == 221 then return ("g")
	elseif digit == 124 - 8 or digit == 124 then return ("h")
	elseif digit == 0 or digit == 8         then return (" ")
	elseif digit == 104 - 8 or digit == 104 then return ("r")
	else
		return (" hex" .. (digit) .. "?")
	end
end

return interface
