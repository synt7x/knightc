local recommendation = {
    binary = package.cpath:match("%p[\\|/]?%p(%a+)")
}

function recommendation:format()
    if self.binary == 'dll' then
        return 'pe'
    else
        return 'elf'
    end
end

function recommendation:target()
    if self.binary == 'so' then
        return 'x86'
    elseif self.binary == 'dll' then
        return 'x64'
    elseif self.binary == 'dylib' then
        return 'aarch64'
    else
        return 'arm'
    end
end

function recommendation:output()
    if self.binary == 'dll' then
        return 'a.exe'
    else
        return 'a.out'
    end
end

return recommendation