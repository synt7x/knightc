local types = require("src/frontend/types")
local frog = require("lib/frog")
local json = require("lib/json")

local infer = {}

function infer.new(ast, symbols)
	local self = {
		symbols = symbols,
	}

	for key, value in pairs(infer) do
		self[key] = value
	end

	for name, symbol in pairs(self.symbols) do
		symbol.types = types.variable()
	end

	print(types.print(self:walk(ast.body)))

	for name, symbol in pairs(self.symbols) do
		print(name, types.print(symbol.types))
	end

	return self
end

function infer:call(node)
	local t = self:walk(node.name)

	local function collect(t, collected, seen)
		seen = seen or {}
		if seen[t] then
			return
		end
		seen[t] = true

		if t.type == types.primitive.block then
			table.insert(collected, t.properties.returns)
		elseif t.type == types.complex.union then
			for _, e in ipairs(t.properties.elements) do
				collect(e, collected, seen)
			end
		end
	end

	local returns = {}
	collect(t, returns)

	if #returns > 0 then
		local result = returns[1]
		for i = 2, #returns do
			types.expand(result, returns[i])
		end
		node.types = result
		return node.types
	elseif t.type == types.complex.variable then
		local v = types.variable()
		types.expand(t, types.block(v))
		node.types = v
		return node.types
	else
		frog:throw(
			node.name.token,
			"Attempted to call non-block type, expected a block got " .. types.print(t),
			"Ensure the function is defined as a block",
			"Inference"
		)
		os.exit(1)
	end
end

function infer:quit(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.number()) then
		frog:throw(
			node.argument.token,
			"Expected a number when calling quit, got " .. types.print(t),
			"Ensure the argument is coercable to a number",
			"Inference"
		)
		os.exit(1)
	end

	if t.type == types.complex.variable then
		types.expand(t, types.number())
	end

	node.types = types.null()
	return node.types
end

function infer:output(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.string()) then
		frog:throw(
			node.argument.token,
			"Expected a string when outputting, got " .. types.print(t),
			"Ensure the argument is coercable to a string",
			"Inference"
		)
		os.exit(1)
	end

	if t.type == types.complex.variable then
		types.expand(t, types.string())
	end

	node.types = types.null()
	return node.types
end

function infer:dump(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.string()) then
		frog:throw(
			node.argument.token,
			"Expected an integer, boolean, null, string, or list when calling the DUMP function, got " .. types.print(t),
			"Ensure the argument is coercable to a string",
			"Inference"
		)
		os.exit(1)
	end

	node.types = t
	return node.types
end

function infer:length(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.list()) then
		frog:throw(
			node.argument.token,
			"Expected a list when calling the LENGTH function, got " .. types.print(t),
			"Ensure the argument is coercable to a list",
			"Inference"
		)
		os.exit(1)
	end

	if t.type == types.complex.variable then
		types.expand(t, types.list(types.variable()))
	end

	node.types = types.number()
	return node.types
end

function infer:negate(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.boolean()) then
		frog:throw(
			node.argument.token,
			"Expected a boolean when calling the ! function, got " .. types.print(t),
			"Ensure the argument is coercable to a boolean",
			"Inference"
		)
		os.exit(1)
	end

	if t.type == types.complex.variable then
		types.expand(t, types.boolean())
	end

	node.types = types.boolean()
	return node.types
end

function infer:negative(node)
	local t = self:walk(node.argument)

	if not types.coerce(t, types.number()) then
		frog:throw(
			node.argument.token,
			"Expected a number when negating, got " .. types.print(t),
			"Ensure the argument is coercable to a number",
			"Inference"
		)
		os.exit(1)
	end

	if t.type == types.complex.variable then
		types.expand(t, types.number())
	end

	node.types = types.number()
	return node.types
end

function infer:ascii(node)
	local t = self:walk(node.argument)

	if t.type == types.primitive.number then
		node.types = types.string()
		return node.types
	elseif t.type == types.primitive.string then
		node.types = types.number()
		return node.types
	elseif t.type == types.complex.union then
		local is_number = false
		local is_string = false

		local function collect(t, seen)
			seen = seen or {}
			if seen[t] then
				return
			end

			seen[t] = true

			if t.type == types.primitive.number then
				is_number = true
			elseif t.type == types.primitive.string then
				is_string = true
			elseif t.type == types.complex.union then
				for _, e in ipairs(t.properties.elements) do
					collect(e, seen)
				end
			end
		end

		collect(t)

		if is_number or is_string then
			if is_number and is_string then
				node.types = types.union(types.string(), types.number())
			elseif is_number then
				node.types = types.number()
			else
				node.types = types.string()
			end

			return node.types
		else
			frog:throw(
				node.argument.token,
				"Expected a number or string when calling ASCII, got " .. types.print(t),
				"Ensure the argument is either a number or string",
				"Inference"
			)
			os.exit(1)
		end
	elseif t.type == types.complex.variable then
		types.expand(t, types.union(types.string(), types.number()))
		node.types = t
		return node.types
	else
		frog:throw(
			node.argument.token,
			"Expected a number or string when calling ASCII, got " .. types.print(t),
			"Ensure the argument is either a number or string",
			"Inference"
		)
	end
end

function infer:box(node)
	local t = self:walk(node.argument)

	node.types = types.list(t)
	return node.types
end

function infer:prime(node)
	local t = self:walk(node.argument)

	if t.type == types.primitive.string then
		node.types = types.string()
		return node.types
	elseif t.type == types.primitive.list then
		node.types = t.properties.element_type
		return node.types
	elseif t.type == types.complex.union then
		local is_string = false
		local list = {}

		local function collect(t, seen)
			seen = seen or {}
			if seen[t] then
				return
			end

			seen[t] = true

			if t.type == types.primitive.string then
				is_string = true
			elseif t.type == types.primitive.list then
				table.insert(list, t.properties.element)
			elseif t.type == types.complex.union then
				for _, e in ipairs(t.properties.elements) do
					collect(e, seen)
				end
			end
		end

		collect(t)

		if is_string and #list == 0 then
			node.types = types.string()
			return node.types
		elseif is_string then
			local result = types.string()
			for _, t in ipairs(list) do
				result = types.union(result, t)
			end

			node.types = result
			return result
		elseif #list > 0 then
			local result = list[1]

			if #list > 1 then
				for i = 2, #list do
					result = types.union(result, list[i])
				end
			end

			node.types = result
			return result
		else
			frog:throw(
				node.argument.token,
				"Expected a string or list when calling [, got " .. types.print(t),
				"Ensure the argument is either a string or a list",
				"Inference"
			)
			os.exit(1)
		end
	elseif t.type == types.complex.variable then
		types.expand(t, types.union(types.string(), types.variable()))
		node.types = t
		return node.types
	else
		frog:throw(
			node.argument.token,
			"Expected a string or list when calling [, got " .. types.print(t),
			"Ensure the argument is either a string or a list",
			"Inference"
		)
		os.exit(1)
	end
end

function infer:ultimate(node)
	local t = self:walk(node.argument)

	if t.type == types.primitive.string then
		node.types = types.string()
		return node.types
	elseif t.type == types.primitive.list then
		node.types = t
		return node.types
	elseif t.type == types.complex.union then
		local is_string = false
		local list = {}

		local function collect(t, seen)
			seen = seen or {}
			if seen[t] then
				return
			end

			seen[t] = true

			if t.type == types.primitive.string then
				is_string = true
			elseif t.type == types.primitive.list then
				table.insert(list, t)
			elseif t.type == types.complex.union then
				for _, e in ipairs(t.properties.elements) do
					collect(e, seen)
				end
			end
		end

		collect(t)

		if is_string and #list == 0 then
			node.types = types.string()
			return node.types
		elseif is_string then
			local result = types.string()
			for _, t in ipairs(list) do
				result = types.union(result, t)
			end

			node.types = result
			return result
		elseif #list > 0 then
			local result = list[1]

			if #list > 1 then
				for i = 2, #list do
					result = types.union(result, list[i])
				end
			end

			node.types = result
			return result
		else
			frog:throw(
				node.argument.token,
				"Expected a string or list when calling ], got " .. types.print(t),
				"Ensure the argument is either a string or a list",
				"Inference"
			)
			os.exit(1)
		end
	elseif t.type == types.complex.variable then
		types.expand(t, types.union(types.string(), types.list(types.variable())))
		node.types = t
		return node.types
	else
		frog:throw(
			node.argument.token,
			"Expected a string or list when calling ], got " .. types.print(t),
			"Ensure the argument is either a string or a list",
			"Inference"
		)
		os.exit(1)
	end
end

function infer:add(node)
	local t1 = self:walk(node.left)
	local t2 = self:walk(node.right)

	local coerced = types.coerce(t2, t1)

	print(types.print(t2), types.print(t1), types.print(coerced))

	if
		not types.has(t1, types.primitive.string)
		and not types.has(t1, types.primitive.number)
		and not types.has(t1, types.primitive.list)
	then
		frog:throw(
			node.token,
			"Expected a number, string, or list when adding, got " .. types.print(t1) .. " and " .. types.print(t2),
			"Ensure both arguments are coercable to a common type",
			"Inference"
		)
		os.exit(1)
	end

	return node.types
end

function infer:walk(node)
	if node.type == "expr" then
		self:walk(node.left)
		return self:walk(node.right)
	elseif node.type == "call" then
		return self:call(node)
	elseif node.type == "quit" then
		return self:quit(node)
	elseif node.type == "output" then
		return self:output(node)
	elseif node.type == "dump" then
		return self:dump(node)
	elseif node.type == "length" then
		return self:length(node)
	elseif node.type == "not" then
		return self:negate(node)
	elseif node.type == "negate" then
		return self:negative(node)
	elseif node.type == "ascii" then
		return self:ascii(node)
	elseif node.type == "box" then
		return self:box(node)
	elseif node.type == "prime" then
		return self:prime(node)
	elseif node.type == "ultimate" then
		return self:ultimate(node)
	elseif node.type == "add" then
		return self:add(node)
	elseif node.type == "number" then
		node.types = types.number()
		return node.types
	elseif node.type == "string" then
		node.types = types.string()
		return node.types
	elseif node.type == "boolean" then
		node.types = types.boolean()
		return node.types
	elseif node.type == "null" then
		node.types = types.null()
		return node.types
	elseif node.type == "identifier" then
		local symbol = self.symbols[node.characters]
		node.types = symbol.types
		return node.types
	elseif node.type == "assignment" then
		local t = self:walk(node.value)
		local name = node.name.characters
		local symbol = self.symbols[name]

		types.expand(symbol.types, t)
		node.types = t
		return node.types
	elseif node.type == "block" then
		local t = self:walk(node.body)

		node.types = types.block(t)
		return node.types
	elseif node.type == "list" then
		node.types = types.list(types.variable())
		return node.types
	end
end

return infer
