local function equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s")
      :format(tostring(expected), tostring(actual)))
  end
end

local assessments = {}
local leases = {}
local sql = {}
function sql:Single(query, values)
  if query:find("FROM lr_trucker_rental_assessments", 1, true) then
    return assessments[values[1]]
  end
  if query:find("FROM lr_trucker_rental_leases", 1, true) then
    return leases[values[1]]
  end
  error("unexpected SELECT")
end
function sql:Update(query, values)
  if query:find("INSERT IGNORE INTO lr_trucker_rental_assessments", 1, true) then
    if assessments[values[1]] then return 0 end
    assessments[values[1]] = {
      settlement_id = values[1], rental_id = values[2], cumulative_due = values[3],
      gross_reward = values[4], net_reward = values[5], bank_due = values[6],
      committed = 0,
    }
    return 1
  end
  if query:find("UPDATE lr_trucker_rental_leases", 1, true) then
    local lease = leases[values[2]]
    if not lease or lease.rental_id ~= values[3] then return 0 end
    lease.assessed_overage = math.max(lease.assessed_overage, values[1])
    return 1
  end
  if query:find("UPDATE lr_trucker_rental_assessments", 1, true) then
    local assessment = assessments[values[1]]
    assessment.committed = 1
    return 1
  end
  error("unexpected UPDATE")
end

LR = { CreateDatabaseBridge = function() return sql end }
dofile("server/database.lua")
local db = LRTruckerServer.Database
local expires = 1003600
local row = {
  citizen_id = "driver", rental_id = "rent-1", rental_key = "mule",
  model = "mule", plate = "LR000001", fee = 5000,
  started_at = expires - 3600, expires_at = expires,
  assessed_overage = 0, status = "active",
}
leases.driver = row
local lease = db.GetRentalLease("driver")
local onTime = db.PrepareRentalAssessment(lease, "order-on-time", 1000, expires, 3)
equal(onTime.netReward, 1000, "60-minute order lost pay")
equal(onTime.bankDue, 0, "60-minute order gained overage")
equal(db.CommitRentalAssessment("driver", lease.id, "order-on-time"), true)

lease = db.GetRentalLease("driver")
local first = db.PrepareRentalAssessment(lease, "order-one", 100, expires + 1, 3)
equal(first.netReward, 0, "first overage did not offset the reward")
equal(first.bankDue, 50, "first overage bank balance is wrong")
equal(db.CommitRentalAssessment("driver", lease.id, "order-one"), true)
equal(row.assessed_overage, 150, "first overage was not recorded")
local replay = db.PrepareRentalAssessment(db.GetRentalLease("driver"),
  "order-one", 100, expires + 180, 3)
equal(replay.bankDue, 50, "replay changed a frozen settlement")

lease = db.GetRentalLease("driver")
local second = db.PrepareRentalAssessment(lease, "order-two", 1000, expires + 61, 3)
equal(second.netReward, 850, "second order paid the same overage twice")
equal(second.bankDue, 0)
equal(db.CommitRentalAssessment("driver", lease.id, "order-two"), true)
equal(row.assessed_overage, 300)

lease = db.GetRentalLease("driver")
local returned = db.PrepareRentalAssessment(lease, "return-rent-1", 0, expires + 121, 3)
equal(returned.bankDue, 150, "return did not include the remaining minute")
equal(first.bankDue + (100 - first.netReward) + (1000 - second.netReward)
  + returned.bankDue, 450, "overage across orders and return did not add up")
