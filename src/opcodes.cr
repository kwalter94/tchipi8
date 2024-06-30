require "./chip8"

module Tchipi8
  extend self

  # Chip 8 opcodes (sourced from https://chip8.gulrak.net/reference/opcodes/)
  #
  # vX, vY are used to represent general purpose registers (ie. v registers).
  # The X and Y are integers in range 0 to F. vA ... vF mean the actual 10th
  # to 16th registers. k means constant/immediate value (usually the last two
  # nibbles of the opcode).
  CLS = 0x00E0.to_u16        # Clear screen
  RET = 0x00EE.to_u16        # Return from subroutine
  JMPNAS = 0x0FFF.to_u16     # Jump to native assembler subroutine
  JMP = 0x1FFF.to_u16        # Jump to address
  CALL = 0x2FFF.to_u16       # Push current address onto stack and call subroutine
  SKIPIFEQ = 0x3FFF.to_u16   # Skip next opcode if vX register is equal to k
  SKIPIFNEQ = 0x4FFF.to_u16  # Skip next opcode if vX is not equal to k
  SKIPIFEQV = 0x5FF0.to_u16  # Skip next opcode if register vX == vY
  SET = 0x6FFF.to_u16        # Set register vX to k
  ADD = 0x7FFF.to_u16        # Add k to register vX
  COPY = 0x8FF0.to_u16       # Copy value from register vY into vX
  OR = 0x8FF1.to_u16         # Set vX to result of vX | vY
  AND = 0x8FF2.to_u16        # Set vX to result of vX & vY
  XOR = 0x8FF3.to_u16        # Set vX ro result of vX ^ vY
  ADDV = 0x8FF4.to_u16        # Set vX to result of vX + vY, setting vF to 0 or 1 if overflow or not even if X == F
  SUB = 0x8FF5.to_u16        # Set vX to result of vX - vY, setting vF to 0 or 1 if underflow or not even if X == F
  RSHIFT = 0x8FF6.to_u16     # Set vX to result of vY >> 1, setting vF to shifted out bit even if X == F
  RSUB = 0x8FF7.to_u16       # Set vX to result of vY - vX, setting vF to 0 or 1 if underflow or not even if X == F
  LSHIFT = 0x8FFE.to_u16     # Set vX to result of vY << 1, setting vF to shifted out bit even if X == F
  SKIPIFNEQV = 0x9FF0.to_u16 # Skip next opcode if vX != vY
  SETI = 0xAFFF.to_u16       # Set register I to k
  JMPREL = 0xBFFF.to_u16     # Jump to v0 + k
  RAND = 0xCFFF.to_u16       # Set vX to random value AND-ed with k
  DRAW = 0xDFFF.to_u16       # Draw sprite at position [vX, vY] using sprite data from location in register I
  SKIPIFKEY = 0xEF9E.to_u16  # Skip next opcode if key pressed matches lower 4 bits vX
  SKIPIFNKEY = 0xEFA1.to_u16 # Skip next opcode if lower 4 bits of vX don't match key pressed
  COPYDV = 0xFF07.to_u16     # Copy delay timer value to vX
  READKEY = 0xFF0A.to_u16    # Read next key pressed, write it to vX (clear screen in Megachip mode)
  COPYVD = 0xFF15.to_u16     # Set delay timer from vX
  COPYVS = 0xFF18.to_u16     # Set sound timer from vX (beep as long as sound timer > 0)
  ADDI = 0xFF1E.to_u16       # Add vX to I
  COPYVI = 0xFF29.to_u16     # Copy vX's low nibble to I
  MOVMBCD = 0xFF33.to_u16    # Copy vX as BCD to I[0,2]
  MOVM = 0xFF55.to_u16       # Copy v[0,X] to I[0,X]
  MOV = 0xFF65.to_u16        # Copy I[0,X] to v[0,X]


  record Opcode,
    opcode : UInt16,
    name : String,  # Human readable name for opcode
    micros : Int32, # Number of microseconds instruction takes
    operation : Chip8, UInt16 -> Nil


  OPCODES = [
    # Opcode timings sourced from https://jackson-s.me/2019/07/13/Chip-8-Instruction-Scheduling-and-Frequency.html
    Opcode.new(CLS, "cls", 109, ->(chip8 : Chip8, _instruction : UInt16) { clear_screen(chip8) }),
    Opcode.new(RET, "ret", 105, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    # Opcode.new(JMPNAS, "jmpnas", 105, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(JMP, "jmp", 105, ->(chip8 : Chip8, instruction : UInt16) { jump(chip8, instruction) }),
    Opcode.new(CALL, "call", 105, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFEQ, "skipifeq", 55, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFNEQ, "skipifneq", 55, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFEQV, "skipifeqv", 73, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SET, "set", 27, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(ADD, "add", 45, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(COPY, "copy", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(OR, "or", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(AND, "and", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(XOR, "xor", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(ADDV, "addv", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SUB, "sub", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(RSHIFT, "rshift", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(RSUB, "rsub", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(LSHIFT, "lshift", 200, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFNEQV, "skipifneqv", 73, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SETI, "seti", 55, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(JMPREL, "jmprel", 105, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(RAND, "rand", 164, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(DRAW, "draw", 22734, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFKEY, "skipifkey", 73, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(SKIPIFNKEY, "skipifnkey", 73, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(COPYDV, "copydv", 45, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(READKEY, "readkey", 0, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(COPYVD, "copyvd", 45, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(COPYVS, "copyvs", 45, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(ADDI, "addi", 86, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(COPYVI, "copyvi", 91, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(MOVMBCD, "movmbcd", 927, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(MOVM, "movm", 605, ->(_chip8 : Chip8, _instruction : UInt16) {}),
    Opcode.new(MOV, "mov", 605, ->(_chip8 : Chip8, _instruction : UInt16) {}),
  ]

  def extract_operand1(instruction : UInt16) : UInt16
    (instruction & 0x0F00) >> 8
  end

  def extract_operand2(instruction : UInt16) : UInt16
    (instruction & 0x00F0) >> 4
  end

  def extract_long_operand(instruction : UInt16) : UInt16
    instruction & 0x0FFF
  end

  def clear_screen(chip8 : Chip8); end

  def jump(chip8 : Chip8, instruction : UInt16); end
end
