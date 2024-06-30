module Tchipi8
  ADDRESS_MASK = 0x0FFF # Addresses are 12 bytes long
  MAX_RAM = 4096  # Bytes
  MAX_STACK = 16  # 16 bit words
  VREG_COUNT = 16 # Number of general purpose registers


  class Chip8
    property pc : UInt16
    property l : UInt16
    property v : Array(UInt8)
    property sound_timer : UInt8
    property delay_timer : UInt8
    property memory : Array(UInt8)
    property stack : Array(UInt16)

    def initialize
      @pc = 0
      @l = 0
      @v = Array.new(VREG_COUNT, 0)
      @sound_timer = 0
      @delay_timer = 0
      @memory = Array.new(MAX_RAM, 0)
      @stack = Array.new(MAX_STACK, 0)
    end
  end
end
