local json = require('lib/json')
local frog = require('lib/frog')
local parser = require('src/frontend/parser')
local traversal = parser.traversal

local symbols = {}

function symbols.new(ast)
    local self = {}
    for name, value in pairs(symbols) do
        self[name] = value
    end

    self.map = {}
    self:walk(ast.body)
    self:reverse()

    return self.map
end

function symbols:add(identifier, parent, deps)
    local name = identifier.characters

    if self.map[name] then
        identifier.tag = self.map[name].tag
    else
        self.tag = (self.tag or 0) + 1
        self.map[name] = {
            tag = self.tag, types = {},
            deps = {}, revdeps = {},
            defs = {}, uses = {}
        }
    end

    if parent and parent.type == 'assignment' then
        table.insert(self.map[name].defs, parent)
    end

    table.insert(self.map[name].uses, identifier)

    if deps then
        for i, dep in ipairs(deps) do
            local dependant = dep.characters
            if dependant ~= name then
                if not self.map[dependant] then
                    self:add(dep)
                end
                
                if not self.map[name].deps[dependant] then
                    self.map[name].deps[dependant] = self.map[dependant].tag
                end
            end
        end
    end
end

function symbols:reverse()
    for name, symbol in pairs(self.map) do
        for dep, tag in pairs(symbol.deps) do
            local reference = self.map[dep]
            reference.revdeps[name] = symbol.tag
        end

        if #symbol.defs == 0 then
            frog:throw(
                symbol.uses[1].token,
                'No definition found for ' .. name,
                'Try checking the spelling or removing this identifier',
                'Symbols'
            )
        end

        symbol.uses = nil
    end
end

function symbols:collect(...)
    local collected = {}
    local args = {...} -- Collect varargs into a table

    for _, v in ipairs(args or {}) do
        if v and v.characters then
            table.insert(collected, v)
        elseif v then
            for _, v in ipairs(v) do
                table.insert(collected, v)
            end
        end
    end

    return collected
end

function symbols:deps(ast)
    if traversal.unary[ast.type] then
        return self:collect(
            self:deps(ast.argument)
        )
    elseif ast.type == 'identifier' then
        return self:collect({
            ast
        })
    elseif ast.type == 'assignment' then
        local val = self:deps(ast.value)
        return self:collect(
            self:deps(ast.name),
            val
        )
    elseif traversal.binary[ast.type] then
        return self:collect(
            self:deps(ast.left),
            self:deps(ast.right)
        )
    elseif ast.type == 'block' then
        return self:collect(
            self:deps(ast.body)
        )
    elseif ast.type == 'call' then
        return self:collect(
            self:deps(ast.name)
        )
    elseif ast.type == 'if' then
        return self:collect(
            self:deps(ast.condition),
            self:deps(ast.body),
            self:deps(ast.fallback)
        )
    elseif ast.type == 'while' then
        return self:collect(
            self:deps(ast.condition),
            self:deps(ast.body)
        )
    elseif ast.type == 'get' then
        return self:collect(
            self:deps(ast.argument),
            self:deps(ast.start),
            self:deps(ast.width)
        )
    elseif ast.type == 'set' then
        return self:collect(
            self:deps(ast.argument),
            self:deps(ast.start),
            self:deps(ast.width),
            self:deps(ast.value)
        )
    else
        return
    end
end

function symbols:walk(ast, parent)
    if traversal.binary[ast.type] then
        self:walk(ast.left, ast)
        self:walk(ast.right, ast)
    elseif traversal.unary[ast.type] then
        self:walk(ast.argument, ast)
    elseif ast.type == 'identifier' then
        self:add(ast, parent)
    elseif ast.type == 'assignment' then
        self:add(
            ast.name, ast,
            self:deps(ast.value)
        )
        self:walk(ast.value, ast)
    elseif ast.type == 'block' then
        self:walk(ast.body, ast)
    elseif ast.type == 'call' then
        self:walk(ast.name, ast)
    elseif ast.type == 'if' then
        self:walk(ast.condition, ast)
        self:walk(ast.body, ast)
        self:walk(ast.fallback, ast)
    elseif ast.type == 'while' then
        self:walk(ast.condition, ast)
        self:walk(ast.body, ast)
    elseif ast.type == 'get' then
        self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)
    elseif ast.type == 'set' then
        self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)
        self:walk(ast.value, ast)
    else
        return
    end

    return self.map
end

return symbols