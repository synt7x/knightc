return function(node)
    if node:test('string') then
        return node:accept('string')
    elseif node:test('number') then
        return node:accept('number')
    end
end