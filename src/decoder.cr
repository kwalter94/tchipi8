require "./errors"
require "./opcodes"

module Tchipi8
  BASE_16 = 16

  class InvalidInstruction < Tchipi8Error
    def initialize(instruction : UInt16)
      super(instruction.to_s(BASE_16))
    end
  end

  module Decoder
    def self.decode(instruction : UInt16) : Opcodes::Opcode
      case instruction & 0xF000
      when 0x0000
        return Opcodes::CLS if instruction == Opcodes::CLS.opcode

        return Opcodes::RET if instruction == Opcodes::RET.opcode

        return Opcodes::JMPNAS
      else
        raise InvalidInstruction.new(instruction)
      end
    end
  end
end
