require "./spec_helper"

module Tchipi8
  describe Decoder do
    describe :decode do
      context "0x0FFF range instructions" do
        it "decodes CLS (0x00E0)" do
          Decoder.decode(0x00E0).should eq(Opcodes::CLS)
        end

        it "decodes RET (0x00EE)" do
          Decoder.decode(0x00EE).should eq(Opcodes::RET)
        end

        it "decodes JMPNAS (0x0???)" do
          Decoder.decode(0x0100).should eq(Opcodes::JMPNAS)
          Decoder.decode(0x00E1).should eq(Opcodes::JMPNAS)

          instruction = Random.new.rand(0x0FFF).to_u16
          if {Opcodes::CLS, Opcodes::RET}.includes?(instruction)
            Decoder.decode(instruction).should_not eq(Opcodes::JMPNAS)
          else
            Decoder.decode(instruction).should eq(Opcodes::JMPNAS)
          end
        end
      end

      context "0x1FFF range instructions" do
        it "decodes JMP (0x1???)" do
          instruction = Random.new.rand(0x1000..0x1FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::JMP)
        end
      end

      context "0x2FFF range instructions" do
        it "decodes CALL (0x2???)" do
          instruction = Random.new.rand(0x2000..0x2FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::CALL)
        end
      end

      context "0x3FFF range instructions" do
        it "decodes SKIPIFEQ (0x3???)" do
          instruction = Random.new.rand(0x3000..0x3FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::SKIPIFEQ)
        end
      end

      context "0x4FFF range instructions" do
        it "decodes SKIPIFEQ (0x4???)" do
          instruction = Random.new.rand(0x4000..0x4FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::SKIPIFNEQ)
        end
      end

      context "0x5FF0 range instructions" do
        it "decodes SKIPIFEQV (0x5??0)" do
          registers = Random.new.rand(0x00..0xFF)
          instruction = (0x5000 | registers << 4).to_u16
          Decoder.decode(instruction).should eq(Opcodes::SKIPIFEQV)
        end

        it "raises InvalidInstruction for instruction 0x5??X where X in 1..F" do
          rng = Random.new
          x = rng.rand(0x0001..0x000F)
          registers = rng.rand(0x00..0xFF)
          instruction = (0x5000 | registers << 4 | x).to_u16
          expect_raises(InvalidInstruction) { Decoder.decode(instruction) }
        end
      end

      context "0x6FFF range instructions" do
        it "decodes SET (0x6???)" do
          instruction = Random.new.rand(0x6000..0x6FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::SET)
        end
      end

      context "0x7FFF range instructions" do
        it "decodes ADD (0x7???)" do
          instruction = Random.new.rand(0x7000..0x7FFF).to_u16
          Decoder.decode(instruction).should eq(Opcodes::ADD)
        end
      end
    end
  end
end
