require "log"
require "sdl-crystal-bindings"

require "./errors"

module Tchipi8
  class Shutdown < Tchipi8Error; end

  module IO
    enum PixelState
      On
      Off

      def to_u8 : UInt8
        return 1.to_u8 if on?

        0.to_u8
      end
    end

    module Controller
      abstract def clear_pixels : Nil
      abstract def set_pixel(x : Int, y : Int, state : PixelState) : Nil
      abstract def read_key : UInt8
      abstract def sync : Nil
    end

    CHIP8_DISPLAY_WIDTH = 64
    CHIP8_DISPLAY_HEIGHT = 32

    class SDLController
      include Controller

      SDL_DISPLAY_WIDTH = 640
      SDL_DISPLAY_HEIGHT = SDL_DISPLAY_WIDTH / 2
      SPRITE_WIDTH = SDL_DISPLAY_WIDTH / CHIP8_DISPLAY_WIDTH
      SPRITE_HEIGHT = SDL_DISPLAY_HEIGHT / CHIP8_DISPLAY_HEIGHT

      def initialize
        if LibSDL.init(LibSDL::INIT_VIDEO) != 0
          Log.error { "Could not initialize SDL: #{String.new(LibSDL.get_error())}" }
          raise "Could not initialize display"
        end

        @window = LibSDL.create_window(
          "Tchipi8",
          LibSDL::WINDOWPOS_UNDEFINED,
          LibSDL::WINDOWPOS_UNDEFINED,
          SDL_DISPLAY_WIDTH,
          SDL_DISPLAY_HEIGHT,
          LibSDL::WindowFlags::WINDOW_SHOWN
        )
        if @window.null?
          Log.error { "Could not initialize SDL window: #{String.new(LibSDL.get_error())}" }
          raise "Could not initialize display"
        end
      end

      def clear_pixels : Nil
        LibSDL.fill_rect(surface, nil, rgb(0x00, 0x00, 0x00))
        LibSDL.update_window_surface(@window)
      end

      def set_pixel(x : Int, y : Int, state : PixelState) : Nil
        if x < 0 || x >= CHIP8_DISPLAY_WIDTH || y < 0 || y >= CHIP8_DISPLAY_HEIGHT
          Log.warn { "Drawing out of display area: #{x}, #{y}" }
          return
        end

        pixel = LibSDL::Rect.new
        pixel.x = x * SPRITE_WIDTH
        pixel.y = y * SPRITE_HEIGHT
        pixel.w = SPRITE_WIDTH
        pixel.h = SPRITE_HEIGHT
        colour = case state
                 in .on? then rgb(0xFF, 0xFF, 0xFF)
                 in .off? then rgb(0x00, 0x00, 0x00)
                 end
        LibSDL.fill_rect(surface, pointerof(pixel), colour)
        LibSDL.update_window_surface(@window)
      end

      def read_key : UInt8
        loop do
          key = next_event
          return key unless key.nil?
        end
      end

      def sync : Nil
        until next_event.nil?
          # Do nothing
          Log.debug { "Flushing event queue" }
        end
      end

      def destroy : Nil
        LibSDL.destroy_window(@window)
        LibSDL.quit
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

      private def next_event : UInt8?
        while LibSDL.poll_event(out event) != 0
          raise Shutdown.new if event.type == LibSDL::EventType::QUIT.to_i

          next if event.type == LibSDL::EventType::KEYDOWN.to_i

          key = case event.key.keysym.scancode
                when LibSDL::Scancode::SCANCODE_1 then 0x01
                when LibSDL::Scancode::SCANCODE_2 then 0x02
                when LibSDL::Scancode::SCANCODE_3 then 0x03
                when LibSDL::Scancode::SCANCODE_4 then 0x0C
                when LibSDL::Scancode::SCANCODE_Q then 0x04
                when LibSDL::Scancode::SCANCODE_W then 0x05
                when LibSDL::Scancode::SCANCODE_E then 0x06
                when LibSDL::Scancode::SCANCODE_R then 0x0D
                when LibSDL::Scancode::SCANCODE_A then 0x07
                when LibSDL::Scancode::SCANCODE_S then 0x08
                when LibSDL::Scancode::SCANCODE_D then 0x09
                when LibSDL::Scancode::SCANCODE_F then 0x0E
                when LibSDL::Scancode::SCANCODE_Z then 0x0A
                when LibSDL::Scancode::SCANCODE_X then 0x00
                when LibSDL::Scancode::SCANCODE_C then 0x0B
                when LibSDL::Scancode::SCANCODE_V then 0x0F
                end

          return key.to_u8 unless key.nil?
        end
      end
    end
  end
end
