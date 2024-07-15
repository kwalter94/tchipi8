require "./errors"
require "./opcodes"

module Tchipi8
  BASE_16 = 16

  class InvalidInstruction < Tchipi8Error
    def initialize(instruction : UInt16)
      super("Could not decode instruction: 0x#{instruction.to_s(BASE_16)}")
    end
  end

  module Decoder
    def self.decode(instruction : UInt16) : Opcodes::Opcode
      case instruction & 0xF000
      when 0x0000
        case
        when instruction == Opcodes::CLS.opcode then Opcodes::CLS
        when instruction == Opcodes::RET.opcode then Opcodes::RET
        else Opcodes::JMPNAS
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
      when 0x8000
        case instruction | 0x8FF0
        when Opcodes::COPY.opcode then Opcodes::COPY
        when Opcodes::OR.opcode then Opcodes::OR
        when Opcodes::AND.opcode then Opcodes::AND
        when Opcodes::XOR.opcode then Opcodes::XOR
        when Opcodes::ADDV.opcode then Opcodes::ADDV
        when Opcodes::SUBV.opcode then Opcodes::SUBV
        when Opcodes::RSHIFT.opcode then Opcodes::RSHIFT
        when Opcodes::RSUB.opcode then Opcodes::RSUB
        when Opcodes::LSHIFT.opcode then Opcodes::LSHIFT
        else raise InvalidInstruction.new(instruction)
        end
      when 0x9000
        raise InvalidInstruction.new(instruction) unless (instruction & 0x000F).zero?

        Opcodes::SKIPIFNEQV
      when 0xA000 then Opcodes::SETI
      when 0xB000 then Opcodes::JMPREL
      when 0xC000 then Opcodes::RAND
      when 0xD000 then Opcodes::DRAW
      when 0xE000
        case instruction | 0x0F00
        when Opcodes::SKIPIFKEY.opcode then Opcodes::SKIPIFKEY
        when Opcodes::SKIPIFNKEY.opcode then Opcodes::SKIPIFNKEY
        else raise InvalidInstruction.new(instruction)
        end
      when 0xF000
        case instruction | 0x0F00
        when Opcodes::COPYDV.opcode then Opcodes::COPYDV
        when Opcodes::READKEY.opcode then Opcodes::READKEY
        when Opcodes::COPYVD.opcode then Opcodes::COPYVD
        when Opcodes::COPYVS.opcode then Opcodes::COPYVS
        when Opcodes::ADDI.opcode then Opcodes::ADDI
        when Opcodes::COPYVI.opcode then Opcodes::COPYVI
        when Opcodes::MOVMBCD.opcode then Opcodes::MOVMBCD
        when Opcodes::MOVM.opcode then Opcodes::MOVM
        when Opcodes::MOV.opcode then Opcodes::MOV
        else raise InvalidInstruction.new(instruction)
        end
      else
        raise InvalidInstruction.new(instruction)
      end
    end
  end
end
