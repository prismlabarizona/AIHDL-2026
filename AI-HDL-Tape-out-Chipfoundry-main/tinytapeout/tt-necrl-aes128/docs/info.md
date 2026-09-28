## How it works

An AES-128 encryption peripheral with a composite-field S-box datapath,
constant-time operation (fixed 32-cycle encryption with an LFSR-scheduled
dummy stall), write-only key registers, hard- and soft-reset key
zeroization, and double-buffered plaintext banks so the next block can be
loaded while the current one encrypts. Control/status/key/data registers
live on the TinyQV register bus, reached through the SPI bridge on the uio
pins (uio[4]=CS, uio[5]=SCK, uio[6]=MOSI, uio[3]=MISO).

Register map (32-bit): 0x00 CTRL (b0 start, b1 soft-reset/zeroize, b2
key-lock, b3 auto-start) · 0x01 STATUS (b0 done, b1 fault) · 0x02-0x05 key
(write-only, reads return 0) · 0x06-0x09 plaintext · 0x0A-0x0D ciphertext.

## How to test

Run the cocotb test in `test/` (`make -B`): it drives the physical SPI pins
with the FIPS-197 Appendix-B vector — loads the key and plaintext, starts,
polls done, and checks the exact ciphertext — plus key-readback-zero and
reset-zeroization checks.

## External hardware

None; any SPI host can exercise the tile.
