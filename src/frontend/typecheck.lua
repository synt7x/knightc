local typecheck = {
    types = {
        ['null'] = 'null', ['number'] = 'number', ['string'] = 'string',
        ['list'] = 'list', ['boolean'] = 'boolean', ['block'] = 'block',
        ['unresolved'] = 'unresolved'
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
    self:work()

    return self:check(ast.body)
end

function typecheck:join(type1, type2, depth)
    depth = depth or 0

    if depth > 10 then
        return type1
    end

    local overlap = {}
    for i, type in ipairs(type1 or {}) do overlap[type] = type end
    for i, type in ipairs(type2 or {}) do overlap[type] = type end

    local union = {}
    for i, type in pairs(overlap) do
        table.insert(union, type)
    end

    if type1.block and type2.block then
        if type1.block == type2.block then
            union.block = type1.block -- Avoid infinite recursion
        else
            union.block = self:join(type1.block, type2.block, depth + 1)
        end
    elseif type1.block then
        union.block = type1.block
    elseif type2.block then
        union.block = type2.block
    end

    if type1.list and type2.list then
        if type1.list == type2.list then
            union.list = type1.list -- Avoid infinite recursion
        else
            union.list = self:join(type1.list, type2.list, depth + 1)
        end
    elseif type1.list then
        union.list = type1.list
    elseif type2.list then
        union.list = type2.list
    end

    return union
end

function typecheck:equal(type1, type2, depth)
    depth = depth or 0

    if depth > 10 then
        return true
    end

    if #type1 ~= #type2 then return false end

    local set = {}
    for _, t in ipairs(type1) do set[t] = true end
    for _, t in ipairs(type2) do
        if not set[t] then return false end
    end

    if type1.block and type2.block then
        if type1.block == type2.block then return true end
        if not self:equal(type1.block, type2.block, depth + 1) then return false end
    elseif type1.block or type2.block then
        return false
    end

    if type1.list and type2.list then
        if type1.list == type2.list then return true end
        if not self:equal(type1.list, type2.list, depth + 1) then return false end
    elseif type1.list or type2.list then
        return false
    end

    return true
end

function typecheck:type(...)
    return { ... }
end

function typecheck:meta(type, bmeta, lmeta)
    if type.block then
        type.block = self:join(type.block, bmeta)
    else
        type.block = bmeta
    end

    if type.list then
        type.list = self:join(type.list, lmeta)
    else
        type.list = lmeta
    end

    return type
end

function typecheck:apply(ast, ...)
    local types = self:type(...)
    ast.types = types

    return ast.types
end

function typecheck:has(ast, check)
	for _, type in ipairs(ast.types) do
		if check == type then
			return true
		end
	end

	return false
end

function typecheck:contains(types, check)
	for _, type in ipairs(types) do
		if check == type then
			return true
		end
	end

	return false
end

function typecheck:work()
    local worklist = {}
    local visited = {}
    for name, symbol in pairs(self.symbols) do
        table.insert(worklist, name)
    end

    while #worklist > 0 do
        local name = table.remove(worklist)
        if not visited[name] then
            local symbol = self.symbols[name]

            self.unresolved = false
            self.symbol = symbol
            
            local inferred = {}
            for i, def in ipairs(symbol.defs) do
                local type = self:infer(def.value)
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
end

function typecheck:expect(ast, checked, expected, a)
    local contains = false
    local set = {}

    for _, t in ipairs(checked) do set[t] = true end
    for _, t in ipairs(expected) do
        if set[t] then contains = true end
    end

    if not contains then
        frog:throw(
            ast.token,
            "Expected expression of type " .. json(expected) .. ' got ' .. json(checked),
            "Replace with an expression of the expected type",
            'err',
            a
        )
    end

    return expected
end

function typecheck:recursive(ast)
    if not ast then
        return false
    end

    if ast.type == 'identifier' then
        local symbol = self.symbols[ast.characters]
        if not symbol then
            frog:throw(
                ast.token,
                string.format('Panic during type enforcement, unhandled identifier %s', ast.characters),
                'Please report this as a bug in the issue tracker',
                'Panic'
            )
        end

        local tag = symbol.tag
        -- Check if the identifier matches the current function being analyzed
        return tag == self.symbol.tag
    elseif ast.type == 'if' then
        -- Check all branches of the `if` statement
        return self:recursive(ast.condition)
            or self:recursive(ast.body)
            or self:recursive(ast.fallback)
    elseif ast.type == 'prime' then
        -- Check the unboxed value in the `prime` node
        return self:recursive(ast.argument)
    elseif ast.type == 'ultimate' then
        -- Check the unboxed value in the `ultimate` node
        return self:recursive(ast.argument)
    elseif ast.type == 'box' then
        -- Check the unboxed value in the `box` node
        return self:recursive(ast.argument)
    elseif ast.type == 'get' then
        return self:recursive(ast.argument)
    elseif ast.type == 'assignment' then
        -- Check the value being assigned
        return self:recursive(ast.value)
    elseif traversal.unary[ast.type] then
        -- Check the argument of unary operations
        return self:recursive(ast.argument)
    elseif traversal.binary[ast.type] then
        -- Check both sides of binary operations
        return self:recursive(ast.left) or self:recursive(ast.right)
    elseif ast.type == 'call' then
        -- Check the `CALL` value itself
        return self:recursive(ast.name)
    end

    return false
end

function typecheck:coerce(ast, checked, expected)
    for _, type in pairs(checked) do
        if type == self.types.block then
            frog:throw(
                ast.token,
                "Attempted to coerce block into " .. json(expected),
                "Replace with a expression of type ".. json(expected)
            )
        end
    end

    return self:type(expected)
end

function typecheck:check(ast, parent)
    if not ast then
        frog:throw(
            parent.token,
            string.format("Panic during type enforcement, recieved nil child while walking node %s", parent.type),
            "Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)",
            "Fatal"
        )

        os.exit(1)
    end

    if ast.type == 'call' then
        local name = ast.name
		local types = self:check(name, ast)
        self:expect(
			name,
			name.types,
			self:type(self.types.block),
            ast
		)

		ast.types = types.block or { self.types.null }
        return ast.types
    elseif ast.type == 'quit' then
        self:coerce(
            ast.argument,
            self:check(ast.argument, ast),
            self.types.number
        )

        return self:apply(ast, self.types.null)
    elseif ast.type == 'output' then
        self:coerce(
            ast.argument,
            self:check(ast.argument, ast),
            self.types.string
        )

        return self:apply(ast, self.types.null)
    elseif ast.type == 'dump' then
        self:expect(
            ast.argument,
            self:check(ast.argument, ast),
            {
                self.types.number, self.types.boolean, self.types.null,
                self.types.string, self.types.list
            }
        )

        return self:apply(ast, self.types.null)
    elseif ast.type == 'length' then
        self:coerce(
            ast.argument,
            self:check(ast.argument, ast),
            self.types.list
        )

        return self:apply(ast, self.types.number)
    elseif ast.type == 'not' then
        self:coerce(
            ast.argument,
            self:check(ast.argument, ast),
            self.types.boolean
        )

        return self:apply(ast, self.types.boolean)
    elseif ast.type == 'negative' then
        self:coerce(
            ast.argument,
            self:check(ast.argument, ast),
            self.types.number
        )

        return self:apply(ast, self.types.number)
    elseif ast.type == 'ascii' then
        self:expect(
            ast.argument,
            self:check(ast.argument, ast),
            self:type(self.types.number, self.types.string)
        )

		local is_string = self:has(ast.argument, self.types.string)
		local is_number = self:has(ast.argument, self.types.number)

		if is_string and is_number then
			return self:apply(ast, self.types.string, self.types.number)
		elseif is_string then
			return self:apply(ast, self.types.number)
		end

		return self:apply(ast, self.types.string)
	elseif ast.type == 'box' then
        self:apply(ast, self.types.list)

		return self:meta(
            ast.types,
            nil,
            self:check(ast.argument, ast)
        )
	elseif ast.type == 'prime' then
        local types = self:check(ast.argument, ast)
        ast.types = {}

		self:expect(
			ast.argument,
			types,
			self:type(self.types.number, self.types.string, self.types.list)
		)

		local is_string = self:has(ast.argument, self.types.string)
		local is_number = self:has(ast.argument, self.types.number)
        local is_list = self:has(ast.argument, self.types.list)

        if is_string then
            ast.types = self:join(ast.types, { self.types.string })
        end

        if is_number then
            ast.types = self:join(ast.types, { self.types.number })
        end

        if is_list then
            ast.types = self:join(ast.types, types.list or { self.types.null })
        end

        return ast.types
	elseif ast.type == 'ultimate' then
        local types = self:check(ast.argument, ast)
        ast.types = {}

		self:expect(
			ast.argument,
			types,
			self:type(self.types.number, self.types.string, self.types.list)
		)

		local is_string = self:has(ast.argument, self.types.string)
		local is_number = self:has(ast.argument, self.types.number)
        local is_list = self:has(ast.argument, self.types.list)

        if is_string then
            ast.types = self:join(ast.types, { self.types.string })
        end

        if is_number then
            ast.types = self:join(ast.types, { self.types.number })
        end

        if is_list then
            ast.types = self:join(ast.types, types.list or { self.types.null })
        end

        return ast.types
	elseif ast.type == 'add' then    
        local ltypes = self:check(ast.left, ast)
        local rtypes = self:check(ast.right, ast)

		self:expect(
			ast.left,
			ltypes,
			self:type(self.types.number, self.types.string, self.types.list)
		)

		local is_number = self:has(ast.left, self.types.number)
		local is_string = self:has(ast.left, self.types.string)
		local is_list = self:has(ast.left, self.types.list)

		local types = {}

		if is_number then
			table.insert(types, self.types.number)
		end

		if is_string then
			table.insert(types, self.types.string)
		end

        if is_list then
            table.insert(types, self.types.list)
        else
            self:coerce(
                ast.right,
                rtypes,
                types
            )
        end

        if is_list then
            types.list = ltypes.list or {}
            types.list = self:join(types.list, rtypes)
		end

		ast.types = types
		return types
	elseif ast.type == 'subtract' then
		self:expect(
			ast.left,
			self:check(ast.left, ast),
			self:type(self.types.number)
		)

		self:coerce(
			ast.right,
			self:check(ast.right, ast),
			self:type(self.types.number)
		)

		return self:apply(ast, self.types.number)
	elseif ast.type == 'multiply' then
        local ltypes = self:check(ast.left, ast)
        local rtypes = self:check(ast.right, ast)

		self:expect(
			ast.left,
			ltypes,
			self:type(self.types.number, self.types.string, self.types.list)
		)

		local is_number = self:has(ast.left, self.types.number)
		local is_string = self:has(ast.left, self.types.string)
		local is_list = self:has(ast.left, self.types.list)

		local types = {}

		if is_number then
			table.insert(types, self.types.number)
		end

		if is_string then
			table.insert(types, self.types.string)
		end

        if is_list then
            table.insert(types, self.types.list)
        end

		self:coerce(
			ast.right,
			rtypes,
			{ self.types.number }
		)

        if is_list then
            types.list = ltypes.list or {}
		end

		ast.types = types
		return types
	elseif ast.type == 'divide' then
        self:expect(
			ast.left,
			self:check(ast.left, ast),
			self:type(self.types.number)
		)

		self:coerce(
			ast.right,
			self:check(ast.right, ast),
			self:type(self.types.number)
		)

		return self:apply(ast, self.types.number)
	elseif ast.type == 'modulus' then
        self:expect(
			ast.left,
			self:check(ast.left, ast),
			self:type(self.types.number)
		)

		self:coerce(
			ast.right,
			self:check(ast.right, ast),
			self:type(self.types.number)
		)

		return self:apply(ast, self.types.number)
	elseif ast.type == 'exponent' then
        local ltypes = self:check(ast.left, ast)
        self:expect(
            ast.left,
            ltypes,
            self:type(self.types.number, self.types.list)
        )

        local is_number = self:has(ast.left, self.types.number)
        local is_list = self:has(ast.left, self.types.list)

        self:coerce(
            ast.right,
            self:check(ast.right, ast),
            self:type(self.types.number, self.types.string)
        )

        if is_number and is_list then
            ast.types = self:type(self.types.number, self.types.list)
        elseif is_number then
            ast.types = self:type(self.types.number)
        elseif is_list then
            ast.types = self:type(self.types.list)
        end

        return ast.types
	elseif ast.type == 'less' then
        self:expect(
            ast.left,
            self:check(ast.left, ast),
            self:type(self.types.number, self.types.string, self.types.boolean, self.types.list)
        )

        self:coerce(
            ast.right,
            self:check(ast.right, ast),
            self:type(self.types.number, self.types.string, self.types.boolean, self.types.list)
        )

        return self:apply(ast, self.types.boolean)
	elseif ast.type == 'greater' then
        self:expect(
            ast.left,
            self:check(ast.left, ast),
            self:type(self.types.number, self.types.string, self.types.boolean, self.types.list)
        )

        self:coerce(
            ast.right,
            self:check(ast.right, ast),
            self:type(self.types.number, self.types.string, self.types.boolean, self.types.list)
        )

        return self:apply(ast, self.types.boolean)
	elseif ast.type == 'exact' then
        self:expect(
            ast.left,
            self:check(ast.left, ast),
            self:type(
                self.types.number,
                self.types.string,
                self.types.boolean,
                self.types.list,
                self.types.null
            )
        )

        self:expect(
            ast.right,
            self:check(ast.right, ast),
            self:type(
                self.types.number,
                self.types.string,
                self.types.boolean,
                self.types.list,
                self.types.null
            )
        )

        return self:apply(ast, self.types.boolean)
    elseif ast.type == 'and' then
        local ltypes = self:check(ast.left, ast)
        local rtypes = self:check(ast.right, ast)

        self:coerce(
            ast.left,
            ltypes,
            self.types.unresolved
        )

        ast.types = self:join(ltypes, rtypes)

        return ast.types
    elseif ast.type == 'or' then
        local ltypes = self:check(ast.left, ast)
        local rtypes = self:check(ast.right, ast)

        self:coerce(
            ast.left,
            ltypes,
            self.types.unresolved
        )

        ast.types = self:join(ltypes, rtypes)
        return ast.types
    elseif ast.type == 'expr' then
        self:check(ast.left, ast)
        ast.types = self:check(ast.right, ast)
        return ast.types
    elseif ast.type == 'assignment' then
        local value = self:check(ast.value, ast)
        local name = ast.name.characters
        local symbol = self.symbols[name]

        self:check(ast.name, ast)
        ast.types = value
        return value
    elseif ast.type == 'if' then
        self:check(ast.condition, ast)
        local type1 = self:check(ast.body, ast)
        local type2 = self:check(ast.fallback, ast)

        ast.types = self:join(type1, type2)
        return ast.types
    elseif ast.type == 'get' then
        local types = self:check(ast.argument, ast)

        self:expect(
            ast.argument,
            types,
            { self.types.list, self.types.string }
        )

        self:expect(
            ast.start,
            self:check(ast.start, ast),
            { self.types.number }
        )

        self:expect(
            ast.width,
            self:check(ast.width, ast),
            { self.types.number }
        )

        ast.types = types
        return ast.types
    elseif ast.type == 'set' then
        local types = self:check(ast.argument, ast)

        self:expect(
            ast.argument,
            types,
            { self.types.list, self.types.string }
        )

        self:coerce(
            ast.start,
            self:check(ast.start, ast),
            { self.types.number }
        )

        self:coerce(
            ast.width,
            self:check(ast.width, ast),
            { self.types.number }
        )

        self:coerce(
            ast.value,
            self:check(ast.value, ast),
            types
        )

        ast.types = types
        return ast.types
    elseif ast.type == 'while' then
        self:check(ast.condition, ast)
        self:check(ast.body, ast)
        return self:apply(ast, self.types.null)
	elseif ast.type == 'block' then
		self:apply(ast, self.types.block)

		return self:meta(
            ast.types,
            self:check(ast.body, ast)
        )
    elseif ast.type == 'identifier' then
        local name = ast.characters
        local symbol = self.symbols[name]

        if not symbol then
            frog:throw(
                ast.token,
                string.format('Panic during type enforcement, unhandled identifier %s', name),
                'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
                'Fatal'
            )
        end

        ast.types = symbol.types
        return ast.types
    elseif ast.type == 'number' or ast.type == 'random' then
        return self:apply(ast, self.types.number)
    elseif ast.type == 'string' or ast.type == 'prompt' then
        return self:apply(ast, self.types.string)
    elseif ast.type == 'list' then
        self:apply(ast, self.types.list)

        return self:meta(
            self:apply(ast, self.types.list),
            nil,
            {}
        )
    elseif ast.type == 'boolean' then
        return self:apply(ast, self.types.boolean)
    elseif ast.type == 'null' then
        return self:apply(ast, self.types.null)
    else
        frog:throw(
            ast.token,
            string.format('Panic during type enforcement, unhandled node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )
    end
end

function typecheck:infer(ast, parent)
    if not ast then
        frog:throw(
            parent.token,
            string.format("Panic during typecheck, recieved nil child while walking node %s", parent.type),
            "Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)",
            "Fatal"
        )

        os.exit(1)
    end

    if ast.type == 'add' then    
        local ltypes = self:infer(ast.left, ast)
        local rtypes = self:infer(ast.right, ast)

		local is_number = self:contains(ltypes, self.types.number)
		local is_string = self:contains(ltypes, self.types.string)
		local is_list = self:contains(ltypes, self.types.list)

		local types = {}

		if is_number then
			table.insert(types, self.types.number)
		end

		if is_string then
			table.insert(types, self.types.string)
		end

        if is_list then
            table.insert(types, self.types.list)
        else
            self:coerce(
                ast.right,
                rtypes,
                types
            )
        end

        if is_list then
            types.list = ltypes.list or {}
            types.list = self:join(types.list, rtypes)
		end

		return types
    elseif ast.type == 'subtract' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.number)
    elseif ast.type == 'multiply' then
        local ltypes = self:infer(ast.left, ast)
        local rtypes = self:infer(ast.right, ast)

        local is_number = self:contains(ltypes, self.types.number)
        local is_string = self:contains(ltypes, self.types.string)
        local is_list = self:contains(ltypes, self.types.list)

        local types = {}

        if is_number then
            table.insert(types, self.types.number)
        end

        if is_string then
            table.insert(types, self.types.string)
        end

        if is_list then
            table.insert(types, self.types.list)
        end

        return types
    elseif ast.type == 'divide' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.number)
    elseif ast.type == 'modulus' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.number)
    elseif ast.type == 'exponent' then
        local ltypes = self:infer(ast.left, ast)
        self:infer(ast.right, ast)

        local is_number = self:contains(ltypes, self.types.number)
        local is_string = self:contains(ltypes, self.types.string)

        if is_number and is_list then
            return self:type(self.types.number, self.types.list)
        elseif is_number then
            return self:type(self.types.number)
        elseif is_list then
            return self:type(self.types.list)
        end

        return self:type(self.types.number, self.types.list)
    elseif ast.type == 'and' then
        local ltypes = self:infer(ast.left, ast)
        local rtypes = self:infer(ast.right, ast)

        return self:join(ltypes, rtypes)
    elseif ast.type == 'or' then
        local ltypes = self:infer(ast.left, ast)
        local rtypes = self:infer(ast.right, ast)

        return self:join(ltypes, rtypes)
    elseif ast.type == 'expr' then
        -- self:infer(ast.left, ast)
        return self:infer(ast.right, ast)
    elseif ast.type == 'exact' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.boolean)
    elseif ast.type == 'less' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.boolean)
    elseif ast.type == 'greater' then
        -- self:infer(ast.left, ast)
        -- self:infer(ast.right, ast)
        return self:type(self.types.boolean)
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
    elseif ast.type == 'box' then
        local lmeta = self:infer(ast.argument, ast)
        return self:meta(self:type(self.types.list), nil, lmeta)
    elseif ast.type == 'prime' or ast.type == 'ultimate' then
        local types = self:infer(ast.argument, ast)

		local is_string = self:contains(types, self.types.string)
		local is_number = self:contains(types, self.types.number)
        local is_list = self:contains(types, self.types.list)

        local types = {}

        if is_string then
            types = self:join(types, { self.types.string })
        end

        if is_number then
            types = self:join(types, { self.types.number })
        end

        if is_list then
            types = self:join(types, types.list or { self.types.null })
        end

        if #types == 0 then
            return self:type(self.types.string, self.types.number, self.types.list)
        end

        return types
    elseif ast.type == 'ascii' then
        local types = self:infer(ast.argument, ast)
        if self:contains(types, self.types.string) and self:contains(types, self.types.number) then
            return self:type(self.types.string, self.types.number)
        elseif self:contains(types, self.types.string) then
            return self:type(self.types.number)
        end
        return self:type(self.types.string)
    elseif ast.type == 'length' then
        self:infer(ast.argument, ast)
        return self:type(self.types.number)
    elseif ast.type == 'not' then
        self:infer(ast.argument, ast)
        return self:type(self.types.boolean)
    elseif ast.type == 'negative' then
        self:infer(ast.argument, ast)
        return self:type(self.types.number)
    elseif ast.type == 'quit' then
        self:infer(ast.argument, ast)
        return self:type(self.types.null)
    elseif ast.type == 'identifier' then
        local name = ast.characters
        local symbol = self.symbols[name]

        return symbol.types
    elseif ast.type == 'assignment' then
        return self:infer(ast.value, ast)
    elseif ast.type == 'block' then
        local bmeta = self:infer(ast.body, ast)
        return self:meta(self:type(self.types.block), bmeta, nil)
    elseif ast.type == 'call' then
        local meta = self:infer(ast.name, ast)
        if self:recursive(ast.name) then
            self.unresolved = true
        end
        return meta.block or {}
    elseif ast.type == 'if' then
        self:infer(ast.condition, ast)
        local type1 = self:infer(ast.body, ast)
        local type2 = self:infer(ast.fallback, ast)
        return self:join(type1, type2)
    elseif ast.type == 'while' then
        -- self:infer(ast.condition, ast)
        -- self:infer(ast.body, ast)
        return self:type(self.types.null)
    elseif ast.type == 'get' then
        -- self:infer(ast.start, ast)
        -- self:infer(ast.width, ast)
        local types = self:infer(ast.argument, ast)
        if #types == 0 then
            return self:type(self.types.string, self.types.list)
        end
        return types 
    elseif ast.type == 'set' then
        -- self:infer(ast.start, ast)
        -- self:infer(ast.width, ast)
        -- self:infer(ast.value, ast)
		local types = self:infer(ast.argument, ast)
        if #types == 0 then
            return self:type(self.types.string, self.types.list)
        end
        return types 
    elseif ast.type == self.types.string then
        return self:type(self.types.string)
    elseif ast.type == self.types.number then
        return self:type(self.types.number)
    elseif ast.type == self.types.null then
        return self:type(self.types.null)
    elseif ast.type == self.types.boolean then
        return self:type(self.types.boolean)
    elseif ast.type == self.types.list then
        return self:meta(self:type(self.types.list), nil, {})
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
