local waywall          = require("waywall")
local requests         = require("ww_requests.init")

local NB_OVERLAY       = {}

local text_handle      = nil
local text_handle_bold = nil

local look             = {
    X = 500,
    Y = 410,
    color = "#FFFFFF",
    bold = true,
    size = 3,
}

-- which cache slot to use
local REQ_INDEX        = "stronghold_info"
local ENDPOINT         = "http://localhost:52533/api/v1/stronghold"


local function clear_text()
    if text_handle then
        text_handle:close()
        text_handle = nil
    end
    if text_handle_bold then
        text_handle_bold:close()
        text_handle_bold = nil
    end
end

local function draw_text(layout)
    local state = waywall.state()
    if not (state.screen == "inworld") then
        clear_text()
        return
    end
    print("layout")

    clear_text()
    text_handle = waywall.text(layout, { x = look.X, y = look.Y, color = look.color, size = look.size })
    if look.bold then
        text_handle_bold = waywall.text(layout, { x = look.X + 1, y = look.Y, color = look.color, size = look.size })
    end
end

local function render_from_data(data_sh)
    local sh = data_sh and data_sh.predictions and data_sh.predictions[1]
    if not sh then
        clear_text()
        return
    end

    -- Convert chunk -> overworld block coords (same convention you used before)
    local sh_ow_x = math.floor(16 * (sh.chunkX or 0) + 4)
    local sh_ow_z = math.floor(16 * (sh.chunkZ or 0) + 4)

    local player = data_sh and data_sh.playerPosition
    local in_nether = player and player.isInNether

    local layout
    if in_nether then
        local sh_nx = math.floor(sh_ow_x / 8)
        local sh_nz = math.floor(sh_ow_z / 8)
        layout = "(" .. sh_nx .. ", " .. sh_nz .. ")"
    else
        layout = "(" .. sh_ow_x .. ", " .. sh_ow_z .. ")"
    end

    draw_text(layout)
end

-- Call this on your polling/tick (whatever you already use to refresh overlays)
NB_OVERLAY.trigger_http_send = function()
    -- phase 1: start fetch (if not already pending)
    requests.trigger_http_send(ENDPOINT, REQ_INDEX)

    -- phase 2: try to read; if not ready, keep waiting
    local data = requests.receive_data(REQ_INDEX)
    if not data or data.error then
        return
    end

    print(data)

    render_from_data(data)
end

NB_OVERLAY.enable_overlay = function()
    NB_OVERLAY.trigger_http_send()
end

NB_OVERLAY.disable_overlay = function()
    clear_text()
end

return NB_OVERLAY
