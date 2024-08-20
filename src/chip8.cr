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

  MEGAHERTZ = 1000

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
    TIMER_TICK_PERIOD = Time::Span.new(nanoseconds: 1_000_000_000 // 60)

    property io : IO::Controller
    property pixels : Array(Array(UInt8))
    property pc : UInt16
    property i : UInt16
    property v : Array(UInt8)
    property sound_timer : UInt8
    property delay_timer : UInt8
    property memory : Array(UInt8)
    property stack : Array(UInt16)
    property hault : Bool
    property custom_flags : Hash(Symbol, Bool) # Used for storing state of instructions like READKEY

    def initialize(@io)
      @pixels = DISPLAY_HEIGHT.times.map { Array(UInt8).new(DISPLAY_WIDTH, 0) }.to_a
      @pc = PROGRAM_ADDRESS
      @i = 0
      @v = Array(UInt8).new(VREG_COUNT, 0)
      @sound_timer = 0
      @delay_timer = 0
      @memory = Array(UInt8).new(MAX_RAM, 0)
      @stack = Array(UInt16).new
      @last_tick = Time::Span.zero
      @hault = false
      @custom_flags = {} of Symbol => Bool

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

    def run(clock_mhz = 10) : Nil
      Log.debug { "Running Chip8..." }
      cycle_period = Time::Span.new(nanoseconds: 1_000_000_000 // (clock_mhz * MEGAHERTZ))
      last_clock_tick = last_timer_tick = Time.monotonic

      loop do
        @io.sync

        instruction = next_instruction
        opcode = Decoder.decode(instruction)
        execute_instruction(opcode, instruction)

        timer_ticks = (Time.monotonic - last_timer_tick).nanoseconds // TIMER_TICK_PERIOD.nanoseconds
        if timer_ticks > 0
          Log.debug { "Synchronising timers: +#{timer_ticks} ticks" }
          @io.flush_pixels
          @delay_timer -= timer_ticks > @delay_timer ? @delay_timer : timer_ticks
          @sound_timer -= timer_ticks > @sound_timer ? @sound_timer : timer_ticks
          last_timer_tick = Time.monotonic
        end

        time_elapsed = Time.monotonic - last_clock_tick
        sleep(cycle_period - time_elapsed) if time_elapsed < cycle_period
        last_clock_tick = Time.monotonic
      end
    end

    private def next_instruction : UInt16
      Log.debug { "Fetching instruction at #{@pc.to_s(16)}" }
      instruction = (memory[@pc].to_u16 << 8) | memory[@pc + 1]
      @pc += 2 unless @hault

      instruction
    end

    private def load_font
      Log.debug { "Loading font at #{FONT_ADDRESS.to_s(16)}" }
      FONT.each_with_index do |byte, offset|
        @memory[FONT_ADDRESS + offset] = byte
      end
    end

    private def execute_instruction(opcode : Opcodes::Opcode, instruction : UInt16) : Nil
      Log.debug { "Executing instruction #{opcode.name}(#{instruction.to_s(16)})" }
      start_time = Time.monotonic
      opcode.operation.call(self, instruction)
      time_elapsed = Time.monotonic - start_time
      return if opcode.micros.zero?

      if opcode.micros < time_elapsed
        Log.warn {
          "Slow instruction #{opcode.name} (took #{time_elapsed} instead of #{opcode.micros})"
        }
        return
      end

      sleep_time = opcode.micros - time_elapsed
      sleep(sleep_time)
      Log.debug {
        "#{opcode.name} executed in #{(time_elapsed + sleep_time).microseconds} micros"
      }
    end
  end
end
