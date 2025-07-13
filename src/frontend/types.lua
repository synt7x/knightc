local types = {}
local json = require("lib/json")

types.tag = 0 -- Track the current tag for variable types

types.primitive = {
	number = "number",
	string = "string",
	boolean = "boolean",
	null = "null",
	list = "list",
	block = "block",
}

types.complex = {
	variable = "variable",
	union = "union",
}

types.coercion = {
	[types.primitive.number] = {
		[types.primitive.string] = true,
		[types.primitive.boolean] = true,
		[types.primitive.list] = true,
	},
	[types.primitive.string] = {
		[types.primitive.number] = true,
		[types.primitive.boolean] = true,
		[types.primitive.list] = true,
	},
	[types.primitive.boolean] = {
		[types.primitive.number] = true,
		[types.primitive.string] = true,
	},
	[types.primitive.list] = {
		[types.primitive.number] = true,
		[types.primitive.string] = true,
		[types.primitive.boolean] = true,
	},
	[types.primitive.null] = {
		[types.primitive.number] = true,
		[types.primitive.string] = true,
		[types.primitive.boolean] = true,
		[types.primitive.list] = true,
	},
}

function types.new(t, properties)
	return {
		type = t,
		properties = properties or {},
	}
end

-- Generate identifier type
function types.string()
	return types.new(types.primitive.string)
end

-- Generate number type
function types.number()
	return types.new(types.primitive.number)
end

-- Generate boolean type
function types.boolean()
	return types.new(types.primitive.boolean)
end

-- Generate null type
function types.null()
	return types.new(types.primitive.null)
end

-- Generate list type with an element type
function types.list(t)
	return types.new(types.primitive.list, { element = t })
end

-- Generate block type with a return type
function types.block(t)
	return types.new(types.primitive.block, { returns = t })
end

function types.variable()
	types.tag = types.tag + 1
	return types.new(types.complex.variable, { tag = types.tag })
end

function types.is_literal(t)
	return t.type == types.primitive.number
		or t.type == types.primitive.string
		or t.type == types.primitive.boolean
		or t.type == types.primitive.null
end

function types.equal(t1, t2)
	if t1.type ~= t2.type then
		return false
	elseif t1.type == types.complex.variable then
		return t1.properties.tag == t2.properties.tag
	elseif t1.type == types.complex.union then
		if #t1.properties.elements ~= #t2.properties.elements then
			return false
		end

		for _, e1 in ipairs(t1.properties.elements) do
			local contains = false
			for _, e2 in ipairs(t2.properties.elements) do
				if types.equal(e1, e2) then
					contains = true
					break
				end
			end

			if not contains then
				return false
			end
		end

		return true
	elseif t1.type == types.primitive.list then
		return types.equal(t1.properties.element, t2.properties.element)
	elseif t1.type == types.primitive.block then
		return types.equal(t1.properties.returns, t2.properties.returns)
	end

	return true
end

function types.print(t, seen)
	seen = seen or {}

	if seen[t] then
		if t.type == types.complex.variable then
			return "T" .. " (recursive " .. (t.properties.tag or "") .. ")"
		else
			return "T (recursive)"
		end
	end

	seen[t] = true

	if t.type == types.complex.union then
		local elements = {}

		for _, element in ipairs(t.properties.elements) do
			table.insert(elements, types.print(element, seen))
		end

		return "(" .. table.concat(elements, " | ") .. ")"
	elseif t.type == types.complex.variable then
		return "T" .. "(" .. (t.properties.tag or "") .. ")"
	elseif t.type == types.primitive.list then
		return "list<" .. types.print(t.properties.element, seen) .. ">"
	elseif t.type == types.primitive.block then
		return "() -> " .. types.print(t.properties.returns, seen)
	else
		return t.type
	end
end

function types.coerce(from, to)
	if types.equal(from, to) then
		return to
	end

	-- List coercion
	if to.type == types.primitive.list and types.coercion[from.type] and types.coercion[from.type][to.type] then
		-- Primitive to list
		if to.properties.element.type == types.complex.variable then
			types.expand(to.properties.element, from)
			return to
		end
	elseif to.type == types.primitive.list and from.type == to.type then
		-- List to list
		if to.properties.element.type == types.complex.variable then
			types.expand(to.properties.element, from.properties.element)
			return to
		end
	end

	-- Primitive coercion
	if types.coercion[from.type] and types.coercion[from.type][to.type] then
		return to
	end

	-- Union coercion
	if to.type == types.complex.union then
		local coercions = {}
		for _, e in ipairs(to.properties.elements) do
			local coercion = types.coerce(from, e)
			if coercion then
				table.insert(coercions, coercion)
			end
		end

		if #coercions == 1 then
			return coercions[1]
		elseif #coercions > 1 then
			local result = coercions[1]
			for i = 2, #coercions do
				result = types.union(result, coercions[i])
			end
			return result
		end
	elseif from.type == types.complex.union then
		local coercions = {}
		for _, e in ipairs(from.properties.elements) do
			print(e.type, "=>", to.type)
			local coercion = types.coerce(e, to)
			if coercion then
				table.insert(coercions, coercion)
			end
		end

		if #coercions == 1 then
			return coercions[1]
		elseif #coercions > 1 then
			local result = coercions[1]
			for i = 2, #coercions do
				result = types.union(result, coercions[i])
			end
			return result
		end
	else
		return nil -- No valid coercion found
	end
end

function types.has(t, primitive)
	if t.type == types.complex.union then
		for _, element in ipairs(t.properties.elements) do
			if types.has(element, primitive) then
				return true
			end
		end
	elseif t.type == types.complex.variable then
		return false -- Variables don't have primitives directly
	elseif t.type == primitive then
		return true
	elseif t.type == types.primitive.list then
		return types.has(t.properties.element, primitive)
	elseif t.type == types.primitive.block then
		return types.has(t.properties.returns, primitive)
	end

	return false
end

function types.union(t1, t2)
	if t1.type == types.complex.union and t1.type == t2.type then
		-- t1 and t2 are both unions
		local elements = {}

		for _, t in ipairs(t1.properties.elements) do
			table.insert(elements, t)
		end

		for _, t in ipairs(t2.properties.elements) do
			local contains = false
			for _, e in ipairs(elements) do
				if types.equal(e, t) then
					contains = true
					break
				end
			end

			if not contains then
				table.insert(elements, t)
			end
		end

		return types.new(types.complex.union, { elements = elements })
	elseif t1.type == types.complex.union then
		-- t1 is a union, t2 is not
		for _, t in ipairs(t1.properties.elements) do
			if types.equal(t, t2) then
				return t1
			end
		end

		local elements = {}
		for _, t in ipairs(t1.properties.elements) do
			table.insert(elements, t)
		end
		table.insert(elements, t2)

		return t1
	elseif t2.type == types.complex.union then
		-- t2 is a union, t1 is not
		return types.union(t2, t1)
	else
		if types.equal(t1, t2) then
			return t1
		end

		return types.new(types.complex.union, { elements = { t1, t2 } })
	end
end

function types.expand(variable, t)
	if variable.type == types.complex.variable then
		variable.type = t.type
		variable.properties = t.properties or {}
		variable.tag = nil
		return variable
	elseif variable.type == types.complex.union then
		for _, e in ipairs(variable.properties.elements) do
			if types.equal(e, t) then
				return variable
			end
		end
		table.insert(variable.properties.elements, t)
		return variable
	else
		local union = types.union(variable, t)

		variable.type = union.type
		variable.properties = union.properties
		variable.tag = nil

		return variable
	end
end

local v = types.union(types.string(), types.list(types.variable()))
local from = types.boolean()
local to = v
print("from type:", types.print(from))
print("to type:", types.print(to))
local result = types.coerce(from, to)
print(json(result))
print(types.print(result))

return types
