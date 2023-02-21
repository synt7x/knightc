# knightc
Faithful[*](#Differences) [Knight](https://github.com/knight-lang/knight-lang) optimizing compiler targeting x86, x86-64, AArch64, and ARM. Compiles Knight programs into static executables for Windows and Linux, without any undefined behavior.

### Usage

To run knightc, you must atleast have [Lua 5.1](https://lua.org) installed. If you have Lua installed, you can run:
```sh
lua main.lua
```
This invokes knightc, and all arguments can directly follow the main command. Below is a list of compiler options:

* *-o \<file>* (default: *a.out*)
    * Specifies the file that the final compilation pass will output to. Can be either a relative or specific path.
* *-P, --pass \<pass>* (default: *codegen*)
    * Specifies which pass in compilation will be the final pass. Once that pass is reached, compilation stops and the output of that pass is placed in the output file.
        * tokens, ast, symbols, types, intermediate, codegen
* *-f, --format \<format>* (default is your current platform)
    * Specifies the executable format of the final codegen pass, and will default to the executable format most commonly used by your operating system.
        * elf, pe
* *-t, --target \<target>* (default is your current platform)
    * Specifies the executable instruction set; note that this is different from the file format. This value defaults to the instruction set most commonly used by your operating system.
        * x64, x86, arm, aarch64

### Differences
Due to knightc being a compiler, not everything is going to follow the Knight specification exactly. Here are the major differences:
* Programs must return a boolean, number, or null (no coercion) in order to produce an exit code.
* Command line input for the compiler will differ from a standard Knight interpreter, as the compiler does not execute code. For more information read [Usage](#Usage).
* Undefined behavior is handled directly by the compiler, and is ensured by typechecking. Undefined behavior *should* result in an exception at compile time.
* The `arg` variable is populated with a list of strings containing the arguments provided to the program.