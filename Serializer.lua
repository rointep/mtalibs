
Serializer = {}


function Serializer.Load(file, encoded)
	local contents = {}
	local f
	if fileExists(file) then
		f = fileOpen(file, true)
	else
		f = fileCreate(file)
	end
	if f then
		while not fileIsEOF(f) do
			table.insert(contents, fileRead(f, 1024))
		end
		fileClose(f)

		contents = table.concat(contents, "")
		if encoded then
			contents = base64Decode(contents)
		end

		if not contents then
			return false
		end
	else
		return false
	end

	return fromJSON(contents)
end


function Serializer.Store(file, data, encode)
	local f
	if fileExists(file) then
		fileDelete(file)
	end
	f = fileCreate(file)
	if f then
		local contents = toJSON(data)
		if contents then
			if encode then
				contents = base64Encode(contents)
			end
			fileWrite(f, contents)
			fileClose(f)
			return true
		else
			fileClose(f)
		end
	end

	return false
end

