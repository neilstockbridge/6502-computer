
# 6502-computer

This is a project to design and build a 6502 computer and software for it.

The first step was a [Free run](free-run) experiment.

The next step was [R1](R1), a SBC based around a [real 6502] but with RAM, ROM and other bus devices simulated by AVRs.


## Step by step

- Connect SERIAL1 to the host used to interact with the SBC
- SBC should supply power to RS232 board
        screen /dev/ttyUSB1 115200
- Connect SERIAL0 to the host used to edit and compile the ROM at 38400
- FTDI should supply power to SBC
- SERIAL1 should say "Initialization complete"
        screen /dev/ttyUSB0 38400
        f  # To enable fast mode.  The SBC will burn around its "jmp f000" ROM
- Stop the screen (^A, k)
        cd ROM/dude/
        ./dude upload
- SERIAL1 should show the SBC initialization messages
        ii     # "i" for instructions
        df000  # To see UART_getc
        ih     # "h" for hex
        d01c0  # To see the stack
        ia     # Not much use for dumping ASCII right now
        r      # Show the registers as they were at BRK


  [real 6502]: http://www.westerndesigncenter.com/wdc/w65c02s-chip.cfm

