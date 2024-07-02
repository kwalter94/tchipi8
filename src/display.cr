require "log"

require "sdl-crystal-bindings"

module Tchipi8
  class Display
    DISPLAY_WIDTH = 640
    DISPLAY_HEIGHT = DISPLAY_WIDTH / 2

    def initialize
      if LibSDL.init(LibSDL::INIT_VIDEO) != 0
        Log.error { "Could not initialize SDL: #{String.new(LibSDL.get_error())}" }
        raise "Could not initialize display"
      end

      @window = LibSDL.create_window(
        "Tchipi8",
        LibSDL::WINDOWPOS_UNDEFINED,
        LibSDL::WINDOWPOS_UNDEFINED,
        DISPLAY_WIDTH,
        DISPLAY_HEIGHT,
        LibSDL::WindowFlags::WINDOW_SHOWN
      )
      if @window.null?
        Log.error { "Could not initialize SDL window: #{String.new(LibSDL.get_error())}" }
        raise "Could not initialize display"
      end
    end

    def clear
      LibSDL.fill_rect(surface, nil, rgb(0x00, 0x00, 0x00))
      LibSDL.update_window_surface(@window)
    end


    def destroy
      LibSDL.destroy_window(@window)
      LibSDL.quit
    end

    def keys_pressed : Enumerable(UInt8)
      keys = [] of UInt8

      while LibSDL.poll_event(out event) != 0
        case event.type
        when LibSDL::EventType::QUIT.to_i
          keys << 0xF0
        when LibSDL::EventType::KEYDOWN.to_i
          case event.key.keysym.scancode
            when LibSDL::Scancode::SCANCODE_1 then keys << 0x01
            when LibSDL::Scancode::SCANCODE_2 then keys << 0x02
            when LibSDL::Scancode::SCANCODE_3 then keys << 0x03
            when LibSDL::Scancode::SCANCODE_4 then keys << 0x0C
            when LibSDL::Scancode::SCANCODE_Q then keys << 0x04
            when LibSDL::Scancode::SCANCODE_W then keys << 0x05
            when LibSDL::Scancode::SCANCODE_E then keys << 0x06
            when LibSDL::Scancode::SCANCODE_R then keys << 0x0D
            when LibSDL::Scancode::SCANCODE_A then keys << 0x07
            when LibSDL::Scancode::SCANCODE_S then keys << 0x08
            when LibSDL::Scancode::SCANCODE_D then keys << 0x09
            when LibSDL::Scancode::SCANCODE_F then keys << 0x0E
            when LibSDL::Scancode::SCANCODE_Z then keys << 0x0A
            when LibSDL::Scancode::SCANCODE_X then keys << 0x00
            when LibSDL::Scancode::SCANCODE_C then keys << 0x0B
            when LibSDL::Scancode::SCANCODE_V then keys << 0x0F
          end
        end
      end

      keys
    end

    private def surface : Pointer(LibSDL::Surface)
      surface = LibSDL.get_window_surface(@window)
      if surface.null?
        Log.error { "Could not get SDL window surface: #{String.new(LibSDL.get_error())}" }
        raise "Could not initialize display"
      end

      surface
    end

    private def rgb(red : UInt8, green : UInt8, black : UInt8) : UInt32
      LibSDL.map_rgb(surface.value.format, red, green, black)
    end
  end
end
