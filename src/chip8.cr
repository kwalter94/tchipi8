require "./io"
require "./decoder"
require "./opcodes"

module Tchipi8
  ADDRESS_MASK = 0x0FFF # Addresses are 12 bytes long
  DISPLAY_WIDTH = 64
  DISPLAY_HEIGHT = 32
  MAX_RAM = 4096  # Bytes
  MAX_STACK = 16  # 16 bit words
  VREG_COUNT = 16 # Number of general purpose registers

  FONT_ADDRESS = 0x050.to_u16 # Start address of font
  PROGRAM_ADDRESS = 0x200.to_u16 # Start address of program

  # Sourced from https://tobiasvl.github.io/blog/write-a-chip-8-emulator/#font
  FONT = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
    0x20, 0x60, 0x20, 0x20, 0x70, # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
    0x90, 0x90, 0xF0, 0x10, 0x10, # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
    0xF0, 0x10, 0x20, 0x40, 0x40, # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
    0xF0, 0x80, 0x80, 0x80, 0xF0, # C
    0xE0, 0x90, 0x90, 0x90, 0xE0, # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
    0xF0, 0x80, 0xF0, 0x80, 0x80  # F
  ] of UInt8


  class Chip8
    property io : IO::Controller
    property pixels : Array(Array(UInt8))
    property pc : UInt16
    property i : UInt16
    property v : Array(UInt8)
    property sound_timer : UInt8
    property delay_timer : UInt8
    property memory : Array(UInt8)
    property stack : Array(UInt16)

    def initialize(@io)
      @pixels = DISPLAY_HEIGHT.times.map { Array(UInt8).new(DISPLAY_WIDTH, 0) }.to_a
      @pc = PROGRAM_ADDRESS
      @i = 0
      @v = Array(UInt8).new(VREG_COUNT, 0)
      @sound_timer = 0
      @delay_timer = 0
      @memory = Array(UInt8).new(MAX_RAM, 0)
      @stack = Array(UInt16).new

      self.load_font
    end

    def load_program(file : File) : Nil
      Log.debug { "Loading program at #{PROGRAM_ADDRESS}" }
      bytes_loaded = 0

      file.each_byte.each_with_index do |byte, offset|
        @memory[PROGRAM_ADDRESS + offset] = byte
        bytes_loaded = offset
      end

      Log.debug { "Loaded #{bytes_loaded} bytes program" }
    end

    def run : Nil
      Log.debug { "Running Chip8..." }
      loop do
        @io.sync
        instruction = next_instruction
        opcode = Decoder.decode(instruction)
        execute_instruction(opcode, instruction)

        sleep(1.0 / 60)
      end
    end


    def next_instruction : UInt16
      Log.debug { "Fetching instruction at #{@pc.to_s(16)}" }
      instruction = (memory[@pc].to_u16 << 8) | memory[@pc + 1]
      @pc += 2

      instruction
    end

    private def load_font
      Log.debug { "Loading font at #{FONT_ADDRESS.to_s(16)}" }
      FONT.each_with_index do |byte, offset|
        @memory[FONT_ADDRESS + offset] = byte
      end
    end

    private def execute_instruction(opcode : Opcodes::Opcode, instruction : UInt16) : Nil
      Log.debug { "Executing instruction #{opcode.name}(#{instruction})" }
      start_time = Time.monotonic
      opcode.operation.call(self, instruction)
      time_elapsed = Time.monotonic - start_time
      sleep_time = opcode.micros > time_elapsed ? opcode.micros - time_elapsed : Time::Span.zero
      sleep(sleep_time) unless sleep_time.zero?
      Log.debug {
        "Execution time: #{(time_elapsed + sleep_time).to_f * 1_000_000} micros"
      }
    end
  end
end
