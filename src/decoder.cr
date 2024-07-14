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
        if instruction == Opcodes::CLS.opcode
          Opcodes::CLS
        elsif instruction == Opcodes::RET.opcode
          Opcodes::RET
        else
          Opcodes::JMPNAS
        end
      when 0x1000 then Opcodes::JMP
      when 0x2000 then Opcodes::CALL
      when 0x3000 then Opcodes::SKIPIFEQ
      when 0x4000 then Opcodes::SKIPIFNEQ
      when 0x5000
        raise InvalidInstruction.new(instruction) unless (instruction & 0x000F).zero?

        Opcodes::SKIPIFEQV
      when 0x6000 then Opcodes::SET
      when 0x7000 then Opcodes::ADD
      else
        raise InvalidInstruction.new(instruction)
      end
    end
  end
end
