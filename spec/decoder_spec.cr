require "./spec_helper"

module Tchipi8
  describe Decoder do
    describe :decode do
      context "0x0FFF range instructions" do
        it "decodes CLS (0x00E0)" do
          Decoder.decode(0x00E0).opcode.should eq(Opcodes::CLS.opcode)
        end

        it "decodes RET (0x00EE)" do
          Decoder.decode(0x00EE).opcode.should eq(Opcodes::RET.opcode)
        end

        it "decodes JMPNAS" do
          Decoder.decode(0x0100).opcode.should eq(Opcodes::JMPNAS.opcode)
          Decoder.decode(0x00E1).opcode.should eq(Opcodes::JMPNAS.opcode)

          instruction = Random.new.rand(0x0FFF).to_u16
          if {Opcodes::CLS.opcode, Opcodes::RET.opcode}.includes?(instruction)
            Decoder.decode(instruction).opcode.should_not eq(Opcodes::JMPNAS.opcode)
          else
            Decoder.decode(instruction).opcode.should eq(Opcodes::JMPNAS.opcode)
          end
        end
      end
    end
  end
end
