
KeyStrokeManager = {}
KeyStrokeManager.__listeners = {}

local function tableEquals(t1, t2)
	local equals = true
	for _, v1 in pairs(t1) do
		local subEquals = false
		for _, v2 in pairs(t2) do
			if v1 == v2 then
				subEquals = true
				break
			end
		end
		if subEquals == false then
			equals = false
			break
		end
	end
	return equals
end

local function inTable(t, v)
	for i,k in pairs(t) do
		if k == v then
			return true
		end
	end
	return false
end

function KeyStrokeManager.__CheckKeyStroke(key, pressOrRelease)
	pressOrRelease = pressOrRelease == "down" and true or false
	for i, listener in ipairs(KeyStrokeManager.__listeners) do
		local allPressed = true
		for _, key in ipairs(listener.keys) do
			if getKeyState(key) == false then
				allPressed = false
				break
			end
		end

		if pressOrRelease == true then
			if allPressed and (listener.state == "down" or listener.state == "both") then
				listener.__triggered = true
				listener.fn("down", unpack(listener.args))
			end
		else
			if not allPressed and listener.__triggered and (listener.state == "up" or listener.state == "both") then
				listener.__triggered = false
				listener.fn("up", unpack(listener.args))
			end
		end
	end
end




-----------------------------------------------------------------------------------
--
-- string	triggerState		"down" | "up" | "both"
-- function callbackFunction
-- table 	tableOfKeys
-- mixed	extra parameters passed to callbackFunction
--
-- When key sequence is triggered, callbackFunction will be called with:
-- string 	triggerState		"down" | "up"
-- mixed	extra parameters passed to callbackFunction
-----------------------------------------------------------------------------------
function KeyStrokeManager.RegisterKeyStrokeListener(triggerState, callbackFunction, tableOfKeys, ...)
	table.insert(KeyStrokeManager.__listeners, { fn = callbackFunction, keys = tableOfKeys, args = { ... }, state = triggerState, __triggered = false })
	for i,key in ipairs(tableOfKeys) do
		bindKey(key, "both", KeyStrokeManager.__CheckKeyStroke)
	end
end

function KeyStrokeManager.RemoveKeystrokeListener(triggerState, callbackFunction, tableOfKeys)
	for i, listener in ipairs(KeyStrokeManager.__listeners) do
		if tableEquals(listener.keys, tableOfKeys) and callbackFunction == listener.fn and triggerState == listener.state then
			table.remove(KeyStrokeManager.__listeners, i)
			break
		end
	end
	for _, key in ipairs(tableOfKeys) do
		local containsKey = false
		for i, listener in ipairs(KeyStrokeManager.__listeners) do
			if inTable(listener.keys, key) then
				containsKey = true
				break
			end
		end
		if not containsKey then
			unbindKey(key, "both", KeyStrokeManager.__CheckKeyStroke)
		end
	end
end
