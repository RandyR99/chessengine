local module = machine.images[':cartslot'].filename
if (module == "sargon25") then
	return load_interface("arb_sargon25")
elseif (module == "sargon35") then
	return load_interface("arb_sargon35")
elseif (module == "gms3") then
	return load_interface("arb_gms3")
elseif (module == "gms4") then
	return load_interface("arb_gms4")
end

return nil
