require "./chip8"

module Tchipi8
  module Opcodes
    extend self

    # Chip 8 opcodes (sourced from https://chip8.gulrak.net/reference/opcodes/)
    #
    # vX, vY are used to represent general purpose registers (ie. v registers).
    # The X and Y are integers in range 0 to F. vA ... vF mean the actual 10th
    # to 16th registers. k means constant/immediate value (usually the last two
    # nibbles of the opcode).
    #   0001
    # Clear screen


    record Opcode,
      opcode : UInt16,
      name : String,  # Human readable name for opcode
      micros : Int32, # Number of microseconds instruction takes
      operation : (Chip8, UInt16) -> Nil

    macro define_opcode(hex_code, name, micros, method_name)
      Opcode.new(
        {{hex_code}},
        {{name}},
        {{micros}},
        ->(chip8: Chip8, instruction : UInt16) { {{method_name}}(chip8, instruction) }
      )
    end


    # Opcode timings sourced from https://jackson-s.me/2019/07/13/Chip-8-Instruction-Scheduling-and-Frequency.html
    CLS = define_opcode(0x00E0.to_u16, "cls", 109, clear_screen)
    RET = define_opcode(0x00EE.to_u16, "ret", 105, return_from_sub)
    JMPNAS = define_opcode(0x0FFF.to_u16, "jmpnas", 105, jump_to_nas)
    JMP = define_opcode(0x1FFF.to_u16, "jmp", 105, jump)
    CALL = define_opcode(0x2FFF.to_u16, "call", 105, call)
    SKIPIFEQ = define_opcode(0x3FFF.to_u16, "skipifeq", 55, skip_if_vx_eq_const)
    SKIPIFNEQ = define_opcode(0x4FFF.to_u16, "skipifneq", 55, skip_if_vx_neq_const)
    SKIPIFEQV = define_opcode(0x5FF0.to_u16, "skipifeqv", 73, skip_if_vx_eq_vy)
    SET = define_opcode(0x6FFF.to_u16, "set", 27, set_vx_to_const)
    ADD = define_opcode(0x7FFF.to_u16, "add", 45, add_const_to_vx)
    COPY = define_opcode(0x8FF0.to_u16, "copy", 200, copy_vy_to_vx)
    OR = define_opcode(0x8FF1.to_u16, "or", 200, or_vx_vy)
    AND = define_opcode(0x8FF2.to_u16, "and", 200, and_vx_vy)
    XOR = define_opcode(0x8FF3.to_u16, "xor", 200, xor_vx_vy)
    ADDV = define_opcode(0x8FF4.to_u16, "addv", 200, add_vy_to_vx)
    SUBV = define_opcode(0x8FF5.to_u16, "sub", 200, sub_vy_from_vx)
    RSHIFT = define_opcode(0x8FF6.to_u16, "rshift", 200, right_shift_vy_to_vx)
    RSUB = define_opcode(0x8FF7.to_u16, "rsub", 200, sub_vx_from_vy)
    LSHIFT = define_opcode(0x8FFE.to_u16, "lshift", 200, left_shift_vy_to_vx)
    SKIPIFNEQV = define_opcode(0x9FF0.to_u16, "skipifneqv", 73, skip_if_vx_neq_vy)
    SETI = define_opcode(0xAFFF.to_u16, "seti", 55, set_i_to_const)
    JMPREL = define_opcode(0xBFFF.to_u16, "jmprel", 105, jump_rel)
    RAND = define_opcode(0xCFFF.to_u16, "rand", 164, set_vx_to_rand)
    DRAW = define_opcode(0xDFFF.to_u16, "draw", 22734, draw)
    SKIPIFKEY = define_opcode(0xEF9E.to_u16, "skipifkey", 73, skip_if_key_pressed)
    SKIPIFNKEY = define_opcode(0xEFA1.to_u16, "skipifnkey", 73, skip_if_other_key_pressed)
    COPYDV = define_opcode(0xFF07.to_u16, "copydv", 45, copy_delay_timer_to_vx)
    READKEY = define_opcode(0xFF0A.to_u16, "readkey", 0, read_key)
    COPYVD = define_opcode(0xFF15.to_u16, "copyvd", 45, set_delay_timer_to_vx)
    COPYVS = define_opcode(0xFF18.to_u16, "copyvs", 45, set_sound_timer_to_vx)
    ADDI = define_opcode(0xFF1E.to_u16, "addi", 86, add_vx_to_i)
    COPYVI = define_opcode(0xFF29.to_u16, "copyvi", 91, set_i_to_low_vx)
    MOVMBCD = define_opcode(0xFF33.to_u16, "movmbcd", 927, move_vx_as_bcd_to_mem)
    MOVM = define_opcode(0xFF55.to_u16, "movm", 605, move_v_array_to_mem)
    MOV = define_opcode(0xFF65.to_u16, "mov", 605, move_mem_array_to_v)

    def extract_operand1(instruction : UInt16) : UInt16
      (instruction & 0x0F00) >> 8
    end

    def extract_operand2(instruction : UInt16) : UInt16
      (instruction & 0x00F0) >> 4
    end

    def extract_long_operand(instruction : UInt16) : UInt16
      instruction & 0x0FFF
    end

    # Clear screen
    def clear_screen(chip8 : Chip8, _instruction) : Nil
      chip8.display.clear
    end

    # Return from subroutine
    def return_from_sub(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Jump to native assembler subroutine
    def jump_to_nas(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Jump to address
    def jump(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Push current address onto stack and call subroutine
    def call(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if vX register is equal to k
    def skip_if_vx_eq_const(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if vX is not equal to k
    def skip_if_vx_neq_const(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if register vX == vY
    def skip_if_vx_eq_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set register vX to k
    def set_vx_to_const(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Add k to register vX
    def add_const_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end


    # Copy value from register vY into vX
    def copy_vy_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vX | vY
    def or_vx_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vX & vY
    def and_vx_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vX ^ vY
    def xor_vx_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vX + vY, setting vF to 0 or 1 if overflow or not even if X == F
    def add_vy_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vX - vY, setting vF to 0 or 1 if underflow or not even if X == F
    def sub_vy_from_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vY >> 1, setting vF to shifted out bit even if X == F
    def right_shift_vy_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vY - vX, setting vF to 0 or 1 if underflow or not even if X == F
    def sub_vx_from_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to result of vY << 1, setting vF to shifted out bit even if X == F
    def left_shift_vy_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if vX != vY
    def skip_if_vx_neq_vy(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set register I to k
    def set_i_to_const(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Jump to v0 + k
    def jump_rel(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set vX to random value AND-ed with k (byte)
    def set_vx_to_rand(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Draw sprite at position [vX, vY] using sprite data from location in register I
    def draw(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if key pressed matches lower 4 bits vX
    def skip_if_key_pressed(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Skip next opcode if lower 4 bits of vX don't match key pressed
    def skip_if_other_key_pressed(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Copy delay timer value to vX
    def copy_delay_timer_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Read next key pressed, write it to vX (clear screen in Megachip mode)
    def read_key(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set delay timer from vX
    def set_delay_timer_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Set sound timer from vX (beep as long as sound timer > 0)
    def set_sound_timer_to_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Add vX to I
    def add_vx_to_i(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Copy vX's low nibble to I
    def set_i_to_low_vx(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Copy vX as BCD to I[0,2]
    def move_vx_as_bcd_to_mem(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Copy v[0,X] to I[0,X]
    def move_v_array_to_mem(chip8 : Chip8, instruction : UInt16) : Nil
    end

    # Copy I[0,X] to v[0,X]
    def move_mem_array_to_v(chip8 : Chip8, instruction : UInt16) : Nil
    end
  end
end
