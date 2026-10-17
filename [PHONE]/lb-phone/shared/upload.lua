

UploadMethods = {
    Custom = {
        Video = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", -- The field name (formData)
            headers = { -- headers to send when uploading
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", -- The path to the error value (res.success)
                value = false -- If the path is equal to this value, it's an error
            },
            success = {
                path = "url" -- The path to the video file (res.url)
            },
            suffix = "webm", -- Add a suffix to the url (not needed if you return the correct name)
        },
        Image = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", -- The field name (formData)
            headers = { -- headers to send when uploading
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", -- The path to the error value (res.success)
                value = false -- If the path is equal to this value, it's an error
            },
            success = {
                path = "url" -- The path to the image file (res.url)
            },
            suffix = "png", -- Add a suffix to the url (not needed if you return the correct name)
        },
        Audio = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", -- The field name (formData)
            headers = { -- headers to send when uploading
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", -- The path to the error value (res.success)
                value = false -- If the path is equal to this value, it's an error
            },
            success = {
                path = "url" -- The path to the audio file (res.url)
            },
            suffix = "mp3", -- Add a suffix to the url (not needed if you return the correct name)
        },
    },
    Fivemanage = {
        Default = {
            url = "PRESIGNED_URL",
            field = "file",
            success = {
                path = "data.url"
            },
            sendPlayer = "metadata"
        },
    },
    LBUpload = {
        Default = {
            url = "https://BASE_URL/lb-upload/",
            field = "file",
            headers = {
                ["Authorization"] = "CHANGEME"
            },
            error = {
                path = "success",
                value = false
            },
            success = {
                path = "link"
            },
            sendPlayer = "metadata"
        },
    },
    OldFivemanage = {
        Video = {
            url = "https://fmapi.net/api/v2/video",
            field = "file",
            headers = {
                ["Authorization"] = "API_KEY"
            },
            success = {
                path = "data.url"
            },
        },
        Image = {
            url = "https://fmapi.net/api/v2/image",
            field = "file",
            headers = {
                ["Authorization"] = "API_KEY"
            },
            success = {
                path = "data.url"
            }
        },
        Audio = {
            url = "https://fmapi.net/api/v2/audio",
            field = "file",
            headers = {
                ["Authorization"] = "API_KEY"
            },
            success = {
                path = "data.url"
            }
        },
    },
}
