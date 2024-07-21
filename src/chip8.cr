require "./io"

module Tchipi8
  ADDRESS_MASK = 0x0FFF # Addresses are 12 bytes long
  DISPLAY_WIDTH = 64
  DISPLAY_HEIGHT = 32
  MAX_RAM = 4096  # Bytes
  MAX_STACK = 16  # 16 bit words
  VREG_COUNT = 16 # Number of general purpose registers


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
      @pc = 0
      @i = 0
      @v = Array(UInt8).new(VREG_COUNT, 0)
      @sound_timer = 0
      @delay_timer = 0
      @memory = Array(UInt8).new(MAX_RAM, 0)
      @stack = Array(UInt16).new
    end

    def next_instruction : UInt16
      instruction = (memory[@pc].to_u16 << 8) | memory[@pc + 1]
      @pc += 2

      instruction
    end
  end
end
