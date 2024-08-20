require "time"

require "./chip8"

module Tchipi8
  module Opcodes
    extend self

    record Opcode,
      opcode : UInt16,
      name : String,  # Human readable name for opcode
      micros : Time::Span, # Number of microseconds instruction takes
      operation : (Chip8, UInt16) -> Nil

    def define_opcode(
      hex_code : UInt16,
      name : String,
      micros : Int32,
      &operation : (Chip8, UInt16) -> Nil
    )
      Opcode.new(
        hex_code,
        name,
        Time::Span.new(nanoseconds: micros * 1000),
        operation
      )
    end

    # The following are Chip 8 opcodes and their timings (cycles each opcode eats)
    #
    # vX, vY are used to represent general purpose registers (ie. v registers).
    # The X and Y are integers in range 0 to F. vA ... vF mean the actual 10th
    # to 16th registers. k means constant/immediate value (usually the last two
    # nibbles of the opcode).
    #
    # Ref:
    # - https://chip8.gulrak.net/reference/opcodes/
    # - https://jackson-s.me/2019/07/13/Chip-8-Instruction-Scheduling-and-Frequency.html

    # Clear screen
    CLS = define_opcode(0x00E0.to_u16, "cls", 109) do |chip8, instruction|
      (0...chip8.pixels.size).each do |row|
        (0...chip8.pixels[row].size).each do |col|
          chip8.pixels[row][col] = 0
        end
      end

      chip8.io.clear_pixels
    end

    # Return from subroutine
    RET = define_opcode(0x00EE.to_u16, "ret", 105) do |chip8, instruction|
      chip8.pc = chip8.stack.pop
    end

    # Jump to native assembler subroutine
    JMPNAS = define_opcode(0x0FFF.to_u16, "jmpnas", 105) do |chip8, instruction|
    end

    # Jump to address
    JMP = define_opcode(0x1FFF.to_u16, "jmp", 105) do |chip8, instruction|
      chip8.pc = instruction & 0x0FFF
      Log.debug { "Jumped to #{chip8.pc.to_s(16)}" }
    end

    # Push current address onto stack and call subroutine
    CALL = define_opcode(0x2FFF.to_u16, "call", 105) do |chip8, instruction|
      chip8.stack.push(chip8.pc)
      chip8.pc = instruction & 0x0FFF
      Log.debug { "Jumped to #{chip8.pc.to_s(16)}" }
    end

    # Skip next opcode if vX register is equal to k
    SKIPIFEQ = define_opcode(0x3FFF.to_u16, "skipifeq", 55) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      k = instruction & 0x00FF

      chip8.pc += 2 if chip8.v[x] == k
    end

    # Skip next opcode if vX is not equal to k
    SKIPIFNEQ = define_opcode(0x4FFF.to_u16, "skipifneq", 55) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      k = instruction & 0x00FF

      chip8.pc += 2 if chip8.v[x] != k
    end

    # Skip next opcode if register vX == vY
    SKIPIFEQV = define_opcode(0x5FF0.to_u16, "skipifeqv", 73) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      chip8.pc += 2 if chip8.v[x] == chip8.v[y]
    end

    # Set register vX to k
    SET = define_opcode(0x6FFF.to_u16, "set", 27) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.v[x] = (instruction & 0x00FF).to_u8
    end

    # Add k to register vX
    ADD = define_opcode(0x7FFF.to_u16, "add", 45) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      k = instruction & 0x00FF
      chip8.v[x] = ((chip8.v[x].to_u16 + k) & 0xFF).to_u8
    end

    # Copy value from register vY into vX
    COPY = define_opcode(0x8FF0.to_u16, "copy", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4
      chip8.v[x] = chip8.v[y]
    end

    # Set vX to result of vX | vY
    OR = define_opcode(0x8FF1.to_u16, "or", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4
      chip8.v[x] |= chip8.v[y]
      chip8.v[0xF] = 0
    end

    # Set vX to result of vX & vY
    AND = define_opcode(0x8FF2.to_u16, "and", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4
      chip8.v[x] &= chip8.v[y]
      chip8.v[0xF] = 0
    end

    # Set vX to result of vX ^ vY
    XOR = define_opcode(0x8FF3.to_u16, "xor", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4
      chip8.v[x] ^= chip8.v[y]
      chip8.v[0xF] = 0
    end

    # Set vX to result of vX + vY, setting vF to 0 or 1 if overflow or not even if X == F
    ADDV = define_opcode(0x8FF4.to_u16, "addv", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4
      result = chip8.v[x].to_u16 + chip8.v[y]

      chip8.v[x] = (result & 0xFF).to_u8
      chip8.v[0xF] = (result > 0xFF ? 1 : 0).to_u8
    end

    # Set vX to result of vX - vY, setting vF to 0 or 1 if underflow or not even if X == F
    SUBV = define_opcode(0x8FF5.to_u16, "sub", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      is_underflowing = chip8.v[x] < chip8.v[y]
      chip8.v[x] = chip8.v[x] &- chip8.v[y]
      chip8.v[0xF] = (is_underflowing ? 0 : 1).to_u8
    end

    # Set vX to result of vY >> 1, setting vF to shifted out bit even if X == F
    RSHIFT = define_opcode(0x8FF6.to_u16, "rshift", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      shifted_out = chip8.v[y] & 0x01
      chip8.v[x] = chip8.v[y] >> 1
      chip8.v[0xF] = shifted_out
    end

    # Set vX to result of vY - vX, setting vF to 0 or 1 if underflow or not even if X == F
    RSUBV = define_opcode(0x8FF7.to_u16, "rsub", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      is_underflowing = chip8.v[y] < chip8.v[x]
      chip8.v[x] = chip8.v[y] &- chip8.v[x]
      chip8.v[0xF] = (is_underflowing ? 0 : 1).to_u8
    end

    # Set vX to result of vY << 1, setting vF to shifted out bit even if X == F
    LSHIFT = define_opcode(0x8FFE.to_u16, "lshift", 200) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      shifted_out = (chip8.v[y] & 0x80) >> 7
      chip8.v[x] = chip8.v[y] << 1
      chip8.v[0xF] = shifted_out
    end

    # Skip next opcode if vX != vY
    SKIPIFNEQV = define_opcode(0x9FF0.to_u16, "skipifneqv", 73) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      y = (instruction & 0x00F0) >> 4

      chip8.pc += 2 if chip8.v[x] != chip8.v[y]
    end

    # Set register I to k
    SETI = define_opcode(0xAFFF.to_u16, "seti", 55) do |chip8, instruction|
      chip8.i = 0x0FFF.to_u16 & instruction
    end

    # Jump to v0 + k
    JMPREL = define_opcode(0xBFFF.to_u16, "jmprel", 105) do |chip8, instruction|
      n = instruction & 0x0FFF
      chip8.pc = chip8.v[0].to_u16 + n
    end

    # Set vX to random value AND-ed with k (byte)
    RAND = define_opcode(0xCFFF.to_u16, "rand", 164) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      n = instruction & 0x00FF

      chip8.v[x] = (Random.new.rand(0xFF) & n).to_u8
    end

    # Draw sprite at position [vX, vY] using sprite data from location I[0..N]
    DRAW = define_opcode(0xDFFF.to_u16, "draw", 8333) do |chip8, instruction|
      x = (0x0F00 & instruction) >> 8
      y = (0x00F0 & instruction) >> 4
      n = 0x000F & instruction

      dirty_pixels = [] of Tuple(Int32, Int32)
      has_unset_pixel = false

      start_x = (chip8.v[x] % IO::CHIP8_DISPLAY_WIDTH).to_i32
      start_y = (chip8.v[y] % IO::CHIP8_DISPLAY_HEIGHT).to_i32

      (0...n).each do |row|
        pixmap = chip8.memory[chip8.i + row]

        (0...8).each do |col|
          pixel = (pixmap >> 8 - col - 1) & 0x01

          adjusted_col = start_x + col
          adjusted_row = start_y + row

          if adjusted_row >= chip8.pixels.size || adjusted_col >= chip8.pixels[0].size
            Log.warn { "Attempted to write out of bounds: (#{adjusted_col}, #{adjusted_row})" }
            break
          end

          if pixel == 1 && chip8.pixels[adjusted_row][adjusted_col] == 1
            has_unset_pixel = true
          end

          chip8.pixels[adjusted_row][adjusted_col] ^= pixel
          dirty_pixels << {adjusted_col, adjusted_row}
        end
      end

      chip8.v[0xF] = 1 if has_unset_pixel

      dirty_pixels.each do |col, row|
        chip8.io.set_pixel(
          col,
          row,
          chip8.pixels[row][col].zero? ? IO::PixelState::Off : IO::PixelState::On
        )
      end
    end

    # Skip next opcode if key pressed matches lower 4 bits of vX
    SKIPIFKEY = define_opcode(0xEF9E.to_u16, "skipifkey", 73) do |chip8, instruction|
      x = (0x0F00 & instruction) >> 8

      chip8.io.read_key.try do |key|
        if (key[:key] == chip8.v[x] & 0x0F) && key[:state].pressed?
          chip8.pc += 2
        end
      end
    end

    # Skip next opcode if lower 4 bits of vX don't match key pressed
    SKIPIFNKEY = define_opcode(0xEFA1.to_u16, "skipifnkey", 73) do |chip8, instruction|
      x = (0x0F00 & instruction) >> 8

      key = chip8.io.read_key
      if key.nil? || (key[:key] != (chip8.v[x] & 0x0F) && key[:state].pressed?)
        chip8.pc += 2
      end
    end

    # Copy delay timer value to vX
    SETVD = define_opcode(0xFF07.to_u16, "setvd", 45) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.v[x] = chip8.delay_timer
    end

    # Read next key pressed, write it to vX (clear screen in Megachip mode)
    READKEY = define_opcode(0xFF0A.to_u16, "readkey", 0) do |chip8, instruction|
      unless chip8.hault
        chip8.pc -= 2
        chip8.hault = true
        chip8.custom_flags[:key_read] = false
      end

      key = chip8.io.read_key

      if key && key[:state].released?
        x = (0x0F00 & instruction) >> 8
        chip8.v[x] = key[:key]
        chip8.custom_flags[:key_read] = true
        chip8.sound_timer = 1
      elsif chip8.custom_flags[:key_read] && chip8.sound_timer == 0
        chip8.hault = false
        chip8.pc += 2
        chip8.custom_flags.delete(:key_read)
      end
    end

    # Set delay timer from vX
    SETDV = define_opcode(0xFF15.to_u16, "setdv", 45) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.delay_timer = chip8.v[x]
    end

    # Set sound timer from vX (beep as long as sound timer > 0)
    SETSV = define_opcode(0xFF18.to_u16, "setsv", 45) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.sound_timer = chip8.v[x]
    end

    # Add vX to I
    ADDI = define_opcode(0xFF1E.to_u16, "addi", 86) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.i &+= chip8.v[x]
    end

    # Copy vX's low nibble to I
    SETIV = define_opcode(0xFF29.to_u16, "setiv", 91) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8
      chip8.i = 0x0F.to_u16 & chip8.v[x]
    end

    # Copy vX as BCD to I[0,2]
    MOVMBCD = define_opcode(0xFF33.to_u16, "movmbcd", 927) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8

      # No information on what do when I is out of bounds, doing nothing
      # feels like a lesser evil than anything else
      rem = chip8.v[x]
      chip8.memory[chip8.i], rem = rem.divmod(100) if chip8.i < chip8.memory.size
      chip8.memory[chip8.i + 1], rem = rem.divmod(10) if chip8.i + 1 < chip8.memory.size
      chip8.memory[chip8.i + 2] = rem % 10 if chip8.i + 2 < chip8.memory.size
    end

    # Copy v[0,X] to I[0,X]
    MOVM = define_opcode(0xFF55.to_u16, "movm", 605) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8

      (0..x).each do |i|
        break if chip8.i + i >= chip8.memory.size

        chip8.memory[chip8.i + i] = chip8.v[i]
      end
    end

    # Copy I[0,X] to v[0,X]
    MOV = define_opcode(0xFF65.to_u16, "mov", 605) do |chip8, instruction|
      x = (instruction & 0x0F00) >> 8

      (0..x).each do |i|
        break if chip8.i + i >= chip8.memory.size

        chip8.v[i] = chip8.memory[chip8.i + i]
      end
    end
  end
end
