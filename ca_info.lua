local BOOL_PROPERTIES = { "Primary" }
local INT_PROPERTIES = { "PCID", "RSRP", "RSRQ", "RSSI", "RSSNR" }

local function to_snake_case(str)
    return str:match("^%s*(.-)%s*$"):gsub(" ", "_"):lower()
end

local function is_bool_property(key)
    return table.concat(BOOL_PROPERTIES):find(key) ~= nil
end

local function is_int_property(key)
    return table.concat(INT_PROPERTIES):find(key) ~= nil
end

local function parse_ca_info(output)
    local ca_entries = {}
    local current_ca_data = {}

    for line in output:gmatch("[^\r\n]+") do

        if line:match("^CA %d+") then
            if next(current_ca_data) then
                table.insert(ca_entries, current_ca_data)
                current_ca_data = {}
            end
        else
            for key_value_pair in line:gmatch("[^|]+") do
                local key, value = key_value_pair:match("([^:]+):%s*(.+)")

                if key and value then
                    key = to_snake_case(key)
                    value = value:match("^%s*(.-)%s*$")

                    if is_bool_property(key) then
                        value = value == "1"
                    elseif is_int_property(key) then
                        value = tonumber(value)
                    end

                    current_ca_data[key] = value
                end
            end
        end
    end

    if next(current_ca_data) then
        table.insert(ca_entries, current_ca_data)
    end

    return ca_entries
end

local function get_cli_output()
    local handle = io.popen("gsmctl --cainfo")
    local output = handle:read("*a")
    handle:close()
    return output
end


function handle_data_request()
    return {
        ca_info = parse_ca_info(get_cli_output()),
        timestamp = os.time()
    }
end
