require "./spec_helper"

describe Tchipi8::InstructionDecoder do
  context :decode do
    it "decodes unparameterized instructions" do
      decoder = Tchipi8::InstructionDecoder.new

      decoder.decode(Tchipi8::CLS).opcode.should eq(Tchipi8::CLS)
      decoder.decode(Tchipi8::RET).opcode.should eq(Tchipi8::RET)
    end

    it "decodes parameterized instructions" do
      decoder = Tchipi8::InstructionDecoder.new

      decoder.decode(Tchipi8::JMP & 0xF042).opcode.should eq(Tchipi8::JMP)
      decoder.decode(Tchipi8::SKIPIFEQV & 0xF690).opcode.should eq(Tchipi8::SKIPIFEQV)
    end

    it "can decode overlapping opcodes" do
      decoder = Tchipi8::InstructionDecoder.new

      decoder.decode(Tchipi8::COPY & 0xF42F).opcode.should eq(Tchipi8::COPY)
      decoder.decode(Tchipi8::OR & 0xF42F).opcode.should eq(Tchipi8::OR)
      decoder.decode(Tchipi8::AND & 0xF42F).opcode.should eq(Tchipi8::AND)
      decoder.decode(Tchipi8::XOR & 0xF42F).opcode.should eq(Tchipi8::XOR)
      decoder.decode(Tchipi8::ADDV & 0xF42F).opcode.should eq(Tchipi8::ADDV)
    end

    it "raises error when passed an invalid instruction" do
      decoder = Tchipi8::InstructionDecoder.new

      expect_raises(Tchipi8::InvalidInstruction) { decoder.decode(0x0000) }
      expect_raises(Tchipi8::InvalidInstruction) { decoder.decode(0x0001) }
      expect_raises(Tchipi8::InvalidInstruction) { decoder.decode(0x00E1) }
      expect_raises(Tchipi8::InvalidInstruction) { decoder.decode(0xFF57) }
    end
  end
end
