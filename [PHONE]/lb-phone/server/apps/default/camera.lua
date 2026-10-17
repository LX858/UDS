local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1
L0_1 = nil
L1_1 = RegisterCallback
L2_1 = "camera:getBaseUrl"
function L3_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    L0_2 = GetConvar
    L1_2 = "web_baseUrl"
    L2_2 = ""
    L0_2 = L0_2(L1_2, L2_2)
    L0_1 = L0_2
  end
  L0_2 = L0_1
  return L0_2
end
L1_1(L2_1, L3_1)
L1_1 = {}
L1_1.Audio = "audio"
L1_1.Image = "image"
L1_1.Video = "video"
L2_1 = RegisterCallback
L3_1 = "camera:getPresignedUrl"
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = L1_1
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L3_2 = Config
  L3_2 = L3_2.UploadMethod
  L3_2 = L3_2[A1_2]
  if "Fivemanage" ~= L3_2 then
    L3_2 = GetPresignedUrl
    if L3_2 then
      L3_2 = GetPresignedUrl
      L4_2 = A0_2
      L5_2 = A1_2
      return L3_2(L4_2, L5_2)
    else
      L3_2 = infoprint
      L4_2 = "warning"
      L5_2 = "GetPresignedUrl has not been set up. Set it up in lb-phone/server/custom/functions/functions.lua, or change your upload method to Fivemanage."
      L3_2(L4_2, L5_2)
    end
    return
  end
  L3_2 = promise
  L3_2 = L3_2.new
  L3_2 = L3_2()
  L4_2 = PerformHttpRequest
  L5_2 = "https://fmapi.net/api/v2/presigned-url?fileType="
  L6_2 = L2_2
  L5_2 = L5_2 .. L6_2
  function L6_2(A0_3, A1_3, A2_3, A3_3)
    local L4_3, L5_3, L6_3, L7_3, L8_3
    if 200 ~= A0_3 then
      L4_3 = infoprint
      L5_3 = "error"
      L6_3 = "Failed to get presigned URL from Fivemanage for "
      L7_3 = L2_2
      L6_3 = L6_3 .. L7_3
      L4_3(L5_3, L6_3)
      L4_3 = print
      L5_3 = "Status:"
      L6_3 = A0_3
      L4_3(L5_3, L6_3)
      L4_3 = print
      L5_3 = "Body:"
      L6_3 = A1_3
      L4_3(L5_3, L6_3)
      L4_3 = print
      L5_3 = "Headers:"
      L6_3 = json
      L6_3 = L6_3.encode
      L7_3 = A2_3 or L7_3
      if not A2_3 then
        L7_3 = {}
      end
      L8_3 = {}
      L8_3.indent = true
      L6_3, L7_3, L8_3 = L6_3(L7_3, L8_3)
      L4_3(L5_3, L6_3, L7_3, L8_3)
      if A3_3 then
        L4_3 = print
        L5_3 = "Error:"
        L6_3 = A3_3
        L4_3(L5_3, L6_3)
      end
      L4_3 = L3_2
      L5_3 = L4_3
      L4_3 = L4_3.resolve
      L4_3(L5_3)
      return
    end
    L4_3 = json
    L4_3 = L4_3.decode
    L5_3 = A1_3
    L4_3 = L4_3(L5_3)
    L5_3 = L3_2
    L6_3 = L5_3
    L5_3 = L5_3.resolve
    L7_3 = L4_3
    if L7_3 then
      L7_3 = L7_3.data
    end
    if L7_3 then
      L7_3 = L7_3.presignedUrl
    end
    L5_3(L6_3, L7_3)
  end
  L7_2 = "GET"
  L8_2 = ""
  L9_2 = {}
  L10_2 = API_KEYS
  L10_2 = L10_2[A1_2]
  L9_2.Authorization = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = Citizen
  L4_2 = L4_2.Await
  L5_2 = L3_2
  return L4_2(L5_2)
end
L2_1(L3_1, L4_1)
L2_1 = RegisterNetEvent
L3_1 = "phone:setListeningPeerId"
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Config
  L1_2 = L1_2.Voice
  L1_2 = L1_2.RecordNearby
  if not L1_2 then
    return
  end
  L1_2 = source
  L2_2 = Player
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2.state
  L2_2 = L2_2.listeningPeerId
  if L2_2 then
    L3_2 = TriggerClientEvent
    L4_2 = "phone:stoppedListening"
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = Player
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2.state
  L3_2.listeningPeerId = A0_2
  L3_2 = debugprint
  L4_2 = L1_2
  L5_2 = "set listeningPeerId to"
  L6_2 = A0_2
  L3_2(L4_2, L5_2, L6_2)
  if A0_2 then
    L3_2 = TriggerClientEvent
    L4_2 = "phone:startedListening"
    L5_2 = -1
    L6_2 = L1_2
    L7_2 = A0_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L2_1(L3_1, L4_1)
L2_1 = AddEventHandler
L3_1 = "playerDropped"
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = source
  L1_2 = Player
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2.state
  L1_2 = L1_2.listeningPeerId
  if L1_2 then
    L2_2 = debugprint
    L3_2 = L0_2
    L4_2 = "dropped, listeningPeerId"
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = TriggerClientEvent
    L3_2 = "phone:stoppedListening"
    L4_2 = -1
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L2_1(L3_1, L4_1)
L2_1 = RegisterCallback
L3_1 = "camera:getUploadApiKey"
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 then
    L2_2 = API_KEYS
    L2_2 = L2_2[A1_2]
    if L2_2 then
      goto lbl_8
    end
  end
  do return end
  ::lbl_8::
  L2_2 = Config
  L2_2 = L2_2.UploadMethod
  L2_2 = L2_2[A1_2]
  if "Fivemanage" == L2_2 then
    L2_2 = DropPlayer
    L3_2 = A0_2
    L4_2 = "Tried to abuse the upload system"
    L2_2(L3_2, L4_2)
    return
  end
  L2_2 = API_KEYS
  L2_2 = L2_2[A1_2]
  return L2_2
end
L2_1(L3_1, L4_1)
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = MySQL
  L3_2 = L3_2.query
  L3_2 = L3_2.await
  L4_2 = "SELECT phone_number FROM phone_photo_album_members WHERE album_id = ?"
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    return
  end
  if not A2_2 then
    L4_2 = MySQL
    L4_2 = L4_2.scalar
    L4_2 = L4_2.await
    L5_2 = "SELECT phone_number FROM phone_photo_albums WHERE id = ?"
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = #L3_2
    L5_2 = L5_2 + 1
    L6_2 = {}
    L6_2.phone_number = L4_2
    L3_2[L5_2] = L6_2
  end
  L4_2 = 1
  L5_2 = #L3_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L3_2[L7_2]
    L8_2 = L8_2.phone_number
    L9_2 = GetSourceFromNumber
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L10_2 = A1_2
    L11_2 = L8_2
    L12_2 = L9_2
    L10_2(L11_2, L12_2)
  end
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MySQL
  L1_2 = L1_2.single
  L1_2 = L1_2.await
  L2_2 = [[
        SELECT
            pa.id,
            pa.title,
            pa.shared,
            (
                SELECT
                    pp_cover.link
                FROM
                    phone_photos pp_cover
                JOIN
                    phone_photo_album_photos ap_cover ON ap_cover.photo_id = pp_cover.id
                WHERE
                    ap_cover.album_id = pa.id
                ORDER BY
                    ap_cover.photo_id DESC
                LIMIT 1
            ) AS cover,
            SUM(CASE WHEN pp.is_video = 1 THEN 1 ELSE 0 END) AS videoCount,
            SUM(CASE WHEN pp.is_video = 0 THEN 1 ELSE 0 END) AS photoCount
        FROM
            phone_photo_albums pa
        LEFT JOIN
            phone_photo_album_photos ap ON ap.album_id = pa.id
        LEFT JOIN
            phone_photos pp ON pp.id = ap.photo_id
        WHERE
            pa.id = ?
        GROUP BY
            pa.id, pa.title, pa.shared, pa.phone_number
    ]]
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L2_2 = tonumber
  L3_2 = L1_2.photoCount
  if not L3_2 then
    L3_2 = 0
  end
  L2_2 = L2_2(L3_2)
  L1_2.photoCount = L2_2
  L2_2 = tonumber
  L3_2 = L1_2.videoCount
  if not L3_2 then
    L3_2 = 0
  end
  L2_2 = L2_2(L3_2)
  L1_2.videoCount = L2_2
  L2_2 = L1_2.photoCount
  L3_2 = L1_2.videoCount
  L2_2 = L2_2 + L3_2
  L1_2.count = L2_2
  return L1_2
end
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = MySQL
  L2_2 = L2_2.single
  L2_2 = L2_2.await
  L3_2 = "SELECT phone_number, shared FROM phone_photo_albums WHERE id = ?"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L3_2 = debugprint
    L4_2 = "DoesPhoneNumberHaveAccessToAlbum: Album not found"
    L5_2 = A0_2
    L6_2 = A1_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = false
    return L3_2
  end
  L3_2 = L2_2.shared
  if not L3_2 then
    L3_2 = L2_2.phone_number
    if L3_2 ~= A0_2 then
      L3_2 = debugprint
      L4_2 = "DoesPhoneNumberHaveAccessToAlbum: Private album, not the owner"
      L5_2 = A0_2
      L6_2 = A1_2
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = false
      return L3_2
  end
  else
    L3_2 = L2_2.shared
    if L3_2 then
      L3_2 = L2_2.phone_number
      if L3_2 ~= A0_2 then
        L3_2 = MySQL
        L3_2 = L3_2.scalar
        L3_2 = L3_2.await
        L4_2 = "SELECT 1 FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?"
        L5_2 = {}
        L6_2 = A1_2
        L7_2 = A0_2
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L3_2 = L3_2(L4_2, L5_2)
        if not L3_2 then
          L4_2 = debugprint
          L5_2 = "DoesPhoneNumberHaveAccessToAlbum: Album is shared, but not a member"
          L6_2 = A0_2
          L7_2 = A1_2
          L4_2(L5_2, L6_2, L7_2)
          L4_2 = false
          return L4_2
        end
      end
    end
  end
  return L2_2
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L3_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = L2_1
  L3_2 = A0_2
  function L4_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    if A1_3 then
      L2_3 = TriggerClientEvent
      L3_3 = "phone:photos:updateAlbum"
      L4_3 = A1_3
      L5_3 = L1_2
      L2_3(L3_3, L4_3, L5_3)
    end
  end
  L2_2(L3_2, L4_2)
end
L6_1 = {}
L6_1.selfie = true
L6_1.import = true
L6_1.screenshot = true
L7_1 = BaseCallback
L8_1 = "camera:saveToGallery"
function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L7_2 = IsMediaLinkAllowed
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = infoprint
    L8_2 = "error"
    L9_2 = "%s %s tried to save an image with a link that is not allowed:"
    L10_2 = L9_2
    L9_2 = L9_2.format
    L11_2 = A0_2
    L12_2 = A1_2
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    L10_2 = A2_2
    L7_2(L8_2, L9_2, L10_2)
    L7_2 = false
    return L7_2
  end
  if A5_2 then
    L7_2 = L6_1
    L7_2 = L7_2[A5_2]
    if not L7_2 then
      L7_2 = debugprint
      L8_2 = "Invalid metadata"
      L9_2 = A5_2
      L7_2(L8_2, L9_2)
      A5_2 = nil
    end
  end
  L7_2 = MySQL
  L7_2 = L7_2.insert
  L7_2 = L7_2.await
  L8_2 = "INSERT INTO phone_photos (phone_number, link, is_video, size, metadata) VALUES (?, ?, ?, ?, ?)"
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = A2_2
  L12_2 = true == A4_2
  L13_2 = A3_2 or L13_2
  if not A3_2 then
    L13_2 = 0
  end
  L14_2 = A5_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L7_2 = L7_2(L8_2, L9_2)
  if A6_2 then
    L8_2 = Log
    L9_2 = "Uploads"
    L10_2 = A0_2
    L11_2 = "info"
    L12_2 = L
    L13_2 = "BACKEND.LOGS.UPLOADED_MEDIA"
    L12_2 = L12_2(L13_2)
    L13_2 = L
    L14_2 = "BACKEND.LOGS.UPLOADED_MEDIA_DESCRIPTION"
    L15_2 = {}
    if A4_2 then
      L16_2 = L
      L17_2 = "BACKEND.LOGS.VIDEO"
      L16_2 = L16_2(L17_2)
      if L16_2 then
        goto lbl_69
      end
    end
    L16_2 = L
    L17_2 = "BACKEND.LOGS.PHOTO"
    L16_2 = L16_2(L17_2)
    ::lbl_69::
    L15_2.type = L16_2
    L15_2.id = L7_2
    L15_2.link = A2_2
    L13_2 = L13_2(L14_2, L15_2)
    L14_2 = A2_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L8_2 = TrackSimpleEvent
    if A4_2 then
      L9_2 = "take_video"
      if L9_2 then
        goto lbl_82
      end
    end
    L9_2 = "take_photo"
    ::lbl_82::
    L8_2(L9_2)
  end
  return L7_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:deleteFromGallery"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MySQL
  L3_2 = L3_2.update
  L3_2 = L3_2.await
  L4_2 = "DELETE FROM phone_photos WHERE phone_number = ? AND id IN (?)"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A2_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = true
  return L3_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:toggleFavourites"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = MySQL
  L4_2 = L4_2.update
  L4_2 = L4_2.await
  L5_2 = "UPDATE phone_photos SET is_favourite = ? WHERE phone_number = ? AND id IN (?)"
  L6_2 = {}
  L7_2 = true == A2_2
  L8_2 = A1_2
  L9_2 = A3_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2(L5_2, L6_2)
  L4_2 = true
  return L4_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:getImages"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = A2_2.showVideos
  if not L4_2 then
    L4_2 = A2_2.showPhotos
    if not L4_2 then
      L4_2 = {}
      return L4_2
    end
  end
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L5_2 = {}
  L6_2 = "phone_number = ?"
  L5_2[1] = L6_2
  L6_2 = "SELECT id, link, is_video, size, metadata, is_favourite, `timestamp` FROM phone_photos {WHERE}"
  L7_2 = A2_2.showPhotos
  L8_2 = A2_2.showVideos
  if L7_2 ~= L8_2 then
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = "(is_video = ? OR is_video != ?)"
    L7_2 = #L4_2
    L7_2 = L7_2 + 1
    L8_2 = A2_2.showVideos
    L8_2 = true == L8_2
    L4_2[L7_2] = L8_2
    L7_2 = #L4_2
    L7_2 = L7_2 + 1
    L8_2 = A2_2.showPhotos
    L8_2 = true == L8_2
    L4_2[L7_2] = L8_2
  end
  L7_2 = A2_2.favourites
  if true == L7_2 then
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = "is_favourite = 1"
  end
  L7_2 = A2_2.type
  if L7_2 then
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = "metadata = ?"
    L7_2 = #L4_2
    L7_2 = L7_2 + 1
    L8_2 = A2_2.type
    L4_2[L7_2] = L8_2
  end
  L7_2 = A2_2.album
  if L7_2 then
    L7_2 = L4_1
    L8_2 = A1_2
    L9_2 = A2_2.album
    L7_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L7_2 = debugprint
      L8_2 = "getImages: No access to album"
      L9_2 = A1_2
      L10_2 = A2_2.album
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = {}
      return L7_2
    end
    L7_2 = table
    L7_2 = L7_2.remove
    L8_2 = L5_2
    L9_2 = 1
    L7_2(L8_2, L9_2)
    L7_2 = table
    L7_2 = L7_2.remove
    L8_2 = L4_2
    L9_2 = 1
    L7_2(L8_2, L9_2)
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = "id IN (SELECT ap.photo_id FROM phone_photo_album_photos ap WHERE ap.album_id = ?)"
    L7_2 = #L4_2
    L7_2 = L7_2 + 1
    L8_2 = A2_2.album
    L4_2[L7_2] = L8_2
  end
  L7_2 = A2_2.duplicates
  if L7_2 then
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = [[
            link IN (
                SELECT link
                FROM phone_photos
                WHERE phone_number = ?
                GROUP BY link
                HAVING COUNT(1) > 1
            )
        ]]
    L7_2 = #L4_2
    L7_2 = L7_2 + 1
    L4_2[L7_2] = A1_2
  end
  L7_2 = math
  L7_2 = L7_2.clamp
  L8_2 = A2_2.perPage
  if not L8_2 then
    L8_2 = 32
  end
  L9_2 = 1
  L10_2 = 32
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = L6_2
  L9_2 = " ORDER BY `timestamp` DESC LIMIT ?, ?"
  L8_2 = L8_2 .. L9_2
  L6_2 = L8_2
  L9_2 = L6_2
  L8_2 = L6_2.gsub
  L10_2 = "{WHERE}"
  L11_2 = #L5_2
  if L11_2 > 0 then
    L11_2 = "WHERE "
    L12_2 = table
    L12_2 = L12_2.concat
    L13_2 = L5_2
    L14_2 = " AND "
    L12_2 = L12_2(L13_2, L14_2)
    L11_2 = L11_2 .. L12_2
    if L11_2 then
      goto lbl_139
    end
  end
  L11_2 = ""
  ::lbl_139::
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L6_2 = L8_2
  L8_2 = #L4_2
  L8_2 = L8_2 + 1
  L9_2 = A3_2 or L9_2
  if not A3_2 then
    L9_2 = 0
  end
  L9_2 = L9_2 * L7_2
  L4_2[L8_2] = L9_2
  L8_2 = #L4_2
  L8_2 = L8_2 + 1
  L4_2[L8_2] = L7_2
  L8_2 = MySQL
  L8_2 = L8_2.query
  L8_2 = L8_2.await
  L9_2 = L6_2
  L10_2 = L4_2
  return L8_2(L9_2, L10_2)
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:getLastImage"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MySQL
  L2_2 = L2_2.scalar
  L2_2 = L2_2.await
  L3_2 = "SELECT link FROM phone_photos WHERE phone_number = ? ORDER BY id DESC LIMIT 1"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  return L2_2(L3_2, L4_2)
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:createAlbum"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MySQL
  L3_2 = L3_2.insert
  L3_2 = L3_2.await
  L4_2 = "INSERT INTO phone_photo_albums (phone_number, title) VALUES (?, ?)"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A2_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2 = L3_2(L4_2, L5_2)
  return L3_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:renameAlbum"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = MySQL
  L4_2 = L4_2.update
  L4_2 = L4_2.await
  L5_2 = "UPDATE phone_photo_albums SET title = ? WHERE phone_number = ? AND id = ?"
  L6_2 = {}
  L7_2 = A3_2
  L8_2 = A1_2
  L9_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2 = L4_2(L5_2, L6_2)
  L4_2 = L4_2 > 0
  if L4_2 then
    L5_2 = MySQL
    L5_2 = L5_2.scalar
    L5_2 = L5_2.await
    L6_2 = "SELECT shared FROM phone_photo_albums WHERE id = ?"
    L7_2 = {}
    L8_2 = A2_2
    L7_2[1] = L8_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      L5_2 = L2_1
      L6_2 = A2_2
      function L7_2(A0_3, A1_3)
        local L2_3, L3_3, L4_3, L5_3, L6_3
        if A1_3 then
          L2_3 = TriggerClientEvent
          L3_3 = "phone:photos:renameAlbum"
          L4_3 = A1_3
          L5_3 = A2_2
          L6_3 = A3_2
          L2_3(L3_3, L4_3, L5_3, L6_3)
        end
      end
      L8_2 = true
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  return L4_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:addToAlbum"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L4_1
  L5_2 = A1_2
  L6_2 = A2_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = debugprint
    L6_2 = "No access to album"
    L7_2 = A1_2
    L8_2 = A2_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = false
    return L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.update
  L5_2 = L5_2.await
  L6_2 = "INSERT IGNORE INTO phone_photo_album_photos (album_id, photo_id) SELECT ?, id FROM phone_photos WHERE phone_number = ? AND id IN (?)"
  L7_2 = {}
  L8_2 = A2_2
  L9_2 = A1_2
  L10_2 = A3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L5_2(L6_2, L7_2)
  L5_2 = debugprint
  L6_2 = "Added photos to album"
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = L4_2.shared
  if L5_2 then
    L5_2 = L5_1
    L6_2 = A2_2
    L5_2(L6_2)
  end
  L5_2 = true
  return L5_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:removeFromAlbum"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L4_1
  L5_2 = A1_2
  L6_2 = A2_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = debugprint
    L6_2 = "No access to album"
    L7_2 = A1_2
    L8_2 = A2_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = false
    return L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.update
  L5_2 = L5_2.await
  L6_2 = "DELETE FROM phone_photo_album_photos WHERE album_id = ? AND photo_id IN (?)"
  L7_2 = {}
  L8_2 = A2_2
  L9_2 = A3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = L5_1
  L6_2 = A2_2
  L5_2(L6_2)
  L5_2 = true
  return L5_2
end
L7_1(L8_1, L9_1)
L7_1 = BaseCallback
L8_1 = "camera:deleteAlbum"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = MySQL
  L3_2 = L3_2.single
  L3_2 = L3_2.await
  L4_2 = "SELECT shared FROM phone_photo_albums WHERE phone_number = ? AND id = ?"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A2_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L4_2 = debugprint
    L5_2 = "deleteAlbum: Album not found"
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
    L4_2 = false
    return L4_2
  end
  L4_2 = L3_2.shared
  if L4_2 then
    L4_2 = L2_1
    L5_2 = A2_2
    function L6_2(A0_3, A1_3)
      local L2_3, L3_3, L4_3, L5_3, L6_3
      if A1_3 then
        L2_3 = TriggerClientEvent
        L3_3 = "phone:photos:removeMemberFromAlbum"
        L4_3 = A1_3
        L5_3 = A2_2
        L6_3 = A0_3
        L2_3(L3_3, L4_3, L5_3, L6_3)
      end
    end
    L7_2 = true
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.update
  L5_2 = "DELETE FROM phone_photo_albums WHERE phone_number = ? AND id = ?"
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2(L5_2, L6_2)
  L4_2 = true
  return L4_2
end
L7_1(L8_1, L9_1)
L7_1 = {}
L8_1 = "videos"
L9_1 = "photos"
L10_1 = "favouritesVideos"
L11_1 = "favouritesPhotos"
L12_1 = "selfiesVideos"
L13_1 = "selfiesPhotos"
L14_1 = "screenshotsVideos"
L15_1 = "screenshotsPhotos"
L16_1 = "importsVideos"
L17_1 = "importsPhotos"
L18_1 = "duplicatesPhotos"
L19_1 = "duplicatesVideos"
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L7_1[4] = L11_1
L7_1[5] = L12_1
L7_1[6] = L13_1
L7_1[7] = L14_1
L7_1[8] = L15_1
L7_1[9] = L16_1
L7_1[10] = L17_1
L7_1[11] = L18_1
L7_1[12] = L19_1
L8_1 = BaseCallback
L9_1 = "camera:getHomePageData"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = MySQL
  L2_2 = L2_2.single
  L2_2 = L2_2.await
  L3_2 = [[
        SELECT
            SUM(is_video = 1) AS videos,
            SUM(is_video = 0) AS photos,
            SUM(is_video = 1 AND is_favourite = 1) AS favouritesVideos,
            SUM(is_video = 0 AND is_favourite = 1) AS favouritesPhotos,
            SUM(metadata = 'selfie' AND is_video = 1) AS selfiesVideos,
            SUM(metadata = 'selfie' AND is_video = 0) AS selfiesPhotos,
            SUM(metadata = 'screenshot' AND is_video = 1) AS screenshotsVideos,
            SUM(metadata = 'screenshot' AND is_video = 0) AS screenshotsPhotos,
            SUM(metadata = 'import' AND is_video = 1) AS importsVideos,
            SUM(metadata = 'import' AND is_video = 0) AS importsPhotos

        FROM phone_photos
        WHERE phone_number = ?
    ]]
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = tonumber
  L4_2 = L2_2.photos
  if not L4_2 then
    L4_2 = 0
  end
  L3_2 = L3_2(L4_2)
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT COUNT(DISTINCT link)
        FROM phone_photos
        WHERE phone_number = ? AND is_video = 0
    ]]
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  L3_2 = L3_2 - L4_2
  L2_2.duplicatesPhotos = L3_2
  L3_2 = tonumber
  L4_2 = L2_2.videos
  if not L4_2 then
    L4_2 = 0
  end
  L3_2 = L3_2(L4_2)
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT COUNT(DISTINCT link)
        FROM phone_photos
        WHERE phone_number = ? AND is_video = 1
    ]]
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  L3_2 = L3_2 - L4_2
  L2_2.duplicatesVideos = L3_2
  L3_2 = 1
  L4_2 = L7_1
  L4_2 = #L4_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = L7_1
    L7_2 = L7_2[L6_2]
    L8_2 = tonumber
    L9_2 = L2_2[L7_2]
    if not L9_2 then
      L9_2 = 0
    end
    L8_2 = L8_2(L9_2)
    L2_2[L7_2] = L8_2
  end
  L3_2 = L2_2.duplicatesPhotos
  if L3_2 > 0 then
    L3_2 = L2_2.duplicatesPhotos
    L3_2 = L3_2 + 1
    L2_2.duplicatesPhotos = L3_2
  end
  L3_2 = L2_2.duplicatesVideos
  if L3_2 > 0 then
    L3_2 = L2_2.duplicatesVideos
    L3_2 = L3_2 + 1
    L2_2.duplicatesVideos = L3_2
  end
  L3_2 = {}
  L4_2 = {}
  L4_2.id = "recents"
  L5_2 = L
  L6_2 = "APPS.PHOTOS.RECENTS"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = L2_2.videos
  L4_2.videoCount = L5_2
  L5_2 = L2_2.photos
  L4_2.photoCount = L5_2
  L5_2 = MySQL
  L5_2 = L5_2.scalar
  L5_2 = L5_2.await
  L6_2 = "SELECT link FROM phone_photos WHERE phone_number = ? ORDER BY id DESC LIMIT 1"
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.cover = L5_2
  L4_2.removable = false
  L5_2 = {}
  L5_2.id = "favourites"
  L6_2 = L
  L7_2 = "APPS.PHOTOS.FAVOURITES"
  L6_2 = L6_2(L7_2)
  L5_2.title = L6_2
  L6_2 = L2_2.favouritesVideos
  L5_2.videoCount = L6_2
  L6_2 = L2_2.favouritesPhotos
  L5_2.photoCount = L6_2
  L6_2 = MySQL
  L6_2 = L6_2.scalar
  L6_2 = L6_2.await
  L7_2 = "SELECT link FROM phone_photos WHERE phone_number = ? AND is_favourite = 1 ORDER BY id DESC LIMIT 1"
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L6_2 = L6_2(L7_2, L8_2)
  L5_2.cover = L6_2
  L5_2.removable = false
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = MySQL
  L4_2 = L4_2.query
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT
            pa.id,
            pa.title,
            pa.shared,
            pa.phone_number,
            (
                SELECT
                    pp_cover.link
                FROM
                    phone_photos pp_cover
                JOIN
                    phone_photo_album_photos ap_cover ON ap_cover.photo_id = pp_cover.id
                WHERE
                    ap_cover.album_id = pa.id
                ORDER BY
                    ap_cover.photo_id DESC
                LIMIT 1
            ) AS cover,
            SUM(CASE WHEN pp.is_video = 1 THEN 1 ELSE 0 END) AS videoCount,
            SUM(CASE WHEN pp.is_video = 0 THEN 1 ELSE 0 END) AS photoCount
        FROM
            phone_photo_albums pa
        LEFT JOIN
            phone_photo_album_photos ap ON ap.album_id = pa.id
        LEFT JOIN
            phone_photos pp ON pp.id = ap.photo_id
        WHERE
            pa.phone_number = ?
            OR EXISTS (
                SELECT 1
                FROM phone_photo_album_members member
                WHERE member.album_id = pa.id AND member.phone_number = ?
            )
        GROUP BY
            pa.id, pa.title, pa.shared, pa.phone_number
        ORDER BY
            pa.id ASC
    ]]
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = 1
  L6_2 = #L4_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L4_2[L8_2]
    L9_2.removable = true
    L10_2 = L9_2.phone_number
    L10_2 = L10_2 == A1_2
    L9_2.isOwner = L10_2
    L9_2.phone_number = nil
    L10_2 = #L3_2
    L10_2 = L10_2 + 1
    L11_2 = L4_2[L8_2]
    L3_2[L10_2] = L11_2
  end
  L5_2 = 1
  L6_2 = #L3_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L3_2[L8_2]
    L10_2 = tonumber
    L11_2 = L9_2.photoCount
    if not L11_2 then
      L11_2 = 0
    end
    L10_2 = L10_2(L11_2)
    L9_2.photoCount = L10_2
    L10_2 = tonumber
    L11_2 = L9_2.videoCount
    if not L11_2 then
      L11_2 = 0
    end
    L10_2 = L10_2(L11_2)
    L9_2.videoCount = L10_2
    L10_2 = L9_2.photoCount
    L11_2 = L9_2.videoCount
    L10_2 = L10_2 + L11_2
    L9_2.count = L10_2
  end
  L5_2 = {}
  L5_2.albums = L3_2
  L5_2.mediaTypes = L2_2
  return L5_2
end
L11_1 = {}
L12_1 = {}
L11_1.albums = L12_1
L12_1 = {}
L11_1.mediaTypes = L12_1
L8_1(L9_1, L10_1, L11_1)
L8_1 = BaseCallback
L9_1 = "camera:getAlbumMembers"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = L4_1
  L4_2 = A1_2
  L5_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L3_2 = debugprint
    L4_2 = "getAlbumMembers: No access to album"
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = false
    return L3_2
  end
  L3_2 = {}
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT phone_number FROM phone_photo_albums WHERE id = ?"
  L6_2 = {}
  L7_2 = A2_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = MySQL
  L5_2 = L5_2.query
  L5_2 = L5_2.await
  L6_2 = "SELECT phone_number FROM phone_photo_album_members WHERE album_id = ?"
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = 1
  L7_2 = #L5_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = L5_2[L9_2]
    L10_2 = L10_2.phone_number
    L3_2[L9_2] = L10_2
  end
  L6_2 = #L3_2
  L6_2 = L6_2 + 1
  L3_2[L6_2] = L4_2
  return L3_2
end
L8_1(L9_1, L10_1)
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MySQL
  L2_2 = L2_2.update
  L2_2 = L2_2.await
  L3_2 = "DELETE FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?"
  L4_2 = {}
  L5_2 = A1_2
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2 = L2_2(L3_2, L4_2)
  L2_2 = L2_2 > 0
  if not L2_2 then
    L3_2 = debugprint
    L4_2 = "removeMemberFromAlbum: failed to remove member from album"
    L5_2 = A0_2
    L6_2 = A1_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = false
    return L3_2
  end
  L3_2 = MySQL
  L3_2 = L3_2.scalar
  L3_2 = L3_2.await
  L4_2 = "SELECT COUNT(1) FROM phone_photo_album_members WHERE album_id = ?"
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = L2_1
  L5_2 = A1_2
  function L6_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3
    if A1_3 then
      L2_3 = TriggerClientEvent
      L3_3 = "phone:photos:removeMemberFromAlbum"
      L4_3 = A1_3
      L5_3 = A1_2
      L6_3 = A0_2
      L2_3(L3_3, L4_3, L5_3, L6_3)
    end
  end
  L4_2(L5_2, L6_2)
  if 0 == L3_2 then
    L4_2 = MySQL
    L4_2 = L4_2.update
    L4_2 = L4_2.await
    L5_2 = "UPDATE phone_photo_albums SET shared = 0 WHERE id = ?"
    L6_2 = {}
    L7_2 = A1_2
    L6_2[1] = L7_2
    L4_2(L5_2, L6_2)
  end
  L4_2 = GetSourceFromNumber
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = TriggerClientEvent
    L6_2 = "phone:photos:removeMemberFromAlbum"
    L7_2 = L4_2
    L8_2 = A1_2
    L9_2 = A0_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
  L5_2 = true
  return L5_2
end
L9_1 = BaseCallback
L10_1 = "camera:removeMemberFromAlbum"
function L11_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT 1 FROM phone_photo_albums WHERE id = ? AND phone_number = ?"
  L6_2 = {}
  L7_2 = A3_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = debugprint
    L6_2 = "removeMemberFromAlbum: not the owner of the album"
    L7_2 = A1_2
    L8_2 = A3_2
    L5_2(L6_2, L7_2, L8_2)
    return
  end
  L5_2 = L8_1
  L6_2 = A2_2
  L7_2 = A3_2
  return L5_2(L6_2, L7_2)
end
L9_1(L10_1, L11_1)
L9_1 = BaseCallback
L10_1 = "camera:leaveSharedAlbum"
function L11_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = L8_1
  L4_2 = A1_2
  L5_2 = A2_2
  L3_2(L4_2, L5_2)
  L3_2 = true
  return L3_2
end
L9_1(L10_1, L11_1)
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = GetEquippedPhoneNumber
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetEquippedPhoneNumber
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L3_2 or not L4_2 then
    L5_2 = debugprint
    L6_2 = "HandleAcceptAirShareAlbum: senderPhoneNumber/recipientPhoneNumber not found"
    L7_2 = L3_2
    L8_2 = L4_2
    L5_2(L6_2, L7_2, L8_2)
    return
  end
  L5_2 = MySQL
  L5_2 = L5_2.scalar
  L5_2 = L5_2.await
  L6_2 = "SELECT 1 FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?"
  L7_2 = {}
  L8_2 = A2_2
  L9_2 = L4_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    L6_2 = debugprint
    L7_2 = "HandleAcceptAirShareAlbum: recipient is already a member of the album"
    L8_2 = L3_2
    L9_2 = L4_2
    L10_2 = A2_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
    return
  end
  L6_2 = MySQL
  L6_2 = L6_2.scalar
  L6_2 = L6_2.await
  L7_2 = "SELECT 1 FROM phone_photo_albums WHERE id = ? AND phone_number = ?"
  L8_2 = {}
  L9_2 = A2_2
  L10_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2 = L6_2(L7_2, L8_2)
  if not L6_2 then
    L7_2 = debugprint
    L8_2 = "HandleAcceptAirShareAlbum: sender is not the owner of the album"
    L9_2 = L3_2
    L10_2 = L4_2
    L11_2 = A2_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
    return
  end
  L7_2 = MySQL
  L7_2 = L7_2.update
  L7_2 = L7_2.await
  L8_2 = "UPDATE phone_photo_albums SET shared = 1 WHERE id = ?"
  L9_2 = {}
  L10_2 = A2_2
  L9_2[1] = L10_2
  L7_2(L8_2, L9_2)
  L7_2 = L3_1
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L8_2 = debugprint
    L9_2 = "HandleAcceptAirShareAlbum: albumData not found"
    L10_2 = L3_2
    L11_2 = L4_2
    L12_2 = A2_2
    L8_2(L9_2, L10_2, L11_2, L12_2)
    return
  end
  L8_2 = L2_1
  L9_2 = A2_2
  function L10_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3
    if A1_3 then
      L2_3 = A0_2
      if A1_3 ~= L2_3 then
        L2_3 = TriggerClientEvent
        L3_3 = "phone:photos:addMemberToAlbum"
        L4_3 = A1_3
        L5_3 = A2_2
        L6_3 = L4_2
        L2_3(L3_3, L4_3, L5_3, L6_3)
      end
    end
  end
  L8_2(L9_2, L10_2)
  L8_2 = MySQL
  L8_2 = L8_2.insert
  L9_2 = "INSERT INTO phone_photo_album_members (album_id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?"
  L10_2 = {}
  L11_2 = A2_2
  L12_2 = L4_2
  L13_2 = L4_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L8_2(L9_2, L10_2)
  L8_2 = TriggerClientEvent
  L9_2 = "phone:photos:addSharedAlbum"
  L10_2 = A0_2
  L11_2 = L7_2
  L8_2(L9_2, L10_2, L11_2)
end
HandleAcceptAirShareAlbum = L9_1
