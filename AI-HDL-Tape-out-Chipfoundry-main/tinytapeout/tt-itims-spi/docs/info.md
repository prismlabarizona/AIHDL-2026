## How it works

An autonomous full-duplex SPI master peripheral on the TinyQV register bus.
Software (or the harness SPI bridge on the uio pins) configures mode
(CPOL/CPHA), word length, bit order and clock divider, then launches
transfers through a 32-bit TX/RX engine with CRC-16 generation. A
"sleep-walker" mode lets the master poll an external sensor autonomously on a
programmable timer and raise an interrupt only when the received value
crosses configured thresholds. A 32-bit unlock-constant interlock protects
the secure register zone against accidental writes.

The harness bridge (uio[4]=CS, uio[5]=SCK, uio[6]=MOSI, uio[3]=MISO) speaks
the standard TinyQV 32-bit SPI register protocol: a 32-bit command word
(RW + width + address) followed by a 32-bit data word.

## How to test

Run the cocotb suite in `test/` (`make -B`): 12 tests covering all four SPI
modes, clock dividers, LSB/MSB bit order, CRC-16 against a software model,
autonomous polling with threshold interrupts, and the security interlock.
On silicon: drive the register bridge over the uio SPI pins and observe the
SPI master's own bus on ui[0] (MISO in) / uo[0..2] (SCLK, MOSI, CS).

## External hardware

Any SPI slave device (sensor, EEPROM) on the dedicated pins; none required
for the register-bridge tests.
