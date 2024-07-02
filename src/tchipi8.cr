require "./chip8"
require "./decoder"
require "./display"
require "./opcodes"


module Tchipi8
  VERSION = "0.1.0"

  chip8 = Chip8.new
  chip8.display.clear
  done = false

  loop do
    chip8.display.keys_pressed.each { |key| done = true if (key & 0xF0) == 0xF0 }
    break if done

    sleep(1.0 / 60)
  end
end
