LRTruckerServer = LRTruckerServer or {}

---@class LRServer.TruckerPlayerData
---@field source integer
---@field citizenId string
---@field name string
---@field xp integer
---@field level integer
---@field job? LRServer.FrameworkGroup

---@class LRServer.TruckerTeamMember
---@field source integer
---@field citizenId string
---@field name string
---@field online boolean

---@class LRServer.TruckerTeamInput
---@field id string
---@field player LRServer.TruckerPlayerData

---@class LRServer.TruckerTeam : LRShared.ClassInstance
---@field id string
---@field hostCitizenId string
---@field members LRServer.TruckerTeamMember[]
---@field session? LRServer.TruckerMissionSession
---@field FindMember fun(self: LRServer.TruckerTeam, citizenId: string): LRServer.TruckerTeamMember?, integer?
---@field FindMemberBySource fun(self: LRServer.TruckerTeam, playerSource: integer): LRServer.TruckerTeamMember?, integer?
---@field OnlineMembers fun(self: LRServer.TruckerTeam): LRServer.TruckerTeamMember[]
---@field IsHost fun(self: LRServer.TruckerTeam, citizenId: string): boolean
---@field Reconnect fun(self: LRServer.TruckerTeam, player: LRServer.TruckerPlayerData): LRServer.TruckerTeamMember?
---@field AddMember fun(self: LRServer.TruckerTeam, player: LRServer.TruckerPlayerData): LRServer.TruckerTeamMember
---@field RemoveMemberAt fun(self: LRServer.TruckerTeam, index: integer): LRServer.TruckerTeamMember?
---@field MarkOffline fun(self: LRServer.TruckerTeam, playerSource: integer): LRServer.TruckerTeamMember?
---@field Serialize fun(self: LRServer.TruckerTeam): table

---@class LRServer.TruckerTeamClass : LRShared.Class<LRServer.TruckerTeam, LRServer.TruckerTeamInput>
---@field init fun(self: LRServer.TruckerTeam, input: LRServer.TruckerTeamInput)
---@field FindMember fun(self: LRServer.TruckerTeam, citizenId: string): LRServer.TruckerTeamMember?, integer?
---@field FindMemberBySource fun(self: LRServer.TruckerTeam, playerSource: integer): LRServer.TruckerTeamMember?, integer?
---@field OnlineMembers fun(self: LRServer.TruckerTeam): LRServer.TruckerTeamMember[]
---@field IsHost fun(self: LRServer.TruckerTeam, citizenId: string): boolean
---@field Reconnect fun(self: LRServer.TruckerTeam, player: LRServer.TruckerPlayerData): LRServer.TruckerTeamMember?
---@field AddMember fun(self: LRServer.TruckerTeam, player: LRServer.TruckerPlayerData): LRServer.TruckerTeamMember
---@field RemoveMemberAt fun(self: LRServer.TruckerTeam, index: integer): LRServer.TruckerTeamMember?
---@field MarkOffline fun(self: LRServer.TruckerTeam, playerSource: integer): LRServer.TruckerTeamMember?
---@field Serialize fun(self: LRServer.TruckerTeam): table

---@type LRServer.TruckerTeamClass
local Team = LR.Class:Define("TruckerTeam")

---@param self LRServer.TruckerTeam
---@param input LRServer.TruckerTeamInput
function Team:init(input)
  local player = input.player
  self.id = input.id
  self.hostCitizenId = player.citizenId
  self.members = {
    {
      source = player.source,
      citizenId = player.citizenId,
      name = player.name,
      online = true,
    },
  }
  self.session = nil
end

---@param self LRServer.TruckerTeam
---@param citizenId string
---@return LRServer.TruckerTeamMember?, integer?
function Team:FindMember(citizenId)
  for index = 1, #self.members do
    if self.members[index].citizenId == citizenId then return self.members[index], index end
  end
  return nil, nil
end

---@param self LRServer.TruckerTeam
---@param playerSource integer
---@return LRServer.TruckerTeamMember?, integer?
function Team:FindMemberBySource(playerSource)
  for index = 1, #self.members do
    local member = self.members[index]
    if member.online and member.source == playerSource then return member, index end
  end
  return nil, nil
end

---@param self LRServer.TruckerTeam
---@return LRServer.TruckerTeamMember[]
function Team:OnlineMembers()
  local result = {}
  for index = 1, #self.members do
    if self.members[index].online then result[#result + 1] = self.members[index] end
  end
  return result
end

---@param self LRServer.TruckerTeam
---@param citizenId string
---@return boolean
function Team:IsHost(citizenId)
  return self.hostCitizenId == citizenId
end

---@param self LRServer.TruckerTeam
---@param player LRServer.TruckerPlayerData
---@return LRServer.TruckerTeamMember?
function Team:Reconnect(player)
  local member = self:FindMember(player.citizenId)
  if not member then return nil end
  member.source = player.source
  member.name = player.name
  member.online = true
  return member
end

---@param self LRServer.TruckerTeam
---@param player LRServer.TruckerPlayerData
---@return LRServer.TruckerTeamMember
function Team:AddMember(player)
  local member = {
    source = player.source,
    citizenId = player.citizenId,
    name = player.name,
    online = true,
  }
  self.members[#self.members + 1] = member
  return member
end

---@param self LRServer.TruckerTeam
---@param index integer
---@return LRServer.TruckerTeamMember?
function Team:RemoveMemberAt(index)
  local member = self.members[index]
  if not member then return nil end
  table.remove(self.members, index)
  if self.hostCitizenId == member.citizenId and self.members[1] then
    self.hostCitizenId = self.members[1].citizenId
  end
  return member
end

---@param self LRServer.TruckerTeam
---@param playerSource integer
---@return LRServer.TruckerTeamMember?
function Team:MarkOffline(playerSource)
  local member = self:FindMemberBySource(playerSource)
  if not member then return nil end
  member.online = false
  member.source = 0
  if self.hostCitizenId == member.citizenId then
    local online = self:OnlineMembers()
    if online[1] then self.hostCitizenId = online[1].citizenId end
  end
  return member
end

---@param self LRServer.TruckerTeam
---@return table
function Team:Serialize()
  local members = {}
  for index = 1, #self.members do
    local member = self.members[index]
    members[index] = {
      source = member.online and member.source or 0,
      citizenId = member.citizenId,
      name = member.name,
      online = member.online,
    }
  end
  return {
    id = self.id,
    hostCitizenId = self.hostCitizenId,
    members = members,
  }
end

LRTruckerServer.Team = Team
