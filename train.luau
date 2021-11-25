-- Converted using Mokiros's Model to Script Version 3
-- Converted string size: 2292 characters


local function Decode(str)
    local StringLength = #str

    -- Base64 decoding
    do
        local decoder = {}
        for b64code, char in pairs(('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='):split('')) do
            decoder[char:byte()] = b64code-1
        end
        local n = StringLength
        local t,k = table.create(math.floor(n/4)+1),1
        local padding = str:sub(-2) == '==' and 2 or str:sub(-1) == '=' and 1 or 0
        for i = 1, padding > 0 and n-4 or n, 4 do
            local a, b, c, d = str:byte(i,i+3)
            local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
            t[k] = string.char(bit32.extract(v,16,8),bit32.extract(v,8,8),bit32.extract(v,0,8))
            k = k + 1
        end
        if padding == 1 then
            local a, b, c = str:byte(n-3,n-1)
            local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
            t[k] = string.char(bit32.extract(v,16,8),bit32.extract(v,8,8))
        elseif padding == 2 then
            local a, b = str:byte(n-3,n-2)
            local v = decoder[a]*0x40000 + decoder[b]*0x1000
            t[k] = string.char(bit32.extract(v,16,8))
        end
        str = table.concat(t)
    end

    local Position = 1
    local function Parse(fmt)
        local Values = {string.unpack(fmt,str,Position)}
        Position = table.remove(Values)
        return table.unpack(Values)
    end

    local Settings = Parse('B')
    local Flags = Parse('B')
    Flags = {
        --[[ValueIndexByteLength]] bit32.extract(Flags,6,2)+1,
        --[[InstanceIndexByteLength]] bit32.extract(Flags,4,2)+1,
        --[[ConnectionsIndexByteLength]] bit32.extract(Flags,2,2)+1,
        --[[MaxPropertiesLengthByteLength]] bit32.extract(Flags,0,2)+1,
        --[[Use Double instead of Float]] bit32.band(Settings,0b1) > 0
    }

    local ValueFMT = ('I'..Flags[1])
    local InstanceFMT = ('I'..Flags[2])
    local ConnectionFMT = ('I'..Flags[3])
    local PropertyLengthFMT = ('I'..Flags[4])

    local ValuesLength = Parse(ValueFMT)
    local Values = table.create(ValuesLength)
    local CFrameIndexes = {}

    local ValueDecoders = {
        --!!Start
        [1] = function(Modifier)
            return Parse('s'..Modifier)
        end,
        --!!Split
        [2] = function(Modifier)
            return Modifier ~= 0
        end,
        --!!Split
        [3] = function()
            return Parse('d')
        end,
        --!!Split
        [4] = function(_,Index)
            table.insert(CFrameIndexes,{Index,Parse(('I'..Flags[1]):rep(3))})
        end,
        --!!Split
        [5] = {CFrame.new,Flags[5] and 'dddddddddddd' or 'ffffffffffff'},
        --!!Split
        [6] = {Color3.fromRGB,'BBB'},
        --!!Split
        [7] = {BrickColor.new,'I2'},
        --!!Split
        [8] = function(Modifier)
            local len = Parse('I'..Modifier)
            local kpts = table.create(len)
            for i = 1,len do
                kpts[i] = ColorSequenceKeypoint.new(Parse('f'),Color3.fromRGB(Parse('BBB')))
            end
            return ColorSequence.new(kpts)
        end,
        --!!Split
        [9] = function(Modifier)
            local len = Parse('I'..Modifier)
            local kpts = table.create(len)
            for i = 1,len do
                kpts[i] = NumberSequenceKeypoint.new(Parse(Flags[5] and 'ddd' or 'fff'))
            end
            return NumberSequence.new(kpts)
        end,
        --!!Split
        [10] = {Vector3.new,Flags[5] and 'ddd' or 'fff'},
        --!!Split
        [11] = {Vector2.new,Flags[5] and 'dd' or 'ff'},
        --!!Split
        [12] = {UDim2.new,Flags[5] and 'di2di2' or 'fi2fi2'},
        --!!Split
        [13] = {Rect.new,Flags[5] and 'dddd' or 'ffff'},
        --!!Split
        [14] = function()
            local flags = Parse('B')
            local ids = {"Top","Bottom","Left","Right","Front","Back"}
            local t = {}
            for i = 0,5 do
                if bit32.extract(flags,i,1)==1 then
                    table.insert(t,Enum.NormalId[ids[i+1]])
                end
            end
            return Axes.new(unpack(t))
        end,
        --!!Split
        [15] = function()
            local flags = Parse('B')
            local ids = {"Top","Bottom","Left","Right","Front","Back"}
            local t = {}
            for i = 0,5 do
                if bit32.extract(flags,i,1)==1 then
                    table.insert(t,Enum.NormalId[ids[i+1]])
                end
            end
            return Faces.new(unpack(t))
        end,
        --!!Split
        [16] = {PhysicalProperties.new,Flags[5] and 'ddddd' or 'fffff'},
        --!!Split
        [17] = {NumberRange.new,Flags[5] and 'dd' or 'ff'},
        --!!Split
        [18] = {UDim.new,Flags[5] and 'di2' or 'fi2'},
        --!!Split
        [19] = function()
            return Ray.new(Vector3.new(Parse(Flags[5] and 'ddd' or 'fff')),Vector3.new(Parse(Flags[5] and 'ddd' or 'fff')))
        end
        --!!End
    }

    for i = 1,ValuesLength do
        local TypeAndModifier = Parse('B')
        local Type = bit32.band(TypeAndModifier,0b11111)
        local Modifier = (TypeAndModifier - Type) / 0b100000
        local Decoder = ValueDecoders[Type]
        if type(Decoder)=='function' then
            Values[i] = Decoder(Modifier,i)
        else
            Values[i] = Decoder[1](Parse(Decoder[2]))
        end
    end

    for i,t in pairs(CFrameIndexes) do
        Values[t[1]] = CFrame.fromMatrix(Values[t[2]],Values[t[3]],Values[t[4]])
    end

    local InstancesLength = Parse(InstanceFMT)
    local Instances = {}
    local NoParent = {}

    for i = 1,InstancesLength do
        local ClassName = Values[Parse(ValueFMT)]
        local obj
        local MeshPartMesh,MeshPartScale
        if ClassName == "UnionOperation" then
            obj = DecodeUnion(Values,Flags,Parse)
            obj.UsePartColor = true
        elseif ClassName:find("Script") then
            obj = Instance.new("Folder")
            --Script(obj,ClassName=='ModuleScript')
        elseif ClassName == "MeshPart" then
            obj = Instance.new("Part")
            MeshPartMesh = Instance.new("SpecialMesh")
            MeshPartMesh.MeshType = Enum.MeshType.FileMesh
            MeshPartMesh.Parent = obj
        else
            obj = Instance.new(ClassName)
        end
        local Parent = Instances[Parse(InstanceFMT)]
        local PropertiesLength = Parse(PropertyLengthFMT)
        local AttributesLength = Parse(PropertyLengthFMT)
        Instances[i] = obj
        for i = 1,PropertiesLength do
            local Prop,Value = Values[Parse(ValueFMT)],Values[Parse(ValueFMT)]

            -- ok this looks awful
            if MeshPartMesh then
                if Prop == "MeshId" then
                    MeshPartMesh.MeshId = Value
                    continue
                elseif Prop == "TextureID" then
                    MeshPartMesh.TextureId = Value
                    continue
                elseif Prop == "Size" then
                    if not MeshPartScale then
                        MeshPartScale = Value
                    else
                        MeshPartMesh.Scale = Value / MeshPartScale
                    end
                elseif Prop == "MeshSize" then
                    if not MeshPartScale then
                        MeshPartScale = Value
                        MeshPartMesh.Scale = obj.Size / Value
                    else
                        MeshPartMesh.Scale = MeshPartScale / Value
                    end
                    continue
                end
            end

            obj[Prop] = Value
        end
        if MeshPartMesh then
            if MeshPartMesh.MeshId=='' then
                if MeshPartMesh.TextureId=='' then
                    MeshPartMesh.TextureId = 'rbxasset://textures/meshPartFallback.png'
                end
                MeshPartMesh.Scale = obj.Size
            end
        end
        for i = 1,AttributesLength do
            obj:SetAttribute(Values[Parse(ValueFMT)],Values[Parse(ValueFMT)])
        end
        if not Parent then
            table.insert(NoParent,obj)
        else
            obj.Parent = Parent
        end
    end

    local ConnectionsLength = Parse(ConnectionFMT)
    for i = 1,ConnectionsLength do
        local a,b,c = Parse(InstanceFMT),Parse(ValueFMT),Parse(InstanceFMT)
        Instances[a][Values[b]] = Instances[c]
    end

    return NoParent
end


local Objects = Decode('AAB4IQhNZXNoUGFydCEETmFtZSEKVHJhaW4gbWVzaCEGQ0ZyYW1lBAtvcCEITWF0ZXJpYWwDAAAAAAAAkUAhC09yaWVudGF0aW9uCgAAAAAAALTCAAAAACEIUG9zaXRpb24KhbihRMZRA0EizatDIQhSb3RhdGlvbiEEU2l6ZQqm4ixBxlGDQbneWUIhBk1lc2hJZCEW'
    ..'cmJ4YXNzZXRpZDovLzc0MzU3NjUzNyEITWVzaFNpemUKAABIQnfBiUK01W1DIQlUZXh0dXJlSUQhF3JieGFzc2V0aWQ6Ly8xNDE2MDI0MDA2IQRXZWxkIQJDMARxcnAhBVBhcnQxIQVNb2RlbCEZVW5pdGVkIFJhaWwgU3RyYWlnaHQgTG9uZyEKV29ybGRQaXZvdARz'
    ..'b3AhBFBhcnQhAUIhCEFuY2hvcmVkIiENQm90dG9tU3VyZmFjZQMAAAAAAAAAACEKQnJpY2tDb2xvcgfAAAQrb3AhBUNvbG9yBmlAKCEYQ3VzdG9tUGh5c2ljYWxQcm9wZXJ0aWVzEDMzsz4AAIA/AAAAAAAAgD8AAIA/AwAAAAAAAIBACtJI2UNTzUw+RuarQwoAAJBB'
    ..'zczMPgAAgD8hClRvcFN1cmZhY2UhCUJsb2NrTWVzaCELT2JqZWN0VmFsdWUhBE5leHQhAUEENHRwCgAAAAAAALRCAAAAAAqayJNDU81MPkXmq0MhBFJhaWwEOnJwEDMzMz8AAIA/AAAAAAAAgD8AAIA/AwAAAAAAAHFACgAAAAAAADRDAAAAAAq3iLZDGQCAP0JmqUMK'
    ..'AAA0wwAAAAAAADTDCgAADEOamZk/AAAAQCELU3BlY2lhbE1lc2ghBVNjYWxlCgAAekQAAIA/AACAPiEITWVzaFR5cGUDAAAAAAAAGEAhB1RleHR1cmUhCFRleHR1cmUxISlodHRwOi8vd3d3LnJvYmxveC5jb20vYXNzZXQvP2lkPTE1MTMxNDc4OCENU3R1ZHNQZXJU'
    ..'aWxlVQMAAAAAAAA0QCENU3R1ZHNQZXJUaWxlVgMAAAAAAADwPyEIVGV4dHVyZTIhBEZhY2UDAAAAAAAAAEAhCFRleHR1cmUzISlodHRwOi8vd3d3LnJvYmxveC5jb20vYXNzZXQvP2lkPTE1MTMxNDgwNQMAAAAAAAAkQAMAAAAAAADgPyEKTWFudWFsV2VsZCEdUmFp'
    ..'bC10by1Db252ZXlvciBTdHJvbmcgSm9pbnQEdXJvIQJDMQR2dHIhBVBhcnQwIQNUaWUH/gMEXG9wBn+OZBBmZmY/AACAPwAAAAAAAIA/AACAPwMAAAAAAACUQApQQrNDU81MPkbmq0MKAACwQc3MzD6aGRdDCjMzsz8AAIA/AAB6RCEWcmJ4YXNzZXRpZDovLzE1MTMx'
    ..'NDY3MQMAAAAAAAA/QAMAAAAAAIA9QARjd3AKtIi2QxkAgD9HZq5DBHhvdyEIQ29udmV5b3IH6wMEaW9wBhEREQq0iLZD3v/PP6hsrkMKnJnZP83MTD0EAAxDIQxUcmFuc3BhcmVuY3khBlNjcmlwdARub3AKtYi2Q97/zz+qbKlDCgAAAAAAAAAAAACAPwoAAAAAAACA'
    ..'PwAAAAAKnLGRQheFAkHk4UhDCgAAgL8AAAAAAAAAAAq2iLZDQjNTP0bmq0MKAAAAAAAAAAAAAIC/CgAAjMKamRk/AACAPwoAaIa/gMLMvAgAjMIKAACAPwAAAAAAAAAACgA+cz+Awsy8AACMQhwBAAoAAgMEBQYHCAkKCwwJDQ4PEBESExQVAQEAFhcZAAIAAhobHB0D'
    ..'DQACHh8gISIjJAQlJicoKQYqCAkKKwwJDSwtIi4EAAAvBAEAAjAdAw0AAjEfICEiIyQEMiYnKCkGKggzCjQMMw0sLSIuBwAALwcBAAIwHQMLAAI1HyAhIgQ2KDcGOAg5CjoMOw08LSI9CgIAPj9AQUIKBAACQ0JERUZHSEIKBQACSUpLQkRFRkdIQgoFAAJMSkhCTUVO'
    ..'R09QCgMAAlEWUlNUHQMNAAJWHyAhIiNXBFgmWShaBlsICQpcDAkNXS0iPRACAD5eQEFCEAQASkhCX0VgR2EdAwkAAjUfICEiBGIoNwY4CmMNPC0iQhMEAAJDQkRFRkdIQhMFAAJJSktCREVGR0hCEwUAAkxKSEJNRU5HT1ATAwACURZSU2Q9EwIAPj9AQR0DCwACZR8g'
    ..'I2YEZyZoCAkKaQwJDWotImtIbBkAAB0DCwACZR8gI2YEbSZoCAkKbgwJDWotImtIbBsAAAUCGAEPVQoPGBsXVRMXGBk=')
for _,obj in pairs(Objects) do
    obj.Parent = script or workspace
end
local Objects = Decode('AACCIQVNb2RlbCEKV29ybGRQaXZvdAR5enshCE1lc2hQYXJ0IQROYW1lIQZCIHVuaXQhBkNGcmFtZQQQenshCkNhbkNvbGxpZGUCIQhNYXRlcmlhbAMAAAAAAICUQCELT3JpZW50YXRpb24KAAAAAAAAtEIAAAAAIQhQb3NpdGlvbgrPpKhE3PAQQTnpq0MhCFJvdGF0'
    ..'aW9uIQRTaXplCtJNT0Hc8JBBMatkQiEGTWVzaElkIRdyYnhhc3NldGlkOi8vMzYxNzgzMjQwMiEITWVzaFNpemUKBoSOP7Fvzz8yuKVAIQlUZXh0dXJlSUQhFnJieGFzc2V0aWQ6Ly82NzgwMjQzNzAhDldlbGRDb25zdHJhaW50IQVQYXJ0MCEFUGFydDEhBVNvdW5k'
    ..'IQZMb29wZWQiIQdQbGF5aW5nIQdTb3VuZElkIRdyYnhhc3NldGlkOi8vMjM2NzUyMDU2NiEGVm9sdW1lAwAAAAAAAPA/IQJGMwQnensKSJyhRNzwEEE56atDCj5LT0GI8JBBiKtkQiEWcmJ4YXNzZXRpZDovLzY3ODAyNDMzNQq8iRVBDh1RQVj1JEIhBFBhcnQhDUJv'
    ..'dHRvbVN1cmZhY2UDAAAAAAAAAAAhCkJyaWNrQ29sb3IH6QMENXx7IQVDb2xvcgb4+PgDAAAAAAAAckAKAAAAAAAANEMAAAAACvh6nkR36F5BKuurQwoAADTDAAAAAAAANMMKg/PBP7J02D/edNI/IQpUb3BTdXJmYWNlIQVTaGFwZQMAAAAAAAAAQCEMQm9keVZlbG9j'
    ..'aXR5IQhNYXhGb3JjZQoAAIB/AACAfwAAgH8hAVADAAAAAABAv0AhCFZlbG9jaXR5CgAASEIAAACAAAAAgCEGQ2FtZXJhIQ9UaHVtYm5haWxDYW1lcmEEfX5/IRNEaWFnb25hbEZpZWxkT2ZWaWV3A19aCMXHVzBAIQtGaWVsZE9mVmlldwMAAAAAAAA+QCEFRm9jdXME'
    ..'gIF7IRJNYXhBeGlzRmllbGRPZlZpZXchC0JveENhcl9PcGVuBE6CewpJzbVE7rXvQHD8q0MKt6pIQe61b0E23lRCIRdyYnhhc3NldGlkOi8vMTQ4OTY2NDM2NAoHpRBDml0rQx0uGEQhF3JieGFzc2V0aWQ6Ly8xNDg5NjYzMDgxBFSCewqqVq9E7rXvQHD8q0MEVoJ7'
    ..'Cn/AwkTute9AcPyrQwRYgnsKcrzPRO6170Bw/KtDBFqCewoeN8lE7rXvQHD8q0MEXIJ7Cjin3ETute9AcPyrQwRegnsKjCzjRO6170Bv/KtDBGCCewpumulE7rXvQG/8q0MEYoJ7Cpkw1kTute9AcPyrQwRkgnsKDhHwRO6170Bv/KtDBGaCewpilvZE7rXvQG/8q0ME'
    ..'aIJ7Cp5SvETute9AcPyrQwRqgnsKhM0BRf2170Bx/KtDBGyCewq0Ff1E/bXvQHH8q0MEboJ7CjAOBUX9te9AcfyrQwRwgnsK2lAIRf2170Bx/KtDBHKCewrojwtF/bXvQHH8q0MEdIJ7CpHSDkX9te9AcfyrQwR2gnsKPBMSRf2170Bx/KtDBHiCewrmVRVF/bXvQHH8'
    ..'q0MKiiClROzwEEE56atDCgAAAAAAAAAAAACAvwoAAAAAAACAPwAAAAAKAACAvwAAAAAAAAAACvnIZkNwINtAnPOFwgrPfFq/AAAAMeVpBb8KJf3IvFa3fz+jkyQ9CnG+ZUMbHdhAoYqCwgoAAIA/AAAAAAAAAAAKAOBMsgAAAAAAAIC/QgEAAQACAwQBCwAFBgcICQoL'
    ..'DA0ODxARDhITFBUWFxgZGgIAAB0CBAAeHyAfISIjJAQBCwAFJQcmCQoLDA0ODycRDhIoFCkWKhgZKwUMACwtLi8HMAkKMTILMw00DzURNhI3OC05OhoGAAAdBQQAHh8gHyEiIyQ7BQMAPD0+P0BBQgEGAAVDB0RFRkdISUpLSAQBCgAFTAdNCQoNDg9OEQ4STxRQFlEY'
    ..'Uh0LBAAeHyAfISIjJBoLAAAaCwAABAEKAAVMB1MJCg0OD1QRDhJPFFAWURhSHQ8EAB4fIB8hIiMkGg8AAAQBCgAFTAdVCQoNDg9WEQ4STxRQFlEYUh0SBAAeHyAfISIjJBoSAAAEAQoABUwHVwkKDQ4PWBEOEk8UUBZRGFIdFQQAHh8gHyEiIyQEAQoABUwHWQkKDQ4P'
    ..'WhEOEk8UUBZRGFIdFwQAHh8gHyEiIyQaFwAAGhcAAAQBCgAFTAdbCQoNDg9cEQ4STxRQFlEYUh0bBAAeHyAfISIjJAQBCgAFTAddCQoNDg9eEQ4STxRQFlEYUh0dBAAeHyAfISIjJBodAAAEAQoABUwHXwkKDQ4PYBEOEk8UUBZRGFIdIAQAHh8gHyEiIyQaIAAAGiAA'
    ..'AAQBCgAFTAdhCQoNDg9iEQ4STxRQFlEYUh0kBAAeHyAfISIjJBokAAAaJAAABAEKAAVMB2MJCg0OD2QRDhJPFFAWURhSHSgEAB4fIB8hIiMkBAEKAAVMB2UJCg0OD2YRDhJPFFAWURhSHSoEAB4fIB8hIiMkGioAAAQBCgAFTAdnCQoNDg9oEQ4STxRQFlEYUh0tBAAe'
    ..'HyAfISIjJAQBCgAFTAdpCQoNDg9qEQ4STxRQFlEYUh0vBAAeHyAfISIjJBovAAAEAQoABUwHawkKDQ4PbBEOEk8UUBZRGFIdMgQAHh8gHyEiIyQEAQoABUwHbQkKDQ4PbhEOEk8UUBZRGFIdNAQAHh8gHyEiIyQEAQoABUwHbwkKDQ4PcBEOEk8UUBZRGFIdNgQAHh8g'
    ..'HyEiIyQaNgAABAEKAAVMB3EJCg0OD3IRDhJPFFAWURhSHTkEAB4fIB8hIiMkBAEKAAVMB3MJCg0OD3QRDhJPFFAWURhSHTsEAB4fIB8hIiMkGjsAAAQBCgAFTAd1CQoNDg92EQ4STxRQFlEYUh0+BAAeHyAfISIjJAQBCgAFTAd3CQoNDg94EQ4STxRQFlEYUh1ABAAe'
    ..'HyAfISIjJBpAAAAkAxsCAxwFBxsGBxwFDRsLDRwPDhsLDhwtERsPERwCFBsSFBwtGRsXGRwSGhsXGhwVHxsdHxwbIhsgIhwoIxsgIxwdJhskJhwVJxskJxwbLBsqLBwoMRsvMRwyOBs2OBw0PRs7PRw5QhtAQhw+')
for _,obj in pairs(Objects) do
    obj.Parent = script
end

local tm=script["Model"]
tm.ThumbnailCamera:Destroy()
for i,v in pairs(tm:GetChildren()) do
    v.Anchored = true
end
tm.Parent=nil
Sound0 = Instance.new("Sound")
Sound1 = Instance.new("Sound")
Sound2 = Instance.new("Sound")
Sound3 = Instance.new("Sound")
Sound4 = Instance.new("Sound")
Sound5 = Instance.new("Sound")
Sound6 = Instance.new("Sound")
Sound0.Name = "Brake"
Sound0.Parent = mas
Sound0.Pitch = 0.8299999833107
Sound0.PlaybackSpeed = 0.8299999833107
Sound0.SoundId = "rbxassetid://253748163"
Sound0.Volume = 1
Sound1.Name = "Buzz"
Sound1.Parent = mas
Sound1.Looped = true
Sound1.EmitterSize = 40
Sound1.MinDistance = 40
Sound1.Playing = true
Sound1.SoundId = "rbxassetid://484973595"
Sound1.Volume = 0
Sound2.Name = "Clattering"
Sound2.Parent = mas
Sound2.Looped = true
Sound2.Playing = true
Sound2.SoundId = "rbxassetid://891395522"
Sound2.Volume = 1
Sound3.Name = "Compressor"
Sound3.Parent = mas
Sound3.EmitterSize = 40
Sound3.MinDistance = 40
Sound3.SoundId = "rbxassetid://554208370"
Sound3.Volume = 1
Sound4.Name = "Ding"
Sound4.Parent = mas
Sound4.Pitch = 0.94999998807907
Sound4.PlaybackSpeed = 0.94999998807907
Sound4.SoundId = "rbxassetid://403408927"
Sound4.Volume = 1
Sound5.Name = "Gong"
Sound5.Parent = mas
Sound5.SoundId = "rbxassetid://326141375"
Sound5.Volume = 2
Sound6.Name = "Release"
Sound6.Parent = mas
Sound6.Pitch = 1.25
Sound6.PlaybackSpeed = 1.25
Sound6.SoundId = "rbxassetid://202615402"
Sound6.Volume = 1
local function Move(Train, CF)
    for i,v in pairs(Train:GetChildren()) do
        v.CFrame *= CF
    end
end
function NewTrain()
    task.spawn(function()
        local Train = tm:Clone()
        Train.Parent = script
        local Sound0 = Instance.new("Sound")
        local Sound1 = Instance.new("Sound")
        Sound0.Name = "Buzz"
        Sound0.Parent = Train.F3
        Sound0.Looped = true
        Sound0.EmitterSize = 40
        Sound0.MinDistance = 40
        Sound0.Playing = true
        Sound0.SoundId = "rbxassetid://484973595"
        Sound0.Volume = 0
        Sound1.Name = "Clattering"
        Sound1.Parent = Train.F3
        Sound1.Looped = true
        Sound1.Playing = true
        Sound1.SoundId = "rbxassetid://891395522"
        Sound1.Volume = 10
        local Spd = 0
        for i = 0,1.4,0.01 do
            Spd += 0.1
            Move(Train, CFrame.new(0,0,-(1+Spd)))
            task.wait()
        end
        Sound1.Playing = false
        local Fake = Instance.new("Part",Train)
        Fake.Anchored = true
        Fake.CFrame = Train.F3.CFrame
        Fake.CanCollide = false
        Fake.Size = Vector3.new(10.805, 16.415, 54.468)
        Fake.Transparency = 0.7
        local Click = Instance.new('ClickDetector',Fake)
        Click.MaxActivationDistance = 9e9
        Click.MouseClick:Connect(function(Plr)
            local Seat = Train:FindFirstChild('Seat'.. Plr.Name)
            if not Seat then
                Seat = Instance.new("Seat",Train)
                Seat.Name="Seat".. Plr.Name
                local Weld = Instance.new("Weld", Seat)
                Weld.Part0,Weld.Part1 = Train.F3,Seat
            end
            Seat:Sit(Plr.Character.Humanoid)
            local AncestryChanged
            AncestryChanged = Seat.Parent.AncestryChanged:Connect(function()
                Seat:Destroy()
                Plr.Character:MoveTo(Vector3.new(0,10,0))
                AncestryChanged:Disconnect()
            end)
        end)
        Sound0.Playing = false
        for i = 1, 4 do
            local Honk = Sound5:Clone()
            Honk.Volume = 10
            Honk.Parent = Train.F3
            Honk.PlayOnRemove = true
            Honk:Destroy()
            wait(Sound5.TimeLength)
        end
        wait(24)
        for i = 1, 4 do
            local Honk = Sound5:Clone()
            Honk.Volume = 10
            Honk.Parent = Train.F3
            Honk.PlayOnRemove = true
            Honk:Destroy()
            wait(Sound5.TimeLength)
        end
        wait(3)
        Fake:Destroy()
        Click:Destroy()
        Sound1.Playing = true
        Sound0.Playing = true
        Spd = 0
        for i = 0,60,0.01 do
            Spd+=0.01
            Move(Train, CFrame.new(0,0,-(1+Spd)))
            task.wait()
        end
        Train:Destroy()
        
        delay(5,function()
            NewTrain()
        end)
    end)
end
NewTrain()
for i,v in pairs(script:GetDescendants()) do
    if v.Name == "Rail" then
        v.Mesh.Scale = Vector3.new(v.Mesh.Scale.X*3,v.Mesh.Scale.Y,v.Mesh.Scale.Z)
    elseif v.Name == "Tie" then
        v.Mesh.Scale = Vector3.new(1.4,1,1000*3)
    end
end
