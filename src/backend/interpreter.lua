local interpreter = {}
local bytecode = require('src/backend/bytecode')
local json = require('lib/json')

function interpreter.new(ir, data, constants)
    local self = {}
    for k, v in pairs(interpreter) do
        self[k] = v
    end

    self.ir = ir
    self.data = data
    self.constants = constants
    self.index = 1

    self:run()

    return self
end

function interpreter:push(value)
    self.stack[self.stack_pointer] = value

    self.stack_pointer = self.stack_pointer + 1
end

function interpreter:pop()
    if self.stack_pointer > 1 then
        self.stack_pointer = self.stack_pointer - 1
        return self.stack[self.stack_pointer]
    end

    return nil
end

function interpreter:jump(address)
    if address > #self.ir then
        print("Jump out of bounds")
        return
    end

    self.index = address
end

function interpreter:byte()
    local byte = self.ir[self.index]
    self.index = self.index + 1

    return byte
end

function interpreter:store(address, register)
    self.data[address] = self.registers[register]
end

function interpreter:load(register, value)
    self.registers[register] = value
end

function interpreter:run()
    self.stack = {}
    self.registers = {}

    self.stack_pointer = 1

    while self.index <= #self.ir do
        local instruction = self:byte()

        if instruction == bytecode.NOP then
        elseif instruction == bytecode.HALT then
            break
        elseif instruction == bytecode.LOAD then
            local register = self:byte()
            local address = self:byte()
            local data = self.data[address]

            self:load(register, data)
        elseif instruction == bytecode.LOADK then
            local register = self:byte()
            local address = self:byte()
            local constant = self.constants[address]

            self:load(register, constant)
        elseif instruction == bytecode.LOADIMM then
            local register = self:byte()
            local value = self:byte()

            self:load(register, value)
        elseif instruction == bytecode.STORE then
            local register = self:byte()
            local address = self:byte()

            self:store(address, register)
        elseif instruction == bytecode.PUSH then
            local address = self:byte()
            local constant = self.constants[address] or 0

            self:push(constant)
        elseif instruction == bytecode.PUSHR then
            local register = self:byte()
            local value = self.registers[register] or 0

            if register == 0 then
                value = self.index + 2
            end

            self:push(value)
        elseif instruction == bytecode.POP then
            local register = self:byte()
            local value = self:pop()

            self:load(register, value)
        elseif instruction == bytecode.JMP then
            local address = self:byte()
            self:jump(address)
        elseif instruction == bytecode.JZ then
            local address = self:byte()
            local value = self:pop()

            if value == 0 then
                self:jump(address)
            end
        elseif instruction == bytecode.JNZ then
            local address = self:byte()
            local value = self:pop()

            if value ~= 0 then
                self:jump(address)
            end
        elseif instruction == bytecode.JR then
            local register = self:byte()
            local address = self.registers[register] or 1

            self:jump(address)
        elseif instruction == bytecode.ADD then
            local register1 = self:byte()
            local register2 = self:byte()
            local value1 = self.registers[register1] or 0
            local value2 = self.registers[register2] or 0

            self:push(value1 + value2)
        elseif instruction == bytecode.SUB then
            local register1 = self:byte()
            local register2 = self:byte()
            local value1 = self.registers[register1] or 0
            local value2 = self.registers[register2] or 0

            self:push(value1 - value2)
        elseif instruction == bytecode.LT then
            local register1 = self:byte()
            local register2 = self:byte()
            local value1 = self.registers[register1] or 0
            local value2 = self.registers[register2] or 0

            if value1 < value2 then
                self:push(1)
            else
                self:push(0)
            end
        elseif instruction == bytecode.OUTPUT then
            print(self:pop())
        else
            error("Unknown instruction", instruction)
        end
    end
end

interpreter.new(bytecode.examples.fib, {}, { 30 } )
