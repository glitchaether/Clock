# Clock

A tick-based timer utility for Roblox written in Luau.
Clock is a flexible, tick-based timer that supports pause/resume, adjustable speed, state saving/loading, and signals for events.

---

## Installation

### Wally

Add to your `wally.toml`:

```toml
[dependencies]
Clock = "glitchaether/clock@1.0.1"
```

Then run:

```bash
wally install
```

### Manual

Copy `Clock.luau` into your game and `require` it directly:

```lua
local Clock = require(path_to_clock)
```

---

## Quick Start

```lua
local Clock = require(Packages.Clock)

-- Create a clock with 1-second interval, ending after 5 ticks
local clock = Clock.new(1, 5)

-- Listen to start
clock.Started:Connect(function()
    print("Clock started!")
end)

-- Listen to each tick
clock.onTick:Connect(function(tick)
    print("Tick:", tick)
end)

-- Listen to end
clock.Ended:Connect(function()
    print("Clock ended!")
end)

clock:startClock()
```

---

## API Reference

### Constructor

```lua
Clock.new(interval: number?, destiny: number?, startingTick: number?): Clock
```

* **interval** → seconds between ticks (default = `1`)
* **destiny** → total ticks before ending, `0` = infinite (default = `0`)
* **startingTick** → tick to start at (default = `0`)

---

### Properties

* `interval: number` — interval between ticks
* `destiny: number` — total ticks before ending (`0` = infinite)
* `tick: number` — current tick count
* `speed: number` — multiplier for tick speed
* `paused: boolean` — whether the clock is paused
* `ended: boolean` — whether the clock has ended

---

### Signals

* `Started` — fires when `startClock()` is called
* `Ended` — fires when the clock ends or is destroyed
* `Paused` — fires when the clock is paused
* `Resumed` — fires when the clock is resumed
* `onTick(tick: number)` — fires every tick with the tick count

---

### Methods

#### `startClock()`

Starts ticking. Fires `Started`, then `onTick` every tick until `Ended`.

#### `pauseClock()`

Pauses the clock and fires `Paused`.

#### `resumeClock()`

Resumes the clock and fires `Resumed`.

#### `ResumeAt(newTick: number?)`

Resumes ticking optionally at a specific tick.

#### `Reset(newTick: number?)`

Resets the clock to zero or the specified tick.

#### `SetSpeed(speed: number)`

Sets the tick speed multiplier. Must be greater than 0.

#### `GetSpeed()`

Returns the current speed multiplier.

#### `WaitForTick(targetTick: number)`

Yields until the clock reaches the specified tick.

#### `IsInfinite()`

Returns true if the clock runs infinitely (`destiny == 0`).

#### `Save()`

Returns a `ClockState` object containing the current tick, speed, and paused status.

#### `Load(state: ClockState)`

Restores the clock state from a `ClockState` object.

#### `Destroy()`

Stops the clock, cleans up signals and trove, and fires `Ended` if not already ended.

---

## Saving & Loading State

```lua
local state = clock:Save()
clock:Destroy()

local newClock = Clock.new()
newClock:Load(state)
```

---

## Examples

```lua
-- Infinite clock
local infiniteClock = Clock.new(1, 0)
infiniteClock:startClock()

-- Double speed
clock:SetSpeed(2)

-- Wait for tick 5
clock:WaitForTick(5)

-- Resume at tick 2
clock:ResumeAt(2)
```

---

## Dependencies

* [Signal and Trove](https://github.com/Sleitnick/RbxUtil) — event handling and automatic cleanup of objects and signals
* [Wally](https://wally.run/) — Roblox package manager

---

## License

MIT License. Free to use, modify, and distribute.
