
R1 is a system with a real 6502 but with everything else simulated by two AVRs.  The only reason for the second ( slave) AVR is because the ATmega1284P ran out of pins.

![R1](R1.jpg)

  - The header in the top-left corner is the SPI bus
  - The UART header at the top is the simulated UART available to the 6502
  - The UART header in the  bottom-left corner is the Admin UART for control of the system
  - The improvised jumper blocks wire the AVRs to the SPI bus in the left-hand position or allow ISP in the right-hand position

  - [gEDA gschem schematic](R1.sch)
  - [gEDA PCB layout](R1.pcb)


## Features

  - `PHI2` is under software control of the master AVR, which:
    - Means that only a fully static 6502 is supported
    - Severely limits the performance of the 6502
    - Results in a irregular `PHI2` as some bus devices take longer to be accessed.  Rather than use wait states, `PHI2` is simply not advanced until the bus operation is complete
    - Allow the whole system to be frozen, resumed and single-stepped under user control

  - Hardware UART ( provided by the slave AVR) capable of 115,200 baud

  - Hardware SPI ( provided by the master AVR) capable of 10 MHz, up to 7 slaves

  - IRQB on the SPI bus

  - All 16 address lines are sampled by the master AVR allowing the full 64K of address space to be simulated

  - The master AVR has an "Admin" UART that can be used by a PC to control the system.  Bus devices could be simulated ( slowly) on a PC over this link

  - Simulated bus devices:
    - 15K RAM.  The master AVR has 16K but needs some for itself
    - ROM.  Can be served from AVR RAM for rapid ROM development or from AVR program memory ( 120+K of it)
    - EEPROM ( 4K of it in the ATmega128)
    - UART.  This is actually the UART on the slave AVR, accessed transparently via SPI
    - SPI.  The master drives the SPI bus, simulating a 65SPI-like bus device.  The slave AVR is commanded by the master ( also via SPI) to control the Slave Select lines
    - Timers in the slave AVRs
    - Potentially others:
      - Timers in the master AVR ( although since the master AVR doesn't drive `IRQB` it would have to ask the slave to interrupt the 6502)
      - Hardware multiplier
      - Blitter

The first boards had problems requiring rework:

  - There wasn't enough space between the master and slave AVRs.  Some of the package of the master AVR had to be ground off
  - AVCC was left unconnected instead of being wired to Vcc.  The UART didn't work
  - There was no pull-up for IRQB.  An internal pull-up in the slave AVR would be inelegant because it would require more code to disable the pull-up when asserting IRQB

By changing the firmware, it would be possible to simulate ( very slowly) 64K of RAM by simulating the RAM on a PC and having it served over the serial port.  The UART becomes the transport layer for the 6502 bus.  Slow but flexible.

