local frog = require("lib/frog")
local json = require("lib/json")

local lexer = require("src/frontend/lexer")
local parser = require("src/frontend/parser")
local symbols = require("src/frontend/symbols")
local infer = require("src/frontend/infer")

local ir = require("src/backend/ir")

local cli = require("src/cli")
local flags, inputs = cli(arg)

for i, name in ipairs(inputs) do
	local file = io.open(name, "r")

	if not file then
		file = io.open(name .. ".kn", "r")
	end

	if file then
		local text = file:read("*a")
		file:close()
		frog.file = name

		local tokens, comments = lexer.new(text)
		frog:dump("tokens", tokens)

		local ast = parser.new(flags, tokens, comments)
		frog:dump("ast", ast)

		local symbols = symbols.new(ast)
		frog:dump("symbols", symbols)

		infer.new(ast, symbols)

		for i, symbol in pairs(symbols) do
			symbol.defs = nil
		end

		frog:dump("types/ast", ast)
		frog:dump("types/symbols", symbols)

		local ir = ir.new(ast)
		local intermediate, constants, data = ir:generate()

		frog:dump("ir/intermediate", intermediate)
		frog:dump("ir/constants", constants)
		frog:dump("ir/data", data)
		frog:dump("ir", intermediate)
	else
		frog:croak(string.format('Unable to locate file "%s" (tried %s and %s)', name, name, name .. ".kn"))
	end
end
