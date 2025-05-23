local bytecode = {
    HALT = 0x01,
    NOP = 0x00,
    
    LOAD = 0x02,
    LOADK = 0x03,
    LOADIMM = 0x04,
    STORE = 0x05,
    PUSH = 0x06,
    PUSHR = 0x07,
    POP = 0x08,
    
    NOT = 0x10,
    EQ = 0x11,
    NEQ = 0x12,
    LT = 0x13,
    GT = 0x14,
    LTE = 0x15,
    GTE = 0x16,
    AND = 0x17,
    OR = 0x18,
    
    JZ = 0x21,
    JNZ = 0x22,
    JR = 0x23,
    JRZ = 0x24,
    JRNZ = 0x25,
    JMP = 0x20,
    
    ADD = 0x30,
    SUB = 0x31,
    MUL = 0x32,
    DIV = 0x33,
    MOD = 0x34,
    NEG = 0x35,
    POW = 0x36,
    
    PROMPT = 0x40,
    RANDOM = 0x41,
    DUMP = 0x42,
    OUTPUT = 0x43,
    
    LENGTH = 0x50,
    PRIME = 0x51,
    ULTIMATE = 0x52,
    INSERT = 0x53,
    EXPAND = 0x54,
    SUBLIST = 0x55,
    SETLIST = 0x56,
    
    CONCAT = 0x60,
    REPEAT = 0x61,
    JOIN = 0x62,
    SUBSTRING = 0x63,
    SETSTRING = 0x64,
        
    CONVERT = 0x90,
    ASCII = 0x91,
}

bytecode.examples = {}

bytecode.examples.fib = {
    bytecode.LOADIMM, 1, 6,
    bytecode.JMP, 57,
    bytecode.LT, 2, 3,
    bytecode.JZ, 17,
    bytecode.POP, 4,
    bytecode.PUSHR, 2,
    bytecode.JR, 4,
    bytecode.LOADIMM, 5, 1,
    bytecode.PUSHR, 2,
    bytecode.SUB, 2, 5,
    bytecode.POP, 2,
    bytecode.PUSHR, 0,
    bytecode.JMP, 6,
    bytecode.POP, 6,
    bytecode.POP, 2,
    bytecode.SUB, 2, 3,
    bytecode.POP, 2,
    bytecode.PUSHR, 6,
    bytecode.PUSHR, 0,
    bytecode.JMP, 6,
    bytecode.POP, 7,
    bytecode.POP, 6,
    bytecode.POP, 4,
    bytecode.ADD, 6, 7,
    bytecode.JR, 4,
    bytecode.LOADK, 2, 1,
    bytecode.LOADIMM, 3, 2,
    bytecode.PUSHR, 0,
    bytecode.JR, 1,
    bytecode.OUTPUT,
    bytecode.HALT,
}

bytecode.examples.fizzbuzz = {
    bytecode.LOADIMM, 1, 1000, -- mov rax, 100
    bytecode.LOADIMM, 2, 0, -- mov rbx, 0
    bytecode.LOADIMM, 3, 1, -- mov rcx, 1
    bytecode.LOADK, 7, 4,
    bytecode.LOADK, 8, 5,
    bytecode.LOADK, 9, 6,

    -- WHILE BODY
    bytecode.LT, 2, 1, -- (< rbx rax)
    bytecode.JZ, 61,

    bytecode.ADD, 2, 3, -- push (rbx + 1)
    bytecode.POP, 2,

    bytecode.MOD, 2, 7,
    bytecode.JNZ, 38,
    bytecode.PUSH, 3,
    bytecode.JMP, 58,

    bytecode.MOD, 2, 8,
    bytecode.JNZ, 47,
    bytecode.PUSH, 1,
    bytecode.JMP, 58,

    bytecode.MOD, 2, 9,
    bytecode.JNZ, 56,
    bytecode.PUSH, 2,
    bytecode.JMP, 58,

    bytecode.PUSHR, 2,
    bytecode.OUTPUT,

    bytecode.JMP, 19,
    bytecode.HALT
}

bytecode.examples.hello_world = {
    bytecode.PUSH, 1,
    bytecode.OUTPUT,
    bytecode.HALT
}

return bytecode