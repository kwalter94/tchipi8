require "log"

require "./chip8"
require "./decoder"
require "./io"
require "./opcodes"


module Tchipi8
  VERSION = "0.1.0"

  Log = ::Log.for("tchipi8")
  Log.level = :debug

  io_controller = IO::SDLController.new
  chip8 = Chip8.new(io_controller)

  if ARGV.empty?
    Log.error { "No program file specified" }
    exit(1)
  end

  file_name = ARGV[0]

  Log.debug { "Loading program from #{file_name}" }
  File.open(file_name, "rb") do |file|
    chip8.load_program(file)
  end

  begin
    chip8.run
  rescue Shutdown
    Log.debug { "Shutdown requested" }
    io_controller.destroy
  rescue error
    Log.error { "Unhandled exception, shutting down" }
    io_controller.destroy
    raise error
  end
end
