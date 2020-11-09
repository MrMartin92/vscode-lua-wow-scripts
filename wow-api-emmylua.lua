local folder_path = "/home/tobias/Downloads/9.0.1.36372/Blizzard_APIDocumentation/"
local result_folder = "../vscode-lua-wow/API/"

-- Dummys ----------------------------------------------------------------------

APIDocumentation = {}

function CreateFromMixins(...)
    return APIDocumentation
end

function APIDocumentation:OnLoad(...)
end

--------------------------------------------------------------------------------

function ends_with(string, string_end)
    return string.sub(string, #string-#string_end+1) == string_end
end

function is_lua_file(path)
    return ends_with(path, ".lua")
end

function is_xml_file(path)
    return ends_with(path, ".xml")
end

function is_dir(path)
    return ends_with(path, "/")
end

function mkdir(path)
    os.execute("mkdir -p "..path)
end

--------------------------------------------------------------------------------
function get_folder_content(path)
    local content = {}

    local f = assert (io.popen ("ls -p "..path))

    for line in f:lines() do
        local full_path = path..line
        if is_dir(full_path) then
            for _,sub_line in ipairs(get_folder_content(full_path)) do
                table.insert(content, sub_line)
            end  
        else
            table.insert(content, path..line)
        end   
    end -- for loop
  
    f:close()

    return content
end

function fix_type(type)
    if type == "bool" then
        return "boolean"
    end

    return type
end

function write_function_emmylua(f, namespace, func)
    -- Insert link to wowpedia
    f:write("---[Wowpedia documentation](https://wow.gamepedia.com/API_")
    if namespace then
        f:write(namespace..".")
    end
    f:write(func.Name..")\n")

    -- Insert all arguments
    if func.Arguments then
        for key, value in pairs(func.Arguments) do
            f:write("---@param "..value.Name.." "..fix_type(value.Type).."\n")
        end
    end

    -- Insert all return values
    if func.Returns then
        f:write("---@return ")
        for i = 1, #func.Returns do
            if i > 1 then
                f:write(", ")
            end
            f:write(fix_type(func.Returns[i].Type))
        end
        
        -- Comment return values
        f:write(" @")
        for i = 1, #func.Returns do
            if i > 1 then
                f:write(", ")
            end
            f:write(func.Returns[i].Name)
        end
        f:write("\n")
    end
end

function write_function_prototype(f, namespace, func)
    -- Create function
    f:write("function ")
    if namespace then
        f:write(namespace..".")
    end
    f:write(func.Name.."(")
    -- Insert all arguments
    if func.Arguments then
        for i = 1, #func.Arguments do
            if i > 1 then
                f:write(", ")
            end
            f:write(func.Arguments[i].Name)
        end
    end
    f:write(")\n")
    f:write("end\n\n")
end

function write_enum(f, namepsace, enum)
    f:write("---@alias "..enum.Name.." number")
    for key, value in pairs(enum.Fields) do
        f:write("|\"enum."..enum.Name.."."..value.Name.."\"")
    end
    f:write("\n")
    for key, value in pairs(enum.Fields) do
        f:write("enum."..enum.Name.."."..value.Name.." = "..value.EnumValue.."\n")
    end
    f:write("\n\n")
end

function write_structure(f, namespace, structure)
    f:write("---@class "..structure.Name.."\n")
    for key, value in pairs(structure.Fields) do
        f:write("---@field public "..value.Name.." "..fix_type(value.Type).."\n")
    end
    f:write(structure.Name.." = {}\n\n")
end

function APIDocumentation:AddDocumentationTable(target)
    if target.Name == nil then
        return
    end

    local f = io.open(result_folder..target.Name..".lua", "w+")
    
    if target.Namespace then
        f:write("---@class "..target.Namespace.."\n")
        f:write(target.Namespace .. " = {}\n\n")
    end

    for key, value in pairs(target.Functions) do
        write_function_emmylua(f, target.Namespace, value)
        write_function_prototype(f, target.Namespace, value)
    end

    for key, value in pairs(target.Tables) do
        if value.Type == "Structure" then
            write_structure(f, target.Namespace, value)
        elseif value.Type == "Enumeration" then
            write_enum(f, target.namespace, value)
        end
    end

    f:close()
end

mkdir(result_folder)
local files = get_folder_content(folder_path)

for _,file in ipairs(files) do
        if is_lua_file(file) then
            dofile(file)
        end
end