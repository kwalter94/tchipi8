require "./errors"
require "./opcodes"

module Tchipi8
  class InvalidInstruction < Tchipi8Error; end

  class InstructionDecoder
    def initialize(opcodes : Array(Opcode) = OPCODES)
      @opcodes_tab = {} of UInt16 => Array(Opcode)

      opcodes.each do |opcode|
        index = opcode.opcode & 0xF000
        @opcodes_tab[index] = [] of Opcode unless @opcodes_tab.has_key?(index)

        @opcodes_tab[index] << opcode
      end
    end

    def decode(instruction : UInt16) : Opcode
      raise InvalidInstruction.new if instruction == 0

      index = instruction & 0xF000
      opcodes = @opcodes_tab[index]?
      raise InvalidInstruction.new if opcodes.nil?

      opcodes.each do |opcode|
        return opcode if ~opcode.opcode & instruction == 0
      end

      raise InvalidInstruction.new
    end
  end
end
