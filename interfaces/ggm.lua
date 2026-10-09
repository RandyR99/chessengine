local module = machine.images[':cartslot'].filename
if (module == "boris25") then
	return load_interface("ggm_boris25")
elseif (module == "morphy") then
	return load_interface("ggm_morphy")
elseif (module == "sandy") then
	return load_interface("ggm_sandy")
elseif (module == "steinitz") then
	return load_interface("ggm_steinitz")
end

return nil
