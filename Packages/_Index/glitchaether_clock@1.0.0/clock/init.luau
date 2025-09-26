local Signal = require(script.Parent.signal)
local Trove = require(script.Parent.trove)

type Signal = {
    Fire: (...any) -> (),
    Connect: ((...any) -> ()) -> (() -> ()),
}
type Trove = {
    Add: <T>(T) -> T,
    Destroy: () -> (),
}

--[=[
    @within Clock
    @type ClockSignals
    All signals that a Clock instance provides.

    - `Started` fires when `startClock()` is called.
    - `Ended` fires when the clock reaches its destiny or is destroyed.
    - `Paused` fires when the clock is paused.
    - `Resumed` fires when the clock is resumed.
    - `onTick` fires each tick with the current tick count.
]=]
export type ClockSignals = {
    Started: Signal,
    Ended: Signal,
    Paused: Signal,
    Resumed: Signal,
    onTick: Signal,
}

--[=[
    @within Clock
    @type ClockState
    Serializable state of a Clock for saving/loading purposes.
]=]
export type ClockState = {
    tick: number,
    speed: number,
    paused: boolean,
}

--[=[
    @class Clock
    A tick-based timer utility for Roblox.

    A `Clock` is a tick counter that increments automatically at a set interval.
    You can pause, resume, reset, save/load state, and listen to signals on each tick.

    Example:

    ```lua
    local clock = Clock.new(1, 5) -- interval = 1 second, destiny = 5 ticks

    -- Listen to ticks:
    clock.onTick:Connect(function(tick)
        print("Tick:", tick)
    end)

    -- Listen to start and end:
    clock.Started:Connect(function() print("Clock started!") end)
    clock.Ended:Connect(function() print("Clock ended!") end)

    clock:startClock()
    ```

    Advanced usage:

    ```lua
    clock:SetSpeed(2) -- double speed
    clock:WaitForTick(3) -- yields until tick 3
    clock:PauseClock()
    clock:ResumeAt(2) -- resume at tick 2
    local state = clock:Save()
    clock:Load(state)
    clock:Reset()
    clock:Destroy()
    ```
]=]
export type Clock = {
    -- Properties
    interval: number,
    destiny: number,
    tick: number,
    speed: number,
    paused: boolean,
    ended: boolean,

    -- Signals
    Started: Signal,
    Ended: Signal,
    Paused: Signal,
    Resumed: Signal,
    onTick: Signal,

    -- Internal
    __trove: Trove?,
    __taskThread: thread?,
    __destroyed: boolean,

    -- Methods
    startClock: (self: Clock) -> (),
    pauseClock: (self: Clock) -> (),
    resumeClock: (self: Clock) -> (),
    Destroy: (self: Clock) -> (),
    Reset: (self: Clock, newTick: number?) -> (),
    SetSpeed: (self: Clock, speed: number) -> (),
    GetSpeed: (self: Clock) -> number,
    WaitForTick: (self: Clock, targetTick: number) -> (),
    IsInfinite: (self: Clock) -> boolean,
    ResumeAt: (self: Clock, newTick: number?) -> (),
    Save: (self: Clock) -> ClockState,
    Load: (self: Clock, state: ClockState) -> (),
}

local Clock = {}
Clock.__index = Clock

--[=[
    Starts the clock loop. Increments `tick` every `interval / speed` seconds.
    Fires signals: `Started`, `onTick`, and `Ended`.

    @within Clock
    @method startClock
    @example
    ```lua
    clock:startClock()
    ```
]=]
function Clock:startClock()
    if self.__destroyed then return end
    local clockTick = self.tick
    self.__taskThread = task.spawn(function()
        self.Started:Fire()
        while not self.paused and not self.ended do
            clockTick += 1
            task.wait(self.interval / self.speed)
            self.tick = clockTick
            self.onTick:Fire(clockTick)
            if self.destiny > 0 and clockTick >= self.destiny then
                self.ended = true
                self.Ended:Fire()
            end
        end
    end)
end

--[=[
    Pauses the clock and fires the `Paused` signal.

    @within Clock
    @method pauseClock
    @example
    ```lua
    clock:pauseClock()
    ```
]=]
function Clock:pauseClock()
    self.paused = true
    self.Paused:Fire()
end

--[=[
    Resumes the clock and fires the `Resumed` signal.

    @within Clock
    @method resumeClock
    @example
    ```lua
    clock:resumeClock()
    ```
]=]
function Clock:resumeClock()
    self.paused = false
    self.Resumed:Fire()
end

--[=[
    Resumes the clock optionally at a specific tick.

    @within Clock
    @method ResumeAt
    @param newTick number? Optional tick to resume at
    @example
    ```lua
    clock:ResumeAt(5) -- resumes at tick 5
    ```
]=]
function Clock:ResumeAt(newTick: number?)
    if newTick then
		self.tick = newTick
	end
    self:resumeClock()
end

--[=[
    Resets the clock to zero or a specified tick.
    @within Clock
    @method Reset
    @param newTick number? Tick to reset to, default = 0
    @example
    ```lua
    clock:Reset()
    clock:Reset(3) -- start from tick 3
    ```
]=]
function Clock:Reset(newTick: number?)
    self.tick = newTick or 0
    self.ended = false
    self.paused = false
end

--[=[
    Sets the speed of the clock. Must be > 0.
    @within Clock
    @method SetSpeed
    @param speed number Speed multiplier
    @example
    ```lua
    clock:SetSpeed(2) -- double speed
    ```
]=]
function Clock:SetSpeed(speed: number)
    assert(speed > 0, "Speed must be greater than 0")
    self.speed = speed
end

--[=[
    Returns the current speed of the clock.
    @within Clock
    @method GetSpeed
    @return number
    @example
    ```lua
    print(clock:GetSpeed())
    ```
]=]
function Clock:GetSpeed(): number
    return self.speed
end

--[=[
    Yields until the clock reaches a specific tick.
    @within Clock
    @method WaitForTick
    @param targetTick number
    @example
    ```lua
    clock:WaitForTick(5)
    ```
]=]
function Clock:WaitForTick(targetTick: number)
    assert(targetTick > 0, "Target tick must be positive")
    while self.tick < targetTick and not self.ended do
        task.wait(self.interval / self.speed)
    end
end

--[=[
    Returns true if the clock runs infinitely (destiny == 0)
    @within Clock
    @method IsInfinite
    @return boolean
    @example
    ```lua
    if clock:IsInfinite() then print("This clock never ends") end
    ```
]=]
function Clock:IsInfinite(): boolean
    return self.destiny == 0
end

--[=[
    Saves the current clock state for later restoration.
    @within Clock
    @method Save
    @return ClockState
    @example
    ```lua
    local state = clock:Save()
    ```
]=]
function Clock:Save(): ClockState
    return {
        tick = self.tick,
        paused = self.paused,
        speed = self.speed,
    }
end

--[=[
    Loads a previously saved clock state.
    @within Clock
    @method Load
    @param state ClockState
    @example
    ```lua
    clock:Load(state)
    ```
]=]
function Clock:Load(state: ClockState)
    self.tick = state.tick
    self.paused = state.paused
    self.speed = state.speed
end

--[=[
    Destroys the clock, stops all threads, and cleans up Trove.
    Fires `Ended` if not already ended.
    @within Clock
    @method Destroy
    @example
    ```lua
    clock:Destroy()
    ```
]=]
function Clock:Destroy()
    if self.__destroyed then return end
    self.__destroyed = true
    self.ended = true
    self.paused = true

    if self.__taskThread and coroutine.status(self.__taskThread) == "suspended" then
        task.cancel(self.__taskThread)
    end

    if self.__trove then
        self.__trove:Destroy()
        self.__trove = nil
    end

    setmetatable(self, nil)
end

--[=[
    Creates a new Clock instance.

    @within Clock
    @param interval number? Interval between ticks, default = 1
    @param destiny number? Total ticks before ending, 0 = infinite, default = 0
    @param startingTick number? Tick to start at, default = 0
    @return Clock
    @example
    ```lua
    local clock = Clock.new(1, 10)
    ```
]=]
function Clock.new(interval: number?, destiny: number?, startingTick: number?): Clock
    local trove = Trove.new()

    local self: Clock = setmetatable({
        interval = interval or 1,
        destiny = destiny or 0,
        tick = startingTick or 0,
        speed = 1,
        paused = false,
        ended = false,
        __trove = trove,
        __destroyed = false,

        Started = trove:Add(Signal.new()),
        Ended = trove:Add(Signal.new()),
        Paused = trove:Add(Signal.new()),
        Resumed = trove:Add(Signal.new()),
        onTick = trove:Add(Signal.new()),
    }, Clock)

    return self
end

return Clock