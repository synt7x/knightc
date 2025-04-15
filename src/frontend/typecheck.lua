local typecheck = {
    types = {
        ['null'] = 'null', ['number'] = 'number', ['string'] = 'string',
        ['array'] = 'array', ['boolean'] = 'boolean', ['block'] = 'block'
    }
}

local frog = require('lib/frog')
local json = require('lib/json')
local parser = require('src/frontend/parser')
local traversal = parser.traversal

function typecheck.new(symbols, ast)
    local self = {}
    for name, value in pairs(typecheck) do
        self[name] = value
    end

    self.symbols = symbols

    return self:work()
end

function typecheck:join(type1, type2)
    local overlap = {}
    for i, type in ipairs(type1) do overlap[type] = type end
    for i, type in ipairs(type2) do overlap[type] = type end

    local union = {}
    for i, type in pairs(overlap) do
        table.insert(union, type)
    end

    return union
end

function typecheck:equal(type1, type2)
    if #type1 ~= #type2 then return false end

    local set = {}
    for _, t in ipairs(type1) do set[t] = true end
    for _, t in ipairs(type2) do
        if not set[t] then return false end
    end

    return true
end

function typecheck:type(...)
    return { ... }
end

function typecheck:work()
    local worklist = {}
    for name, symbol in pairs(self.symbols) do
        table.insert(worklist, name)
    end

    while #worklist > 0 do
        local name = table.remove(worklist)
        local symbol = self.symbols[name]
        
        local inferred = {}
        for i, def in ipairs(symbol.defs) do
            local type = self:infer(def.value, ast)
            inferred = self:join(inferred, type)
        end

        if not self:equal(symbol.types, inferred) then
            symbol.types = inferred

            for dep, tag in pairs(symbol.revdeps) do
                table.insert(worklist, dep)
            end
        end
    end
end

function typecheck:infer(ast, parent)
    if not ast then
        frog:throw(
            parent.token, 
            string.format("Panic during typecheck, recieved nil child while walking node (%s)", parent.type),
            "Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)",
            "Fatal"
        )

        os.exit(1)
    end

    if traversal.binary[ast.type] then
        self:infer(ast.left, ast)
        return self:infer(ast.right, ast)
    elseif ast.type == 'output' then
        self:infer(ast.argument, ast)
        return self:type(self.types.null)
    elseif ast.type == 'dump' then
        self:infer(ast.argument, ast)
        return self:type(self.types.null)
    elseif ast.type == 'prompt' then
        return self:type(self.types.string)
    elseif ast.type == 'random' then
        return self:type(self.types.number)
    elseif traversal.unary[ast.type] then
        return self:infer(ast.argument, ast)
    elseif ast.type == 'identifier' then
        local name = ast.characters
        local symbol = self.symbols[name]
        return symbol.types
    elseif ast.type == 'assignment' then
        self:infer(ast.value, ast)
        return self:type(self.types.null)
    elseif ast.type == 'block' then
        return self:type(self.types.block)
    elseif ast.type == 'call' then
        return self:infer(ast.name, ast)
    elseif ast.type == 'if' then
        self:infer(ast.condition, ast)
        local type1 = self:infer(ast.body, ast)
        local type2 = self:infer(ast.fallback, ast)
        return self:join(type1, type2)
    elseif ast.type == 'while' then
        self:infer(ast.condition, ast)
        return self:infer(ast.body, ast)
    elseif ast.type == 'get' then
        self:infer(ast.start, ast)
        self:infer(ast.width, ast)
        return self:infer(ast.argument, ast)
    elseif ast.type == 'set' then
        self:infer(ast.start, ast)
        self:infer(ast.width, ast)
        self:infer(ast.value, ast)
        return self:infer(ast.argument, ast)        
    elseif ast.type == self.types.string then
        return self:type(self.types.string)
    elseif ast.type == self.types.number then
        return self:type(self.types.number)
    elseif ast.type == self.types.null then
        return self:type(self.types.null)
    elseif ast.type == self.types.boolean then
        return self:type(self.types.boolean)
    elseif ast.type == self.types.array then
        return self:type(self.types.array)
    else
        frog:throw(
            ast.token, 
            string.format('Panic during typecheck, recieved unknown node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )

        os.exit(1)
    end
end

return typecheck