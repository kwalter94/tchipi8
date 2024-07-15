require "./spec_helper"

module Tchipi8
  describe Decoder do
    describe :decode do
      context "0x0??? range instructions" do
        it "decodes CLS (0x00E0)" do
          Decoder.decode(0x00E0).should eq(Opcodes::CLS)
        end

        it "decodes RET (0x00EE)" do
          Decoder.decode(0x00EE).should eq(Opcodes::RET)
        end

        it "decodes JMPNAS (0x0???)" do
          (0x0000..0x0FFF).each do |instruction|
            next if instruction == Opcodes::CLS.opcode || instruction == Opcodes::RET.opcode

            Decoder.decode(instruction.to_u16).should eq(Opcodes::JMPNAS)
          end
        end
      end

      context "0x1??? range instructions" do
        it "decodes JMP (0x1???)" do
          (0x1000..0x1FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::JMP)
          end
        end
      end

      context "0x2??? range instructions" do
        it "decodes CALL (0x2???)" do
          (0x2000..0x2FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::CALL)
          end
        end
      end

      context "0x3??? range instructions" do
        it "decodes SKIPIFEQ (0x3???)" do
          (0x3000..0x3FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::SKIPIFEQ)
          end
        end
      end

      context "0x4??? range instructions" do
        it "decodes SKIPIFEQ (0x4???)" do
          (0x4000..0x4FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::SKIPIFNEQ)
          end
        end
      end

      context "0x5??? range instructions" do
        it "decodes SKIPIFEQV (0x5??0)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x5000 | registers << 4).to_u16
            Decoder.decode(instruction).should eq(Opcodes::SKIPIFEQV)
          end
        end

        it "raises InvalidInstruction for instruction 0x5??X where X in 1..F" do
          rng = Random.new
          (0x0001..0x000F).each do |x|
            (0x00..0xFF).each do |registers|
              instruction = (0x5000 | registers << 4 | x).to_u16
              expect_raises(InvalidInstruction) { Decoder.decode(instruction) }
            end
          end
        end
      end

      context "0x6??? range instructions" do
        it "decodes SET (0x6???)" do
          (0x6000..0x6FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::SET)
          end
        end
      end

      context "0x7??? range instructions" do
        it "decodes ADD (0x7???)" do
          (0x7000...0x7FFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::ADD)
          end
        end
      end

      context "0x8??? range instructions" do
        it "decodes COPY (0x8??0)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8000 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::COPY)
          end
        end

        it "decodes OR (0x8??1)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8001 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::OR)
          end
        end

        it "decodes AND (0x8??2)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8002 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::AND)
          end
        end

        it "decodes XOR (0x8??3)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8003 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::XOR)
          end
        end

        it "decodes ADDV (0x8??4)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8004 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::ADDV)
          end
        end

        it "decodes SUBV (0x8??5)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8005 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::SUBV)
          end
        end

        it "decodes RSHIFT (0x8??6)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8006 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::RSHIFT)
          end
        end

        it "decodes RSUB (0x8??7)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x8007 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::RSUB)
          end
        end

        it "decodes LSHIFT (0x8??E)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x800E | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::LSHIFT)
          end
        end

        it "raises InvalidInstruction on invalid instructions" do
          (0x8...0xE).each do |x| # Skip 0x8??E which is a valid instruction
            (0x00..0xFF).each do |registers|
              instruction = (0x8000 | registers << 4 | x).to_u16
              expect_raises(InvalidInstruction) { Decoder.decode(instruction) }
            end
          end

          (0x00..0xFF).each do |registers|
            expect_raises(InvalidInstruction) do
              instruction = (0x8000 | registers << 4 | 0xF).to_u16
              Decoder.decode(instruction)
            end
          end
        end
      end

      context "0x9??? range instructions" do
        it "decodes SKIPIFNEQV (0x9??0)" do
          (0x00..0xFF).each do |registers|
            instruction = (0x9000 | (registers << 4)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::SKIPIFNEQV)
          end
        end

        it "raises InvalidInstruction for instruction in 0x9??X where X in 1..F" do
          (0x00..0xFF).each do |registers|
            (0x1..0xF).each do |x|
              instruction = (0x9000 | (registers << 4) | x).to_u16
              expect_raises(InvalidInstruction) { Decoder.decode(instruction) }
            end
          end
        end
      end

      context "0xA??? range instructions" do
        it "decodes SETI (0xA???)" do
          (0xA000..0xAFFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::SETI)
          end
        end
      end

      context "0xB??? range instructions" do
        it "decodes JMPREL (0xB???)" do
          (0xB000..0xBFFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::JMPREL)
          end
        end
      end

      context "0xC??? range instructions" do
        it "decodes RAND (0xC???)" do
          (0xC000..0xCFFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::RAND)
          end
        end
      end

      context "0xD??? range instructions" do
        it "decodes DRAW (0xD???)" do
          (0xD000..0xDFFF).each do |instruction|
            Decoder.decode(instruction.to_u16).should eq(Opcodes::DRAW)
          end
        end
      end

      context "0xE??? range instructions" do
        it "decodes SKIPIFKEY (0xE?9E)" do
          (0x0..0xF).each do |register|
            instruction = (0xE09E | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::SKIPIFKEY)
          end
        end

        it "decodes SKIPIFNKEY (0xE?A1)" do
          (0x0..0xF).each do |register|
            instruction = (0xE0A1 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::SKIPIFNKEY)
          end
        end

        it "raises InvalidInstruction for non-existent 0xE??? opcodes" do
          (0xE000..0xEFFF).each do |instruction|
            masked = instruction | 0x0F00
            next if masked == Opcodes::SKIPIFKEY.opcode || masked == Opcodes::SKIPIFNKEY.opcode

            expect_raises(InvalidInstruction) { Decoder.decode(instruction.to_u16) }
          end
        end
      end

      context "0xF??? range instructions" do
        it "decodes COPYDV (0xF?07)" do
          (0x0..0xF).each do |register|
            instruction = (0xF007 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::COPYDV)
          end
        end

        it "decodes READKEY (0xF?0A)" do
          (0x0..0xF).each do |register|
            instruction = (0xF00A | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::READKEY)
          end
        end

        it "decodes COPYVD (0xF?15)" do
          (0x0..0xF).each do |register|
            instruction = (0xF015 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::COPYVD)
          end
        end

        it "decodes COPYVS (0xF?18)" do
          (0x0..0xF).each do |register|
            instruction = (0xF018 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::COPYVS)
          end
        end

        it "decodes ADDI (0xF?1E)" do
          (0x0..0xF).each do |register|
            instruction = (0xF01E | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::ADDI)
          end
        end

        it "decodes COPYVI (0xF?29)" do
          (0x0..0xF).each do |register|
            instruction = (0xF029 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::COPYVI)
          end
        end

        it "decodes MOVMBCD (0xF?33)" do
          (0x0..0xF).each do |register|
            instruction = (0xF033 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::MOVMBCD)
          end
        end

        it "decodes MOVM (0xF?55)" do
          (0x0..0xF).each do |register|
            instruction = (0xF055 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::MOVM)
          end
        end

        it "decodes MOV (0xF?65)" do
          (0x0..0xF).each do |register|
            instruction = (0xF065 | (register << 8)).to_u16
            Decoder.decode(instruction).should eq(Opcodes::MOV)
          end
        end

        it "raises InvalidInstruction for invalid 0xF??? range opcodes" do
          valid_opcodes = {
            Opcodes::COPYDV,
            Opcodes::READKEY,
            Opcodes::COPYVD,
            Opcodes::COPYVS,
            Opcodes::ADDI,
            Opcodes::COPYVI,
            Opcodes::MOVMBCD,
            Opcodes::MOVM,
            Opcodes::MOV,
          }.map(&.opcode)

          (0xF000...0xFFFF).each do |instruction|
            next if valid_opcodes.includes?(instruction | 0x0F00)

            expect_raises(InvalidInstruction) { Decoder.decode(instruction.to_u16) }
          end
        end
      end
    end
  end
end
