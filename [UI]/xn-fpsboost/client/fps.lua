

Oxlyn = Oxlyn or {}

----------------------------------------------------------------------
-- Constants / config
----------------------------------------------------------------------
local BUCKET_MS         = 0.25                                  -- histogram bucket width (ms)
local MAX_FRAMETIME_MS  = 250.0
local BUCKET_COUNT      = math.floor(MAX_FRAMETIME_MS / BUCKET_MS) + 1

local monitorCfg        = Config.Monitor
local STATS_WINDOW_SEC  = monitorCfg.statsWindow or 60
local STATS_WINDOW_MS   = STATS_WINDOW_SEC * 1000
local MAX_WINDOW_SAMPLES = 20000                                -- cap for rolling stats window

local SAMPLE_RATE       = math.max(1, monitorCfg.sampleRate or 10)           -- history samples / sec
local HISTORY_CAPACITY  = math.max(60, (monitorCfg.historyMinutes or 60) * 60 * SAMPLE_RATE)

local DEFAULT_POINTS    = 180                                   -- default chart resolution
local SMOOTH_ALPHA      = 0.12
local CHUNK_SIZE        = 32                                    -- chunk size for downsample cache

local RANGE_SECONDS = { ["1m"] = 60, ["5m"] = 300, ["15m"] = 900, ["1h"] = 3600 }

----------------------------------------------------------------------
-- Public state
----------------------------------------------------------------------
local FPS = {
    current         = 0,
    smooth          = 0,
    frametime       = 16.7,
    avgFrametime    = 16.7,
    bestFrametime   = 1000.0,
    frametimeStdDev = 0,
    average         = 0,
    low1            = 0,
    low01           = 0,
    min             = 0,
    max             = 0,
    prevMinuteAvg   = 0,
    deltaPct        = 0,
    sessionMin      = 9999,
    sessionMax      = 0,
    sessionSum      = 0,
    sessionN        = 0,
}
Oxlyn.FPS = FPS

----------------------------------------------------------------------
-- Rolling stats window (ring buffer + frametime histogram)
----------------------------------------------------------------------
local winFrametimes = {}   -- frametime (ms) per sample
local winBuckets    = {}   -- histogram bucket per sample
local winTimestamps = {}   -- timestamp (ms) per sample
local winHead       = 0    -- index of newest sample
local winTail       = 1    -- index of oldest sample
local winCount      = 0

local histogram = {}
for i = 1, BUCKET_COUNT do histogram[i] = 0 end
local histTotal     = 0
local winSum        = 0    -- sum of frametimes
local winSumSq      = 0    -- sum of squared frametimes
local minBucket     = BUCKET_COUNT   -- lowest occupied bucket (bounds are trimmed on recompute)
local maxBucket     = 1              -- highest occupied bucket

-- min/max FPS seen between two history samples
local intervalFpsLo, intervalFpsHi = nil, nil

local function bucketIndex(frametimeMs)
    if frametimeMs < 0 then frametimeMs = 0 end
    local idx = math.floor(frametimeMs / BUCKET_MS) + 1
    if idx > BUCKET_COUNT then idx = BUCKET_COUNT end
    return idx
end

-- Average FPS of the slowest `fraction` of frames (e.g. 0.01 -> "1% low")
local function lowPercentileFps(fraction)
    if histTotal < 20 then return 0 end

    local target   = math.max(1, math.floor(histTotal * fraction + 0.5))
    local taken    = 0
    local weighted = 0.0

    for b = maxBucket, minBucket, -1 do
        local count = histogram[b]
        if count > 0 then
            local take = math.min(count, target - taken)
            weighted = weighted + take * ((b - 0.5) * BUCKET_MS)
            taken    = taken + take
            if taken >= target then break end
        end
    end

    if taken == 0 or weighted <= 0 then return 0 end
    local avgMs = weighted / taken
    if avgMs <= 0 then return 0 end
    return math.floor(1000.0 / avgMs + 0.5)
end

-- FPS at the given percentile of the frametime distribution (0.5 = median)
local function percentileFps(fraction)
    if histTotal < 5 then return 0 end

    local target     = math.max(1, math.floor(histTotal * fraction + 0.5))
    local cumulative = 0

    for b = minBucket, maxBucket do
        cumulative = cumulative + histogram[b]
        if cumulative >= target then
            local ms = (b - 0.5) * BUCKET_MS
            return math.floor(1000.0 / ms + 0.5)
        end
    end
    return 0
end

local function popOldestSample()
    if winCount == 0 then return end

    local ft     = winFrametimes[winTail]
    local bucket = winBuckets[winTail]

    histogram[bucket] = histogram[bucket] - 1
    histTotal = histTotal - 1
    winSum    = winSum - ft
    winSumSq  = winSumSq - ft * ft

    winTail = winTail + 1
    if winTail > MAX_WINDOW_SAMPLES then winTail = 1 end
    winCount = winCount - 1
end

local function pushSample(frametimeMs, now)
    -- drop samples older than the stats window
    while winCount > 0 and (now - winTimestamps[winTail]) > STATS_WINDOW_MS do
        popOldestSample()
    end
    if winCount >= MAX_WINDOW_SAMPLES then
        popOldestSample()
    end

    winHead = winHead + 1
    if winHead > MAX_WINDOW_SAMPLES then winHead = 1 end

    winFrametimes[winHead] = frametimeMs
    winTimestamps[winHead] = now
    winCount = winCount + 1

    local bucket = bucketIndex(frametimeMs)
    winBuckets[winHead] = bucket
    histogram[bucket] = histogram[bucket] + 1
    histTotal = histTotal + 1

    if bucket < minBucket then minBucket = bucket end
    if bucket > maxBucket then maxBucket = bucket end

    winSum   = winSum + frametimeMs
    winSumSq = winSumSq + frametimeMs * frametimeMs
end

local function recomputeStats()
    if winCount < 5 then return end

    local avgFt = winSum / winCount
    FPS.avgFrametime = avgFt
    FPS.average = (avgFt > 0) and math.floor(1000.0 / avgFt + 0.5) or 0

    local variance = winSumSq / winCount - avgFt * avgFt
    if variance < 0 then variance = 0 end
    FPS.frametimeStdDev = math.sqrt(variance)

    FPS.low1  = lowPercentileFps(0.01)
    FPS.low01 = lowPercentileFps(0.001)

    -- find the real occupied bounds and tighten them
    local lowest, highest
    for b = minBucket, maxBucket do
        if histogram[b] > 0 then lowest = b break end
    end
    for b = maxBucket, minBucket, -1 do
        if histogram[b] > 0 then highest = b break end
    end

    if lowest then
        minBucket = lowest
        FPS.max = math.floor(1000.0 / ((lowest - 0.5) * BUCKET_MS) + 0.5)
    end
    if highest then
        maxBucket = highest
        FPS.min = math.floor(1000.0 / ((highest - 0.5) * BUCKET_MS) + 0.5)
    end
end

----------------------------------------------------------------------
-- History ring buffers (one value per sample at SAMPLE_RATE)
----------------------------------------------------------------------
local histFps, histFrametime, histPing, histEntities = {}, {}, {}, {}
local histFpsLo, histFpsHi = {}, {}
local histStart = 1        -- index of oldest entry
local histCount = 0

-- Chunk cache for fast downsampling; each series array has its own cache.
local chunkVersions = {}   -- chunk number -> version (bumped on every write)
local chunkCache = {
    [histFps]       = {},
    [histFrametime] = {},
    [histPing]      = {},
    [histEntities]  = {},
}

local function pushHistory(fps, frametime, ping, entities)
    local lo = intervalFpsLo or fps
    local hi = intervalFpsHi or fps
    intervalFpsLo, intervalFpsHi = nil, nil

    -- bump the version of the chunk being written
    local writeIdx = (histStart + histCount - 1) % HISTORY_CAPACITY + 1
    local chunk = math.floor((writeIdx - 1) / CHUNK_SIZE) + 1
    chunkVersions[chunk] = (chunkVersions[chunk] or 0) + 1

    histFps[writeIdx]       = fps
    histFrametime[writeIdx] = frametime
    histPing[writeIdx]      = ping
    histEntities[writeIdx]  = entities
    histFpsLo[writeIdx]     = lo
    histFpsHi[writeIdx]     = hi

    if histCount >= HISTORY_CAPACITY then
        -- buffer full: overwrote the oldest entry, advance start
        histStart = histStart + 1
        if histStart > HISTORY_CAPACITY then histStart = 1 end
    else
        histCount = histCount + 1
    end
end

-- Last `n` values of a series as a plain array
local function getRecent(seriesName, n)
    if histCount == 0 then return {} end
    if n > histCount then n = histCount end

    local source = histFps
    if     seriesName == "frametime" then source = histFrametime
    elseif seriesName == "ping"      then source = histPing
    elseif seriesName == "entities"  then source = histEntities
    elseif seriesName == "fpsLo"     then source = histFpsLo
    elseif seriesName == "fpsHi"     then source = histFpsHi
    end

    local out = {}
    local offset = histCount - n
    for i = 1, n do
        local idx = histStart + offset + i - 1
        while idx > HISTORY_CAPACITY do idx = idx - HISTORY_CAPACITY end
        out[i] = source[idx] or 0
    end
    return out
end

-- Downsample the newest `count` entries of `values` into `points` buckets.
-- loValues/hiValues (optional) hold per-sample min/max; `invert` converts FPS -> ms.
local function downsample(values, loValues, hiValues, count, points, invert)
    if count <= 0 or histCount == 0 then
        return { avg = {}, min = {}, max = {} }
    end
    if count > histCount then count = histCount end
    points = points or DEFAULT_POINTS

    local offset = histCount - count
    local avgOut, minOut, maxOut = {}, {}, {}

    local function ringIndex(i)
        return (histStart + offset + i - 2) % HISTORY_CAPACITY + 1
    end

    -- returns (min, max) for one sample
    local function sampleBounds(idx, value)
        if not loValues then return value, value end
        local lo, hi = loValues[idx], hiValues[idx]
        if not lo or not hi then return value, value end
        if invert then
            local minMs = (hi > 0) and (1000.0 / hi) or value
            local maxMs = (lo > 0) and (1000.0 / lo) or value
            return minMs, maxMs
        end
        return lo, hi
    end

    -- Few enough samples: no aggregation needed
    if count <= points then
        for i = 1, count do
            local idx = ringIndex(i)
            local v = values[idx] or 0
            local mn, mx = sampleBounds(idx, v)
            avgOut[i], minOut[i], maxOut[i] = v, mn, mx
        end
        return { avg = avgOut, min = minOut, max = maxOut }
    end

    local cache = chunkCache[values]
    local step  = count / points

    for p = 1, points do
        local first = math.floor((p - 1) * step) + 1
        local last  = math.floor(p * step)
        if first > last then last = first end
        if last > count then last = count end

        local sum, lo, hi, n = 0, math.huge, -math.huge, 0
        local i   = first
        local idx = ringIndex(i)

        while i <= last do
            local usedChunk = false

            if (idx - 1) % CHUNK_SIZE == 0
                and last >= i + CHUNK_SIZE - 1
                and idx + CHUNK_SIZE - 1 <= HISTORY_CAPACITY then

                local chunkNo = math.floor((idx - 1) / CHUNK_SIZE) + 1
                local entry = cache[chunkNo]

                if not entry or entry.version ~= chunkVersions[chunkNo] then
                    local cSum, cLo, cHi = 0, math.huge, -math.huge
                    for j = idx, idx + CHUNK_SIZE - 1 do
                        local v = values[j] or 0
                        local mn, mx = sampleBounds(j, v)
                        cSum = cSum + v
                        if mn < cLo then cLo = mn end
                        if mx > cHi then cHi = mx end
                    end
                    entry = entry or {}
                    entry.sum, entry.lo, entry.hi = cSum, cLo, cHi
                    entry.version = chunkVersions[chunkNo]
                    cache[chunkNo] = entry
                end

                sum = sum + entry.sum
                if entry.lo < lo then lo = entry.lo end
                if entry.hi > hi then hi = entry.hi end
                n   = n + CHUNK_SIZE
                i   = i + CHUNK_SIZE
                idx = idx + CHUNK_SIZE
                usedChunk = true
            end

            if not usedChunk then
                local v = values[idx] or 0
                local mn, mx = sampleBounds(idx, v)
                sum = sum + v
                if mn < lo then lo = mn end
                if mx > hi then hi = mx end
                n   = n + 1
                i   = i + 1
                idx = idx + 1
            end

            if idx > HISTORY_CAPACITY then idx = 1 end
        end

        if n == 0 then n, lo, hi = 1, 0, 0 end

        avgOut[p] = math.floor(sum / n * 10 + 0.5) / 10
        minOut[p] = (lo == math.huge)  and 0 or math.floor(lo * 10 + 0.5) / 10
        maxOut[p] = (hi == -math.huge) and 0 or math.floor(hi * 10 + 0.5) / 10
    end

    return { avg = avgOut, min = minOut, max = maxOut }
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function Oxlyn.GetChartSeries(series, range)
    local seconds = RANGE_SECONDS[range] or 60
    local wanted  = seconds * SAMPLE_RATE
    series = series or "fps"

    local data
    if series == "fps" then
        data = downsample(histFps, histFpsLo, histFpsHi, wanted, nil, false)
    elseif series == "frametime" then
        data = downsample(histFrametime, histFpsLo, histFpsHi, wanted, nil, true)
    elseif series == "ping" then
        data = downsample(histPing, nil, nil, wanted, nil, false)
    else
        data = downsample(histEntities, nil, nil, wanted, nil, false)
    end

    local available = (wanted > histCount) and histCount or wanted

    return {
        series  = series,
        range   = range or "1m",
        seconds = seconds,
        filled  = available / wanted,
        avg     = data.avg,
        min     = data.min,
        max     = data.max,
    }
end

function Oxlyn.ExportCsv(range)
    local seconds = RANGE_SECONDS[range] or 60
    local wanted  = seconds * SAMPLE_RATE

    local fps       = getRecent("fps", wanted)
    local frametime = getRecent("frametime", wanted)
    local ping      = getRecent("ping", wanted)
    local entities  = getRecent("entities", wanted)

    local lines = { "seconds_ago,fps,frametime_ms,ping_ms,entities" }
    local n = #fps
    for i = 1, n do
        lines[#lines + 1] = ("%.1f,%.1f,%.2f,%d,%d"):format(
            (n - i) / SAMPLE_RATE,
            fps[i]       or 0,
            frametime[i] or 0,
            ping[i]      or 0,
            entities[i]  or 0
        )
    end
    return table.concat(lines, "\n")
end

function Oxlyn.FpsSnapshot()
    local stability = 0
    if FPS.avgFrametime > 0 then
        local ratio = math.min(1.0, FPS.frametimeStdDev / FPS.avgFrametime)
        stability = math.floor((1.0 - ratio) * 100 + 0.5)
    end

    return {
        current    = math.floor(FPS.smooth + 0.5),
        raw        = FPS.current,
        frametime  = math.floor(FPS.frametime * 100 + 0.5) / 100,
        average    = FPS.average,
        low1       = FPS.low1,
        low01      = FPS.low01,
        min        = FPS.min,
        max        = FPS.max,
        median     = percentileFps(0.5),
        deltaPct   = FPS.deltaPct,
        stability  = stability,
        sessionMin = (FPS.sessionMin == 9999) and 0 or FPS.sessionMin,
        sessionMax = FPS.sessionMax,
        sessionAvg = (FPS.sessionN > 0) and math.floor(FPS.sessionSum / FPS.sessionN + 0.5) or 0,
    }
end

function Oxlyn.RecentAverage(seconds)
    if histCount == 0 then return FPS.average end

    local n = math.floor((seconds or 10) * SAMPLE_RATE)
    if n > histCount then n = histCount end
    if n <= 0 then return FPS.average end

    local offset = histCount - n
    local sum = 0
    for i = 1, n do
        local idx = (histStart + offset + i - 2) % HISTORY_CAPACITY + 1
        sum = sum + (histFps[idx] or 0)
    end
    return sum / n
end

function Oxlyn.ResetWindow()
    for i = 1, BUCKET_COUNT do histogram[i] = 0 end
    histTotal = 0
    minBucket = BUCKET_COUNT
    maxBucket = 1

    winFrametimes = {}
    winTimestamps = {}
    winBuckets    = {}
    winHead, winTail, winCount = 0, 1, 0
    winSum, winSumSq = 0, 0

    intervalFpsLo, intervalFpsHi = nil, nil

    FPS.average = 0
    FPS.low1    = 0
    FPS.low01   = 0
end

----------------------------------------------------------------------
-- Threads
----------------------------------------------------------------------

-- Frame sampler: runs every frame
CreateThread(function()
    Wait(3000)

    local getFrameTime = GetFrameTime
    local floor        = math.floor
    local boostFrame   = Oxlyn.BoostFrame or function() end
    local metrics      = Oxlyn.Metrics.real

    local sampleAccum    = 0.0
    local sampleInterval = 1.0 / SAMPLE_RATE
    local clockMs        = 0.0      -- accumulated frame time, used as our own clock
    local WARMUP_MS      = 5000.0

    while true do
        local dt = getFrameTime()

        if dt > 0.0 then
            local ms = dt * 1000.0

            -- ignore impossible frametimes (<0.9ms or >=2s, e.g. loading screens / hitches)
            if ms >= 0.9 and ms < 2000.0 then
                clockMs = clockMs + ms

                FPS.frametime = ms
                local fps = floor(1000.0 / ms + 0.5)
                FPS.current = fps

                -- exponential smoothing
                if FPS.smooth == 0 then
                    FPS.smooth = fps
                else
                    local alpha = dt / (dt + SMOOTH_ALPHA)
                    FPS.smooth = FPS.smooth + (fps - FPS.smooth) * alpha
                end

                pushSample(ms, clockMs)

                -- track min/max FPS between history samples
                if not intervalFpsLo or fps < intervalFpsLo then intervalFpsLo = fps end
                if not intervalFpsHi or fps > intervalFpsHi then intervalFpsHi = fps end

                -- best frametime after warm-up
                if clockMs > WARMUP_MS and ms < FPS.bestFrametime and ms > 0.5 then
                    FPS.bestFrametime = ms
                end

                -- periodic history sample
                sampleAccum = sampleAccum + dt
                if sampleAccum >= sampleInterval then
                    sampleAccum = 0.0

                    pushHistory(
                        floor(FPS.smooth + 0.5),
                        floor(ms * 100 + 0.5) / 100,
                        metrics.ping or 0,
                        metrics.totalEntities or 0
                    )

                    if fps < FPS.sessionMin then FPS.sessionMin = fps end
                    if fps > FPS.sessionMax then FPS.sessionMax = fps end
                    FPS.sessionSum = FPS.sessionSum + fps
                    FPS.sessionN   = FPS.sessionN + 1
                end
            end
        end

        boostFrame()
        Wait(0)
    end
end)

-- Stats updater: recomputes aggregate stats, adaptive tick rate
CreateThread(function()
    Wait(4000)

    local minuteAvg  = 0
    local nextMinute = GetGameTimer() + 60000

    while true do
        recomputeStats()

        local now = GetGameTimer()
        if nextMinute <= now then
            nextMinute = now + 60000
            minuteAvg  = FPS.average
        end

        FPS.prevMinuteAvg = minuteAvg
        if minuteAvg > 0 then
            FPS.deltaPct = math.floor((FPS.average - minuteAvg) / minuteAvg * 100 + 0.5)
        else
            FPS.deltaPct = 0
        end

        if Oxlyn.State.open then
            Wait(500)
        elseif Oxlyn.Get("hudEnabled") then
            Wait(750)
        else
            Wait(1500)
        end
    end
end)

