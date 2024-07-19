require "./spec_helper"

module Tchipi8
  class DummyIOController
    include IO::Controller

    def clear_display : Nil
    end

    def draw_sprite(x, y, colour) : Nil
    end

    def read_key : UInt8
      0xF
    end

    def sync : Nil
    end
  end

  describe Opcodes do
    describe "JMP" do
      it "sets PC to provided address" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x1000..0x1FFF).each do |instruction|
          Opcodes::JMP.operation.call(chip8, instruction.to_u16)
          chip8.pc.should eq(instruction & 0x0FFF)
        end
      end
    end

    describe "SET" do
      it "sets vx to provided value" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |register|
          (0x00..0xFF).each do |k|
            instruction = (0x6000 | register << 8 | k).to_u16
            Opcodes::SET.operation.call(chip8, instruction)

            chip8.v[register].should eq(instruction & 0x00FF)
          end
        end
      end
    end

    describe "ADD" do
      it "correctly adds without overflowing" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |register|
          (0..127).each do |k|
            chip8.v[register] = k.to_u8
            instruction = (0x7000 | register << 8 | k).to_u16
            Opcodes::ADD.operation.call(chip8, instruction)

            chip8.v[register].should eq(k * 2)
          end
        end
      end

      it "wraps around on overflow" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |register|
          (1..255).each do |k|
            chip8.v[register] = 255
            instruction = (0x7000 | register << 8 | k).to_u16
            Opcodes::ADD.operation.call(chip8, instruction)

            chip8.v[register].should eq(k - 1)
          end
        end
      end
    end

    describe "COPY" do
      it "copies from register vY to register vX" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            value = rng.rand(256).to_u8
            chip8.v[register_y] = value
            instruction = (0x8000 | register_x << 8 | register_y << 4).to_u16
            Opcodes::COPY.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value)
          end
        end
      end
    end

    describe "OR" do
      it "sets vX to value of bitwise OR between vX and vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            chip8.v[register_x] = value_x = rng.rand(256).to_u8
            chip8.v[register_y] = value_y = register_x == register_y ? value_x : rng.rand(256).to_u8

            instruction = (0x8001 | (register_x << 8) | (register_y << 4)).to_u16
            Opcodes::OR.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_x | value_y)
          end
        end
      end
    end

    describe "AND" do
      it "sets vX to value of bitwise AND between vX and vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            chip8.v[register_x] = value_x = rng.rand(256).to_u8
            chip8.v[register_y] = value_y = register_x == register_y ? value_x : rng.rand(256).to_u8

            instruction = (0x8002 | (register_x << 8) | (register_y << 4)).to_u16
            Opcodes::AND.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_x & value_y)
          end
        end
      end
    end

    describe "XOR" do
      it "sets vX to value of bitwise XOR between vX and vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            chip8.v[register_x] = value_x = rng.rand(256).to_u8
            chip8.v[register_y] = value_y = register_x == register_y ? value_x : rng.rand(256).to_u8

            instruction = (0x8003 | register_x << 8 | register_y << 4).to_u16
            Opcodes::XOR.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_x ^ value_y)
          end
        end
      end
    end

    describe "ADDV" do
      it "correctly adds vX and vY without overflowing" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = rng.rand(128).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? chip8.v[register_x] : rng.rand(128).to_u8

            instruction = (0x8004 | register_x << 8 | register_y << 4).to_u16
            Opcodes::ADDV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_x + value_y)
          end
        end
      end

      it "sets vF to 0 when there is no overflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = rng.rand(128).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? chip8.v[register_x] : rng.rand(128).to_u8

            instruction = (0x8004 | register_x << 8 | register_y << 4).to_u16
            Opcodes::ADDV.operation.call(chip8, instruction)

            chip8.v[0xF].should eq(0)
          end
        end
      end

      it "wraps around on overflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = 255.to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? chip8.v[register_x] : rng.rand(255).to_u8 + 1

            instruction = (0x8004 | register_x << 8 | register_y << 4).to_u16
            Opcodes::ADDV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_y - 1)
          end
        end
      end

      it "sets vF to 1 on overflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = 255.to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? chip8.v[register_x] : (rng.rand(255).to_u8 + 1)

            instruction = (0x8004 | register_x << 8 | register_y << 4).to_u16
            Opcodes::ADDV.operation.call(chip8, instruction)

            chip8.v[0xF].should eq(1)
          end
        end
      end
    end

    describe "CALL" do
      it "sets PC to specified address" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x2000..0x2FFF).each do |instruction|
          Opcodes::CALL.operation.call(chip8, instruction.to_u16)
          chip8.pc.should eq(instruction & 0x0FFF)
        end
      end

      it "pushes current address onto stack" do
        rng = Random.new

        (0x2000..0x2FFF).each do |instruction|
          chip8 = Chip8.new(DummyIOController.new)
          chip8.pc = current_address = rng.rand(0xFFF).to_u16

          Opcodes::CALL.operation.call(chip8, instruction.to_u16)
          chip8.stack.size.should be > 0
          chip8.stack[-1].should eq(current_address)
        end
      end
    end

    describe "SKIPIFEQ" do
      it "increments PC by two if vX = k" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          chip8.pc = address = rng.rand(0xFFF).to_u16
          chip8.v[x] = rng.rand(0xFF).to_u8
          instruction = (0x3000 | x << 8 | chip8.v[x]).to_u16

          Opcodes::SKIPIFEQ.operation.call(chip8, instruction)
          chip8.pc.should eq(address + 2)
        end
      end

      it "does not modify PC if vX != k" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          chip8.pc = address = rng.rand(0xFFF).to_u16
          chip8.v[x] = rng.rand(0xFE).to_u8
          instruction = (0x3000 | x << 8 | chip8.v[x] + 1).to_u16

          Opcodes::SKIPIFEQ.operation.call(chip8, instruction)
          chip8.pc.should eq(address)
        end
      end
    end

    describe "SKIPIFNEQ" do
      it "increments PC by two if vX != k" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          chip8.pc = address = rng.rand(0xFFF).to_u16
          chip8.v[x] = rng.rand(0xFE).to_u8
          instruction = (0x4000 | x << 8 | chip8.v[x] + 1).to_u16

          Opcodes::SKIPIFNEQ.operation.call(chip8, instruction)
          chip8.pc.should eq(address + 2)
        end
      end

      it "does not modify PC if vX == k" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          chip8.pc = address = rng.rand(0xFFF).to_u16
          chip8.v[x] = rng.rand(0xFF).to_u8
          instruction = (0x4000 | x << 8 | chip8.v[x]).to_u16

          Opcodes::SKIPIFNEQ.operation.call(chip8, instruction)
          chip8.pc.should eq(address)
        end
      end
    end

    describe "SKIPIFEQV" do
      it "increments PC by two if vX == vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          (0x0..0xF).each do |y|
            chip8.pc = address = rng.rand(0xFFF).to_u16
            chip8.v[x] = chip8.v[y] = rng.rand(0xFF).to_u8
            instruction = (0x5000 | x << 8 | x << 4).to_u16

            Opcodes::SKIPIFEQV.operation.call(chip8, instruction)
            chip8.pc.should eq(address + 2)
          end
        end
      end

      it "does not modify PC if vX != vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          (0x0..0xF).each do |y|
            next if x == y

            chip8.pc = address = rng.rand(0xFFF).to_u16
            chip8.v[x] = rng.rand(0xFE).to_u8
            chip8.v[y] = chip8.v[x] + 1
            instruction = (0x5000 | x << 8 | y << 4).to_u16

            Opcodes::SKIPIFEQV.operation.call(chip8, instruction)
            chip8.pc.should eq(address)
          end
        end
      end
    end

    describe "RET" do
      it "sets PC to last value pushed onto stack" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new
        chip8.pc = rng.rand(0xFFF).to_u16
        ret_address = rng.rand(0xFFF).to_u16
        chip8.stack.push(ret_address)

        Opcodes::RET.operation.call(chip8, 0x0000.to_u16)
        chip8.pc.should eq(ret_address)
      end

      it "pops last value off stack" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new
        chip8.pc = rng.rand(0xFFF).to_u16
        ret_address = chip8.stack.push(rng.rand(0xFFF).to_u16)

        Opcodes::RET.operation.call(chip8, 0x0000.to_u16)
        chip8.stack.size.should eq(0)
      end
    end
  end
end
