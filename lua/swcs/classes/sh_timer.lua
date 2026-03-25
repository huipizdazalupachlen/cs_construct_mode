AddCSLuaFile()

local META = {
	m_timestamp = -1,

	Now = function()
		return CurTime()
	end,

	Duration = function(self)
		return self.duration
	end,

	Reset = function(self)
		self.m_timestamp = self:Now()
	end,

	Start = function(self)
		self.m_timestamp = self:Now()
	end,

	StartFromTime = function(self, time)
		self.m_timestamp = time
	end,

	Invalidate = function(self)
		self.m_timestamp = -1
	end,

	-- Returns true if the timer has been started
	Started = function(self)
		return self.m_timestamp > 0
	end,

	-- Returns how long the timer has been running for
	GetElapsedTime = function(self)
		return self:Started() and (self:Now() - self.m_timestamp) or 99999.9
	end,

	IsLessThen = function(self, duration)
		return (self:Now() - self.m_timestamp < duration) and true or false
	end,

	IsGreaterThen = function(self, duration)
		return (self:Now() - self.m_timestamp > duration) and true or false
	end,

	GetStartTime = function(self)
		return self.m_timestamp
	end,
}
META.__index = META

-- Create a new timer object
function swcs.IntervalTimer()
	return setmetatable({}, META)
end

META = {
	m_duration = 0,
	m_timestamp = -1,

	Now = CurTime,

	Reset = function(self)
		self.m_timestamp = self:Now() + self.m_duration
	end,

	Start = function(self, duration)
		duration = duration or 0
		self.m_timestamp = self:Now() + duration
		self.m_duration = duration
	end,

	StartFromTime = function(self, startTime, duration)
		duration = duration or 0
		self.m_timestamp = startTime + duration
		self.m_duration = duration
	end,

	Invalidate = function(self)
		self.m_timestamp = -1.0
	end,

	HasStarted = function(self)
		return self.m_timestamp > 0.0
	end,

	IsElapsed = function(self)
		return self:Now() > self.m_timestamp
	end,

	GetElapsedTime = function(self)
		return self:Now() - self.m_timestamp + self.m_duration
	end,

	GetRemainingTime = function(self)
		return self.m_timestamp - self:Now()
	end,

	GetTargetTime = function(self)
		return self.m_timestamp
	end,

	-- return original countdown time
	GetCountdownDuration = function(self)
		return (self.m_timestamp > 0.0) and self.m_duration or 0.0
	end,

	-- 1.0 for newly started, 0.0 for elapsed
	GetRemainingRatio = function(self)
		if self:HasStarted() then
			local left = self:GetRemainingTime() / self.m_duration

			if left < 0.0 then
				return 0.0
			elseif left > 1.0 then
				return 1.0
			end

			return left
		end

		return 0.0
	end,

	GetElapsedRatio = function(self)
		if (self:HasStarted()) then
			local elapsed = self:GetElapsedTime() / self.m_duration

			if elapsed < 0.0 then
				return 0.0
			elseif elapsed > 1.0 then
				return 1.0
			end

			return elapsed
		end

		return 1.0
	end,

	-- Usage:
	--    Declaration: CountdownTimer mTimer
	--    Think function:
	--        while(mTimer.RunEvery( timerInterval ))
	--        {
	--            do fixed-rate stuff
	--        }
	--
	--        nextThinkTime = min(nextThinkTime, mTimer.GetTargetTime())
	--
	-- This avoids 'losing' ticks on a repeating timer when
	-- the think rate is not a multiple of the timer duration,
	-- especially since SetNextThink rounds ticks up/down, causing
	-- even a timer that is running exactly at the think rate of
	-- the underlying class to not elapse correctly.
	--
	-- It also makes sure that ticks are never lost
	RunEvery = function(self, amount)
		amount = amount or -1

		-- First call starts the timer
		if not self:HasStarted() then
			if amount > 0.0 then
				self:Start(amount)
			end

			return false
		end

		if self:IsElapsed() then
			if amount > 0.0 then
				self.m_duration = amount
			end

			self.m_timestamp = self.m_timestamp + self.m_duration
			return true
		end

		return false
	end,

	-- Same as RunEvery() but only returns true once per 'tick', then guarantees being non-elapsed.
	-- Useful when "do fixed rate stuff" is idempotent, like updating something to match
	-- the current time.
	Interval = function(self, amount)
		amount = amount or -1

		-- First call starts the timer
		if not self:HasStarted() then
			if amount > 0.0 then
				self:Start(amount)
			end

			return false
		end

		if self:IsElapsed() then
			if amount > 0.0 then
				self.m_duration = amount
			end

			self.m_timestamp = self.m_timestamp + self.m_duration

			-- If we are still expired, add a multiple of the interval
			-- until we become non-elapsed
			local remaining = self:GetRemainingTime()
			if remaining < 0.0 then
				local numIntervalsRequired = -math.floor(remaining / self.m_duration)
				self.m_timestamp = self.m_timestamp + (self.m_duration * numIntervalsRequired)
			end

			-- We should no longer be elapsed
			--Assert( !IsElapsed() )

			return true
		end

		return false
	end,
}
META.__index = META
function swcs.CountdownTimer()
	return setmetatable({}, META)
end
