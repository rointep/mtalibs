
ID = {}
ID.instances = {}

function ID.CreateFactory()
	local o = {
		_id_ = 0
	}

	setmetatable(o, { __index = ID })

	table.insert(ID.instances, o)

	return o
end

function ID:Obtain()
	local id = self._id_
	self._id_ = id + 1
	return id
end

function ID:Reset()
	self._id_ = 0
end
