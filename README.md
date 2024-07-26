# tchipi8

A [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) emulator (interpretor).

This program is able to execute a number of CHIP-8 programs. Almost all
functionality is implemented except audio. From this
[awesome test suite](https://github.com/Timendus/chip8-test-suite),
this implementation is able to run the first 6 tests (with some
bugs here and there). More roms that have been tested available
[here](https://github.com/Klairm/chip8/).

## Installation / Building

- Get [Crystal](https://crystal-lang.org/install/) if you don't already have it
- Install SDL development libraries for your platform
```sh
sudo zypper install SDL2-devel # On opensuse

sudo apt install libsdl2-dev # Debian/Ubuntu

```
- Build the damn thing
```sh
shards install && crystal build --release src/tchipi8.cr
```
- Copy binary to a directory in $PATH
```sh
cp tchipi8 ~/bin/ # Assuming ~/bin is in $PATH
```

## Usage

```sh
./tchipi path-to-rom
```

Plenty of ROMs available on the Internet, just make sure that they
are compatible with COSMAC VIP CHIP-8 (avoid SUPER-CHIP or any other CHIP
with a fancy prefix).

## Development

- Ensure you have SDL2 development libraries installed (see the Installation / Building
section above)
- Install Crystal bindings for SDL
```sh
shards install
```
- Run tests
```sh
crystal spec
```
- Run app in debug mode
```sh
DEBUG=1 crystal run src/tchipi8 -- path-to-rom
```

## Contributing

1. Fork it (<https://gitlab.com/ntumbuka/tchipi8/-/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Walter Kaunda](https://ntumbuka.me) - creator and maintainer
