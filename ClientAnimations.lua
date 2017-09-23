Anim = {}
Anim.instances = {}

local ANIM_ID = 0


function Anim:__Initialize()
	removeEventHandler("onClientRender", root, __handleAnimations)
	addEventHandler("onClientRender", root, __handleAnimations)
end

function Anim:__Unload()
	removeEventHandler("onClientRender", root, __handleAnimations)
end

function Anim:Create(from, to, duration, easing, fn, args)
	local animation = {
		_id = ANIM_ID,

		from = from,
		to = to,
		duration = duration,
		easing = easing,

		startTime = nil, -- is set in Anim:Run()

		chain = nil,

		fn = fn,
		args = args or {},

		running = false,
	}

	setmetatable(animation, { __index = Anim })

	table.insert(Anim.instances, animation)

	ANIM_ID = ANIM_ID + 1

	return animation
end

function Anim:Run()
	if self then
		if self.running == false then
			self.startTime = getTickCount() -- start time must be set here
			self.running = true
		end
	end
end


function Anim:CreateAndRun(from, to, duration, easing, fn, args)
	local animation = {
		_id = ANIM_ID,

		from = from,
		to = to,
		duration = duration,
		easing = easing,

		startTime = getTickCount(),

		chain = nil,

		fn = fn,
		args = args or {},

		running = false,
	}

	setmetatable(animation, { __index = Anim })

	table.insert(Anim.instances, animation)
	animation.running = true

	ANIM_ID = ANIM_ID + 1

	return animation
end


function Anim:Chain(triggerProgress, ...)
	if self then
		for pointer, animation in pairs(Anim.instances) do
			if animation == self then

				local function getNextChainLink(thisAnimationInstance)
					if thisAnimationInstance.chain then
						return getNextChainLink(thisAnimationInstance.chain.instance)
					end

					return thisAnimationInstance
				end

				getNextChainLink(Anim.instances[pointer]).chain = { trigger = triggerProgress, instance = Anim:Create( ... ), parent = self }
			end
		end
	end
end


function Anim:Stop()
	if self then
		for pointer, animation in pairs(Anim.instances) do
			if animation == self and animation.running then
				animation.running = false
				table.remove(Anim.instances, pointer)
			end

			if animation.chain and animation.chain.parent._id == self._id then
				animation.running = false
				table.remove(Anim.instances, pointer)
			end
		end
	end
end


function __handleAnimations()
	local now = getTickCount()

	local scheduledForRemoval = {}

	for i, animation in pairs(Anim.instances) do

		if animation.running then
			local releaseAnimation = false
			local elapsedTime = now - animation.startTime
			local duration = animation.startTime + animation.duration - animation.startTime
			local progress = elapsedTime / duration

			local fAnimationTime = getEasingValue(progress, animation.easing)

			if elapsedTime >= duration then
				fAnimationTime = 1
				releaseAnimation = true
			end


			if animation.chain and animation.chain.instance then
				if progress >= animation.chain.trigger then
					animation.chain.instance:Run()
					animation.chain.instance = nil
				end
			end

			local value = animation.from + (animation.to - animation.from) * fAnimationTime

			if type(animation.fn) == "string" then
				loadstring("return "..animation.fn)(value, unpack(animation.args))
			else
				animation.fn(value, unpack(animation.args))
			end

			if releaseAnimation then
				table.insert(scheduledForRemoval, i)
			end
		end
	end

	if #scheduledForRemoval >= 1 then
		for i=#scheduledForRemoval, 1, -1 do
			local indexToRemove = scheduledForRemoval[i]
			table.remove(Anim.instances, indexToRemove)
		end
	end
end
