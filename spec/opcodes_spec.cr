require "./spec_helper"

module Tchipi8
  class DummyIOController
    include IO::Controller

    getter pixels

    def initialize
      @pixels = [] of Array(IO::PixelState)

      (0...IO::CHIP8_DISPLAY_HEIGHT).each do
        @pixels << Array.new(IO::CHIP8_DISPLAY_WIDTH, IO::PixelState::Off)
      end
    end

    def clear_pixels : Nil
      (0...@pixels.size).each do |y|
        (0...@pixels[y].size).each do |x|
          @pixels[y][x] = IO::PixelState::Off
        end
      end
    end

    def set_pixel(x, y, state) : Nil
      @pixels[y][x] = state
    end

    def render_display : Nil
      @pixels.each do |row|
        row.each { |pixel| print(pixel.on? ? "*" : ".") }
        print("\n")
      end
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

    describe "SUBV" do
      it "subtracts vY from vX and stores the result in vX" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = (128 + rng.rand(128)).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? value_x : rng.rand(128).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::SUBV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_x - value_y)
          end
        end
      end

      it "sets vF to 0 when there is no underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = (128 + rng.rand(128)).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? value_x : rng.rand(128).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::SUBV.operation.call(chip8, instruction)

            chip8.v[0xF].should eq(0)
          end
        end
      end

      it "wraps around on underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            next if register_x == register_y # Can't underflow

            value_x = chip8.v[register_x] = rng.rand(0xFE).to_u8
            value_y = chip8.v[register_y] = value_x + 1 + rng.rand(0xFF - value_x - 1).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::SUBV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(0xFF - (value_y - value_x) + 1)
          end
        end
      end

      it "sets vF to 1 on underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            next if register_x == register_y # Can't underflow

            value_x = chip8.v[register_x] = rng.rand(0xFE).to_u8
            value_y = chip8.v[register_y] = value_x + 1 + rng.rand(0xFF - value_x - 1).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::SUBV.operation.call(chip8, instruction)

            chip8.v[0xF].should eq(1)
          end
        end
      end
    end

    describe "RSUBV" do
      it "subtracts vX from vY and stores the result in vX" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = rng.rand(128).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? value_x : (128 + rng.rand(128)).to_u8

            instruction = (0x8007 | register_x << 8 | register_y << 4).to_u16
            Opcodes::RSUBV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(value_y - value_x)
          end
        end
      end

      it "sets vF to 0 when there is no underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            value_x = chip8.v[register_x] = rng.rand(128).to_u8
            value_y = chip8.v[register_y] = register_x == register_y ? value_x : (128 + rng.rand(128)).to_u8

            instruction = (0x8007 | register_x << 8 | register_y << 4).to_u16
            Opcodes::RSUBV.operation.call(chip8, instruction)

            chip8.v[0xF].should eq(0)
          end
        end
      end

      it "wraps around on underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xE).each do |register_x| # vF is always used for overflow indicator
          (0x0..0xF).each do |register_y|
            next if register_x == register_y # Can't underflow

            value_y = chip8.v[register_y] = rng.rand(0xFE).to_u8
            value_x = chip8.v[register_x] = value_y + 1 + rng.rand(0xFF - value_y - 1).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::RSUBV.operation.call(chip8, instruction)

            chip8.v[register_x].should eq(0xFF - (value_x - value_y) + 1)
          end
        end
      end

      it "sets vF to 1 on underflow" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |register_x|
          (0x0..0xF).each do |register_y|
            next if register_x == register_y # Can't underflow


            value_y = chip8.v[register_y] = rng.rand(0xFE).to_u8
            value_x = chip8.v[register_x] = value_y + 1 + rng.rand(0xFF - value_y - 1).to_u8

            instruction = (0x8005 | register_x << 8 | register_y << 4).to_u16
            Opcodes::RSUBV.operation.call(chip8, instruction)

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
            instruction = (0x5000 | x << 8 | y << 4).to_u16

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

    describe "SKIPIFNEQV" do
      it "increments PC by two if vX != vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          (0x0..0xF).each do |y|
            next if x == y

            chip8.pc = address = rng.rand(0xFFF).to_u16
            chip8.v[x] = rng.rand(0xFE).to_u8
            chip8.v[y] = chip8.v[x] + 1
            instruction = (0x9000 | x << 8 | y << 4).to_u16

            Opcodes::SKIPIFNEQV.operation.call(chip8, instruction)
            chip8.pc.should eq(address + 2)
          end
        end
      end

      it "does not modify PC if vX == vY" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          (0x0..0xF).each do |y|
            chip8.pc = address = rng.rand(0xFFF).to_u16
            chip8.v[x] = chip8.v[y] = rng.rand(0xFF).to_u8
            instruction = (0x9000 | x << 8 | y << 4).to_u16

            Opcodes::SKIPIFNEQV.operation.call(chip8, instruction)
            chip8.pc.should eq(address)
          end
        end
      end
    end

    describe "JMPREL" do
      it "sets pc to v0 + NNN" do
        chip8 = Chip8.new(DummyIOController.new)
        address = chip8.v[0] = 0x69
        offset = Random.new.rand(0x0FFF)
        instruction = (0xB000 | offset).to_u16
        Opcodes::JMPREL.operation.call(chip8, instruction)
        chip8.pc.should eq(address.to_u16 + offset)
      end
    end

    describe "RAND" do
      it "sets vX to a random value AND-ed with k" do
        chip8 = Chip8.new(DummyIOController.new)

        # Shitty test but still better than nothing, how
        # the eff do you test a random function?
        (0..0xF).each do |x|
          values = 1000.times.map do
            chip8.v[x] = 0
            instruction = (0xC000 | x << 8 | 0x69).to_u16
            Opcodes::RAND.operation.call(chip8, instruction)
            chip8.v[x].to_u32
          end

          values = values.to_a
          (values.sum // values.size).should_not eq(0)
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

    describe "SETI" do
      it "sets register I to provided constant" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x000..0xFFF).each do |k|
          Opcodes::SETI.operation.call(chip8, (0xA000 | k).to_u16)
          chip8.i.should eq(k)
        end
      end
    end

    describe "ADDI" do
      it "adds vX to I" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          chip8.v[x] = rng.rand(0xFF).to_u8
          k = chip8.i = rng.rand(0xFFF).to_u16

          Opcodes::ADDI.operation.call(chip8, (0xF01E | x << 8).to_u16)
          chip8.i.should eq(k + chip8.v[x])
        end
      end

      it "should rollover on overflow" do # Shouldn't occur in practice buy you never know
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |x|
          (0x01..0xFF).each do |k| # We can only overflow by how much a vX can hold
            chip8.i = 0xFFFF
            chip8.v[x] = k.to_u8

            Opcodes::ADDI.operation.call(chip8, (0xF01E | x << 8).to_u16)
            chip8.i.should eq(k - 1)
          end
        end
      end
    end

    describe "COPYVI" do
      it "copies the lowest significant nibble of vX to I" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |x|
          (0x00..0xFF).each do |k|
            chip8.v[x] = k.to_u8

            Opcodes::COPYVI.operation.call(chip8, (0xF029 | x << 8).to_u16)
            chip8.i.should eq(0x0F & k)
          end
        end
      end
    end

    describe "MOVMBCD" do
      it "copies the BCD digits of vX to memory locations I[0,1,2]" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          (0x00..0xFF).each do |k|
            chip8.v[x] = k.to_u8
            i = chip8.i = rng.rand(0xFFD).to_u16

            Opcodes::MOVMBCD.operation.call(chip8, (0xF033 | x << 8).to_u16)
            expected = [k // 100, (k % 100) // 10, k % 10]
            chip8.memory[i..(i + 2)].should eq(expected)
          end
        end
      end

      it "truncates BCD when I is out of bounds" do
        chip8 = Chip8.new(DummyIOController.new)

        (0x0..0xF).each do |x|
          [0xFFD, 0xFFF].each do |i|
            chip8.v[x] = 255.to_u8
            chip8.i = i.to_u16

            Opcodes::MOVMBCD.operation.call(chip8, (0xF033 | x << 8).to_u16)
            expected = [2, 5, 5][..(0xFFF - i)]
            chip8.memory[i..0xFFF].should eq(expected)
          end
        end
      end
    end

    describe "MOVM" do
      it "copies v[0..X] to memory locations I[0..X]" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0x0..0xF).each do |x|
          expected = (0..x).map { |i| chip8.v[i] = rng.rand(0x100).to_u8 }.to_a
          i = chip8.i = rng.rand(0xFFF - x).to_u16

          Opcodes::MOVM.operation.call(chip8, (0xF055 | x << 8).to_u16)
          chip8.memory[i..i + x].should eq(expected)
        end
      end

      it "truncates when I[X] goes out of bounds" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        expected = (0..0xF).map { |x| chip8.v[x] = rng.rand(0x100).to_u8 }

        (0..15).each do |i|
          address = chip8.i = (0xFFF - i).to_u16

          Opcodes::MOVM.operation.call(chip8, 0xFF55.to_u16)
          chip8.memory[address..].should eq(expected[..i])
        end
      end
    end

    describe "MOV" do
      it "copies memory locations I[0..X] to v[0..X]" do
        rng = Random.new
        chip8 = Chip8.new(DummyIOController.new)
        chip8.i = rng.rand(0xFF0).to_u16

        expected = (0..0xF).map { |i| chip8.memory[chip8.i + i] = rng.rand(0xFF).to_u8 }

        (0..0xF).each do |x|
          Opcodes::MOV.operation.call(chip8, (0xF065 | x << 8).to_u16)
          chip8.v[..x].should eq(expected[..x])
        end
      end

      it "truncates when memory locations are out of bounds" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..15).each do |x|
          address = chip8.i = (0xFFF - x).to_u16
          (0..0xF).each { |i| chip8.v[i] = 0.to_u8 }
          expected = (0..x).map { |i| chip8.memory[chip8.i + i] = rng.rand(0xFF).to_u8 }

          Opcodes::MOV.operation.call(chip8, 0xFF65.to_u16)
          chip8.v[0..x].should eq(expected)
          chip8.v[x + 1..].each { |k| k.should eq(0) }
        end
      end
    end

    describe "RSHIFT" do
      it "shifts right 1 bit from vY and assigns it to vX" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |x|
          y = x + 1
          source = chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::RSHIFT.operation.call(chip8, (0x8006 | x << 8 | y << 4).to_u16)
          chip8.v[x].should eq(source >> 1)
        end
      end

      it "sets vF to the bit shifted out" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |x|
          y = x + 1
          chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::RSHIFT.operation.call(chip8, (0x8006 | x << 8 | y << 4).to_u16)
          chip8.v[0xF].should eq(chip8.v[y] & 0x01)
        end
      end

      it "overwrites vF with shifted bit even when vF is destination" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |y|
          chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::RSHIFT.operation.call(chip8, (0x8006 | 0xF << 8 | y << 4).to_u16)
          chip8.v[0xF].should eq(chip8.v[y] & 0x01)
        end
      end
    end

    describe "LSHIFT" do
      it "shifts left 1 bit from vY and assigns it to vX" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |x|
          y = x + 1
          source = chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::LSHIFT.operation.call(chip8, (0x8006 | x << 8 | y << 4).to_u16)
          chip8.v[x].should eq(source << 1)
        end
      end

      it "sets vF to the bit shifted out" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |x|
          y = x + 1
          chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::LSHIFT.operation.call(chip8, (0x8006 | x << 8 | y << 4).to_u16)
          chip8.v[0xF].should eq(chip8.v[y] & 0x80)
        end
      end

      it "overwrites vF with shifted bit even when vF is destination" do
        chip8 = Chip8.new(DummyIOController.new)
        rng = Random.new

        (0..0xE).each do |y|
          chip8.v[y] = rng.rand(0xFF).to_u8

          Opcodes::LSHIFT.operation.call(chip8, (0x8006 | 0xF << 8 | y << 4).to_u16)
          chip8.v[0xF].should eq(chip8.v[y] & 0x80)
        end
      end
    end

    describe "CLS" do
      it "requests clear_pixels on connected I/O devices" do
        io = DummyIOController.new
        io.set_pixel(6, 9, IO::PixelState::On)

        Opcodes::CLS.operation.call(Chip8.new(io), 0x00E0.to_u16)
        io.pixels.each do |row|
          row.each do |pixel|
            pixel.should eq(IO::PixelState::Off)
          end
        end
      end
    end

    describe "DRAW" do
      it "draws sprite at {vX, vY}" do
        io = DummyIOController.new
        chip8 = Chip8.new(io)
        rng = Random.new

        sprite = [0x81, 0x42, 0x24, 0x18] of UInt8
        sprite.each_with_index { |row, i| chip8.memory[i] = row }
        chip8.i = 0

        [{0, 0}, {32, 16}, {56, 24}].each do |sprite_x, sprite_y|
          (0..0xE).each do |x|
            (0..0xE).each do |y|
              Opcodes::CLS.operation.call(chip8, Opcodes::CLS.opcode)
              chip8.v[x] = sprite_x.to_u8
              chip8.v[y] = sprite_y.to_u8
              instruction = (0xD000 | x << 8 | y << 4 | sprite.size).to_u16

              Opcodes::DRAW.operation.call(chip8, instruction)
              # io.render_display

              sprite.each_with_index do |pixmap, row|
                (0..7).each do |col|
                  pixel_state = (pixmap >> 7 - col) & 0x01
                  io.pixels[row + chip8.v[y]][col + chip8.v[x]].to_u8.should eq(pixel_state)
                end
              end
            end
          end
        end
      end

      it "draws N pixels as specified in instruction" do
        io = DummyIOController.new
        chip8 = Chip8.new(io)
        chip8.i = 0x0420.to_u16

        (0...0xF).each do |i|
          Opcodes::CLS.operation.call(chip8, Opcodes::CLS.opcode)
          chip8.memory[chip8.i + i] = 0xFF.to_u8
          chip8.v[0] = 0
          chip8.v[1] = 0

          instruction = (0xD010 | i + 1).to_u16

          Opcodes::DRAW.operation.call(chip8, instruction)
          # io.render_display
          io.pixels
            .map { |row| row[0...8].select(&.on?).size }
            .reduce { |a, b| a + b }
            .should eq((i + 1) * 8)
        end
      end

      it "sets vF if any set pixel is unset" do
        io = DummyIOController.new
        chip8 = Chip8.new(io)
        rng = Random.new

        chip8.i = 0x100
        chip8.memory[chip8.i] = 0xFF
        chip8.memory[chip8.i + 1] = 0xFF
        chip8.v[0x4] = 0
        chip8.v[0x2] = 0
        instruction = (0xD000 | 0x4 << 8 | 0x2 << 4 | 0x2).to_u16
        Opcodes::DRAW.operation.call(chip8, instruction)

        chip8.memory[chip8.i] = 0x00
        Opcodes::DRAW.operation.call(chip8, instruction)

        chip8.v[0xF].should eq(1)
      end

      it "unsets vF if no pixels are unset" do
        io = DummyIOController.new
        chip8 = Chip8.new(io)
        rng = Random.new

        chip8.i = 0x100
        chip8.memory[chip8.i] = 0xFF
        chip8.memory[chip8.i + 1] = 0xFF
        chip8.v[0x4] = 0
        chip8.v[0x2] = 0
        instruction = (0xD000 | 0x4 << 8 | 0x2 << 4 | 0x2).to_u16
        Opcodes::DRAW.operation.call(chip8, instruction)

        chip8.memory[chip8.i] = 0x00
        Opcodes::DRAW.operation.call(chip8, instruction) # This should set vF
        Opcodes::DRAW.operation.call(chip8, instruction) # Unset vF

        chip8.v[0xF].should eq(0)
      end
    end
  end
end
