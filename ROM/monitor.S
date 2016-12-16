
; PLAN
; - erase 4K flash (done but reenable coment and test)
; - read: done
; - write: need in order to test erase since flash is already erased

; A monitor program driven by a VT100 ; terminal ( perhaps using ANSI escape
; codes) over a serial terminal.
;
; NOTE: This began on a C64, so there may be opportunities to make things more
; compact with W65C02 instructions

; PLAN
;   - Zero-page stack idea
;   - Breakpoints
;   - Single step
;   - memset - at least for individual bytes
;   - [c]ontinue to specific address
;   - ability to load a labels file and add labels to addresses
;   - Show cycle count in disassembly
;   - add hex dump to instruction dump
;   - Assembly, memmove, DOS - probably can't be bothered

; MONITOR COMMANDS
; d1234     DUMP memory from address 1234;  Omit address to continue disassembly from where left off
; ih        Change Dump mode INTERPRETATION to h:HEX, a:ASCII, i:instructions
; w123456   Write 0x56 to address 0x1234
; c[AAAA]   Continue from BRK ( or to specified address)
; bl        BREAKPOINT LIST
; bs0,1234  BREAKPOINT, SET #0 at address 1234.  Two bytes at address are saved in slot #0 and replace with BRK #0
; br7       BREAKPOINT, REMOVE #7
; r         Show processor registers ( as they were at BRK)
; s         Single Step
; a 1234    Begin assembly at 1234
; ?         memset, memmove, directory, load/save region to/from file
; wAAAAdd   Write dd to address AAAA
; t         Test
; ss        Select SPI slave
; sRR       Make request RR of selected SPI device
; sr        Release SPI slave
; spN       "Pump" N bytes from SPI device
; fi        Show SPI flash unique ID
; faAAAA    Set address to use within flash to AAAAxx or AAAIxx for erase (I: still specified but ignored)
; fbAAAA    Set address within RAM to use as the buffer for reading from and writing to flash
; fr        Read 256 bytes from SPI flash to RAM
; fw        Write 256 bytes from RAM to SPI flash
; fe        Erase 4K page at stored address
;
;
; # Ideas
;
;   - Auto-single-step: BRK then dump registers ( and perhaps inspect the
;     instruction and dump memory that it references) then set a BRK at the
;     next instruction and return.  Provides a trace over serial of the whole
;     execution.  Would likely need to switch it on and off to capture the
;     trouble section only otherwise too much output to wade through

; Export these so that they apear in the label file (so the disassembler can use them)
.export map
.export index
.export reset_handler
.export irq_handler
.export nmi_handler
.export init
.export main
.export cmdline
.export cursor
.export request
.export brk_handler
.export dump_registers
.export set_dump_func
.export dump
.export dump_hex
.export dump_ascii
.export dump_instructions
.export trace

.import inc_zp_ptr
.import advance_zp_ptr
.import adjust_zp_ptr
.import read_from_stream
.import zps_init
.import zps_pha
.import zps_phya
.import zps_release2
.import UART_getc
.import UART_putc
.import SPI_select
.import SPI_exchange
.import SPI_release
.import parse_hex4
.import parse_hex8
.import print_space
.import write_eol
.import pstr
.import write_cstr
.import write_ansi_color
.import printfu
.import phex16
.import phex8
.import phex4
.import power_up_SPI_flash
.import read_SPI_flash_unique_identifier
.import read_SPI_flash_page
.import erase_4K_of_SPI_flash
.import write_SPI_flash_page
.import test
.import show_A

getc = UART_getc
putc = UART_putc

.if .defined(dump_sp)
.export dump_sp
.endif


.include "globals.S"

K_ENTER = $0d
K_BACKSPACE = $7f


reset_handler:
init:
  ldx #$ff  ; Initialize the stack pointer
  txs
;right_here:
;  jsr getc
;  bcc :+
;  lda #$3e  ; '>'
;  jsr putc
;: jmp right_here

  jsr zps_init

  ;lda #<dump_instructions      ; Default dump interpretation
  ;ldx #>dump_instructions
  lda #<dump_hex
  ldx #>dump_hex
  jsr set_dump_func

  lda #$39  ; Default
  jsr write_ansi_color
  ldx #<@READY
  ldy #>@READY
  .define init_msg .sprintf("%c%cNeil's 6502 SBC R2%c%c64K RAM SYSTEM%c%cREADY%c%c", $0d, $0a, $0d, $0a, $0d, $0a, $0d, $0a)
  .rodata
  @READY: .byt .strlen(init_msg), init_msg
  .code
  jsr pstr

  stz dump_ptr
  lda #$f0
  sta dump_ptr+1
  ; Fall through to main

  ;lda #$28   ; '('
  ;jsr spi_test
  ;lda #$7a   ; 'z'
  ;jsr spi_test

main:
  ; 435b1b  RIGHT ARROW
  ; 445b1b  LEFT ARROW
  ; 425b1b  DOWN ARROW
  ; 415b1b  UP ARROW
  ; DELETE 7e335b1b
  ; BACKSPACE 7f

  ; To begin with, ignore cursor keys because otherwise have to store length of
  ; cmdline as well as cursor and more importantly need memmove for shifting
  ; around characters to the right of the cursor

  ; Take note of the SP so no matter how far down the stack we go, we still
  ; have a reference to the things put on the stack by BRK and brk_handler:
  ;   - Y, X, A, Flags, RALO, RAHI
  tsx
  inx           ; SP points to empty slot, so INX so $0100+X points to Y instead
  stx brk_sp
  ldx #$01      ; HI byte of stack
  stx brk_sp+1

  ; If entering via BRK rather than reset..
;  lda #$ff
;  cmp brk_sp
;  beq @prompt
  jsr dump_sp
;  jsr dump_registers

@prompt:
  lda #$31  ; Red
  jsr write_ansi_color
  lda #$3e  ; '>'
  jsr putc
  lda #$20
  jsr putc

  ; If BRK then use the command-line editor then BRK again then the
  ; command-line cursor will be in the wrong place
  lda #0      ; The character input next should go to the *beginning* of the buffer
  sta cursor

@loop:
  ; Get a character from the console
  jsr getc    ; Returned in A
  bcc @loop   ; If C is 0 then no key was available

  ; If the Backspace key was pressed..
  cmp #K_BACKSPACE
  bne @maybe_enter
  ; Multiple delete not supported any more.  Left here in case want to use again
  ;ldy #1 ; Number of characters to delete.  This section is re-used by ENTER below
@delete:
  ;tya
  ; If the cursor is at the beginning of the line..
  ldx cursor
  beq @loop
  ; Move the cursor back one
  dex
  stx cursor
  ; Erase the latest character
  ldx #<@BACKSPACE
  ldy #>@BACKSPACE
  ;pha                 ; pstr damages A, so preserve it
  jsr pstr            ; Print the ^H[space]^H sequence
  ;pla
  ;tay
  ;dey
  ;bne @delete
  jmp @loop

@maybe_enter:
  cmp #K_ENTER
  bne @store
  jsr write_eol     ; Move the cursor to the next line
  lda #$39  ; Default
  jsr write_ansi_color
  jsr request           ; Process the command
  ;ldy #$ff ; All characters to beginning of line
  ;jmp @delete
  jmp @prompt

@store:
  ; If the command line buffer is full then do nothing
  ldx cursor
  cpx #CMDLINE_MAX
  bpl @loop

  jsr putc
  ; Store the character in the command line
  sta cmdline,x
  ; Advance the cursor
  inx
  stx cursor
  jmp @loop

  rts

@BACKSPACE:
  .byt 3, $08, $20, $08


cursor:
  .byt 0
CMDLINE_MAX = 39
cmdline:
  .res CMDLINE_MAX, $ea ; NOP so diassembly doesn't interfere with brk_handler


brk_handler:

  phaxy         ; Save the registers as they were prior to the BRK

  ; Prepare for an RTI to "main" instead of where the BRK occurred
  lda #>main    ; Push HI first, the same order as JSR
  pha
  lda #<main
  pha
  lda #$00  ; flags
  pha

  rti


; This is invoked once a complete command line ( request) has been received,
; i.e. after the user has pressed RETURN.
;
request:
  lda #<cmdline         ; The request is parsed as a stream
  sta cmdline_stream
  lda #>cmdline
  sta cmdline_stream+1
  ldx #<cmdline_stream  ; X refers to the ptr in ZP
  jsr read_from_stream  ; Read the first character of the request

  cmp #'i'              ; i[hai]  Change interpretation (hex, ascii, instructions)
  bne @maybe_dump

  jsr read_from_stream  ; Read the character following 'I'
  tay                   ; Y is now the character that followed 'I'
  lda #<@DUMP_FUNC_MAP
  ldx #>@DUMP_FUNC_MAP
  jsr map
  bcs :+
  jmp @bad_request
: jmp set_dump_func

@maybe_dump:
  cmp #'d'
  bne @maybe_dump_registers

  ; If an address is present then it should be parsed to dump_ptr

  lda cursor      ; If an address was specified..
  cmp #5          ; The cursor is `5` if the request is `D1234`
  bmi :+          ; Branch if A is < 5

  jsr parse_hex8  ; Parse the address specified in the request
  sta dump_ptr+1
  jsr parse_hex8
  sta dump_ptr

: lda #8          ; Lines to dump
  jsr dump

  ;jsr write_eol
  ;jsr test
  rts

@maybe_dump_registers:
  cmp #'r'
  bne @maybe_write

  jmp dump_registers

@maybe_write:
  cmp #'w'
  bne @maybe_continue

;  jsr parse_hex8      ; Parse the HI byte of the address to write to
;  tay
;  jsr parse_hex8      ; Parse the LO byte
;  jsr zps_phya        ; Put the pointer to the address to write to on the ZP stack
;  jsr parse_hex8      ; Parse the byte to be written
;
;  ldx zp_sp           ; Write the byte to the specified address
;  sta ($01,x)
;
;  jsr zps_release2

  ; A good test of ZPS but is faster *and* more compact like this:
  jsr parse_hex8
  sta @write_addr+2
  jsr parse_hex8
  sta @write_addr+1
  jsr parse_hex8
@write_addr:
  sta $ffff

  rts

@maybe_continue:
  cmp #'c'
  bne @maybe_test

  ; The stack holds the return address in main then Y,X,A,flags,PC(BRK)
  pla   ; Discard the return address in "main"
  pla
  ; The main IRQ/BRK handler saved A, X and Y, so restore them:
  plyxa
  rti

@maybe_test:
  cmp #'t'
  bne @maybe_spi

;  jsr dump_sp
;  brk
;  nop   ; "signature" ( BRK parameter)
;
;  lda #$62  ; 'b' for back from monitor
;  jsr putc
;  jsr dump_sp
;
;  jsr parse_hex8  ; Abuse dump_ptr to store parameters for test
;  sta dump_ptr+1
;  jsr parse_hex8
;  sta dump_ptr

  .if .defined (TEST)
  jsr parse_hex8
  jsr test
  .endif
  rts

@maybe_spi:
  cmp #'s'
  bne @maybe_flash
  ; "ss" to select, "sr" to release, "s44" to transmit $44, "sp4" to pump 4 bytes
  lda ($00,x)       ; Read the head of the stream
  cmp #'s'
  bne :+
  jmp SPI_select  ; rts in SPI_select will return from this method
: cmp #'r'
  bne :+
  jmp SPI_release
: cmp #'p'
  bne :+
  jsr inc_zp_ptr           ; Skip the 'p'
  jsr read_from_stream
  jsr parse_hex4  ; Number of exchanges to pump
  tax
@pump:
  lda #$ff
  jsr SPI_exchange
  jsr phex8
  jsr print_space
  dex
  bne @pump
  rts
: jsr parse_hex8
  jsr SPI_exchange
  jmp phex8         ; Show the received data

@prepare_flash_method:
  ldy @flash_buf_ptr + 1
  lda @flash_buf_ptr
  jsr zps_phya
  ldy @address_within_flash + 1
  lda @address_within_flash
  rts

@maybe_flash:
  cmp #'f'
  bne @bad_request
  jsr power_up_SPI_flash
  ;txa
  ;bit @x_msg
  ;jsr show_A
  jsr read_from_stream
  ;bit @a_msg
  ;jsr show_A
  cmp #'i'          ; i: Identify
  bne :+
  ldya $04, $00
  jsr zps_phya
  jsr read_SPI_flash_unique_identifier
  jmp zps_release2  ; Use `rts` in zps_release2
: cmp #'a'          ; a: Address (within flash) for subsequent operations
  bne :+
  jsr parse_hex8                ; Read MSB first
  sta @address_within_flash + 1
  jsr parse_hex8
  sta @address_within_flash
  rts
: cmp #'b'          ; b: Buffer in RAM for flash operations
  bne :+
  jsr parse_hex8          ; Read MSB first
  sta @flash_buf_ptr + 1
  jsr parse_hex8
  sta @flash_buf_ptr
  rts
: cmp #'r'          ; b: Read 256 bytes from address to buffer
  bne :+
  jsr @prepare_flash_method
  jsr read_SPI_flash_page
  jmp zps_release2  ; Use `rts` in zps_release2
: cmp #'e'          ; b: Erase 4K at address
  bne :+
  jsr @prepare_flash_method
  jsr erase_4K_of_SPI_flash
  jmp zps_release2  ; Use `rts` in zps_release2
: cmp #'w'          ; w: Write 256 bytes from buffer to address
  bne :+
  jsr @prepare_flash_method
  jsr write_SPI_flash_page
  jmp zps_release2  ; Use `rts` in zps_release2
: lda @flash_buf_ptr      ; Show state
  pha
  lda @flash_buf_ptr + 1
  pha
  lda @address_within_flash
  pha
  lda @address_within_flash + 1
  pha
  ldx #<@STATE_MSG
  ldy #>@STATE_MSG
  jsr printfu
  rts

@bad_request:
  ldx #<@BAD_REQUEST
  ldy #>@BAD_REQUEST
  jmp pstr

.data
@address_within_flash: .byt 0, 0
@flash_buf_ptr: .byt 0, 0
@STATE_MSG: .byt "addr:",I_HEX16,"xx buf:",I_HEX16,13,10,0
@x_msg: .byt "X:",0
@a_msg: .byt "A:",0
@DUMP_FUNC_MAP:
  .byt 4, "h",      "a",        "i", 0
@DUMP_FUNC_MAP_VALUES:
  .word    dump_hex, dump_ascii, dump_instructions

@BAD_REQUEST:
  .byt .strlen("Bad request.."), "Bad request",$0d,$0a
.code


; brk:0000  a00 x00 y00 s00  n0 v0 b0 d0 i0 z0 c0
; $09af  a[00] x[00] y[00]  p[NVB-IZC]
; b:09af  a:00 x:00 y:00  p:NVB-IZC
;
dump_registers:
  ; On the stack:
  ;   - The address to return to after this method is finished, which:
  ;     - Might be "main", or it might be "request", so we don't know how far
  ;       up the stack to go to get to the saved values of the registers as
  ;       they were at BRK, hence `brk_sp`
  ;   - 0y, 1x, 2a, 3flags, 4RALO, 5RAHI
  ;   brk_sp.LO + 5 is SP as it was prior to BRK

  ldy #3              ; Y is an index into saved data on stack. 3:flags
  lda (brk_sp),y
  tax                 ; X is now the flags register as it was prior to BRK
  ldy #8              ; Y is the number of flags left to push
  lda #$01            ; Initialise the flags register mask to 0x01
  sta dump_regs_mask
@push_flag:
  ;cpy #3              ; When there are 3 flags left to push then this flag is undefined and should be skipped
  ;beq @next
  txa                 ; A is now flags as they were at BRK
  and dump_regs_mask
  beq :+              ; If A is 0 then that's just what I want to see
  ;lda #1              ; Otherwise A is 1 << 0..7 but should be `1` for display
  lda @FLAGS-1,y
  bne @push
: lda #$2d            ; $2d is '-'
@push:
  pha                 ; Push the value of the now isolated and normalised flag
@next:
  asl dump_regs_mask  ; The mask now captures the next most significant flag
  dey
  bne @push_flag      ; Loop while there are more flags to process

  lda brk_sp          ; A is now the SP as it was upon entry to brk_handler
  clc
  adc #5              ; A is now the SP as it was prior to BRK
  pha

  ldy #0              ; Y now refers to the saved value of Y
: lda (brk_sp),y
  pha
  iny                 ; Y will refer first to X, then A, which happily is the order in which we wish to push, so loop
  cpy #3
  bne :-

  ldy #5              ; 5: HI byte of the return address ( the address after not just the BRK but the signature byte)
  lda (brk_sp),y
  tax                 ; X is now Return Address HI
  dey                 ; Y is now 4: offset of the LO byte of the return address
  lda (brk_sp),y      ; A is now Return Address LO
  sec
  sbc #2              ; A is now the address of the BRK
  bcs :+              ; If it underflowed..
  dex                 ; ..then adjust address HI
: pha                 ; Push BRK address LO first
  txa
  pha                 ; ..and HI after
  ldx #<@REGS
  ldy #>@REGS
  jmp printfu

@FLAGS: .byt "NV1BDIZC"

@C = %10010011 ; printfu_putc
@REGS:
  .byt %10010000,%10010000," A:",%10010000," X:",%10010000," Y:",%10010000," S:",%10010000,"  ",@C,@C,@C,@C,@C,@C,@C,@C,$0d,$0a,0

; @param  A  The mask
; @param  X  The value
; @return  A  1 if bit is set, 0 otherwise
;@is_bit_set:
;  stx @and+1
;@and:
;  and #$ff
;  bne :+
;  rts     ; A is already 0
;: lda #1
;  rts

; Remembers the address of the function that should be used to dump a single ;
; line of stuff from memory.
;
;   A:  LO byte of ptr to dump func
;   X:  HI byte of ptr to dump func
;
set_dump_func:
  sta dump_func_ptr+1
  stx dump_func_ptr+2
  rts


; This is the general purpose dump routine.  It prints the address being dumped
; then transfers control to the specific dumper ( hex, instructions, etc.) and
; then advances to the next line until 20 lines have been dumped.
;
; dump_ptr        is 16-bit ptr in ZP, points to the memory address to dump
; dump_func_ptr   is 16-bit ptr in ZP, points to the address of the function
;                 that dumps a single line of stuff from memory
;
; @param  A   The number of lines to dump
dump:
  ;lda #8
  sta lines_to_dump
: lda dump_ptr
  ldx dump_ptr+1
  jsr phex16

  jsr print_space   ; Print two spaces
  jsr print_space
dump_func_ptr:
  jsr $ffff         ; Placeholder: Self-modifying
  jsr write_eol     ; Move the console cursor to the next line
  dec lines_to_dump
  bne:-
  rts


; Limit to 40 columns
; Each line begins with an address.  Generic for different dump types
;1000  00 00 00 00 00 00 00 00  abcdefgh
;
dump_hex:
  ldy #16           ; Number of bytes to dump
: tya               ; Remember Y because phex8 destroys it
  pha
  ldx #dump_ptr
  jsr read_from_stream
  jsr phex8         ; Dump the byte
  jsr print_space
  pla
  tay
  dey
  ;dec tmp2 ; FIXME: It's like "DEC zeropage" is not affecting the Z flag
  bne :-
  rts


dump_ascii:
  ldy #32               ; Number of bytes to dump
  ldx #dump_ptr         ; Address in ZP of ptr to data
@next:
  jsr read_from_stream
  cmp #$20
  bmi @unprintable      ; Branch if A < $20
  cmp #$80
  bpl @unprintable      ; Branch if A >= $80
: jsr putc
  dey
  bne @next
  rts
@unprintable:
  lda #$2e              ; '.' to indicate unprintable character
  bne :-
  rts


dump_instructions:
  ldx #dump_ptr                     ; X is now the address in ZP of ptr to data
  jsr read_from_stream              ; A is now the OpCode
  ; The ID of the mnemonic for the OpCode is @OPCODE_MNEMONIC_IDS + OpCode
  ; The mnemonic is 3 chars at @MNEMONICS + 3 * mnemonic_id
  pha

  tay
  lda @OPCODE_MNEMONIC_IDS,y        ; A is now the mnemonic ID
  ldx #<@MNEMONICS                  ; Set up a stream to read the mnemonic
  stx mnemonic_stream
  ldx #>@MNEMONICS
  stx mnemonic_stream+1
  ldx #<mnemonic_stream
  tay                               ; Y is now the mnemonic ID
  asl                               ; A is now 2x mnemonic_id
  jsr advance_zp_ptr
  tya                               ; A is now the mnemonic ID once more
  jsr advance_zp_ptr                ; mnemonic_stream now points to @MNEMONICS + 3 * mnemonic_id
  ldy #3                            ; Copy 3 characters from mnemonic_stream to the console
: jsr read_from_stream
  jsr putc
  dey
  bne :-
  jsr print_space                   ; There should be a space after the mnemonic even if wasted for implied addressing modes

  pla                               ; A is now the OpCode once more
  tay
  lda @OPCODE_ADDRESSING_MODE_IDS,y
  cmp #8                            ; 8 is program_counter_relative, which is the only addressing mode that requires special handling
  bne @all_other_modes
  ; handling for PC relative
  ; Output format:
  ;   beq $ffb4
  ; ..where the address ( $ffb4 in example) = dump_ptr + 2 + ( signed) offset,
  ; except dump_ptr has already been advanced one to read the opcode and will
  ; be advanced again to read the operand, so "+ 2" is not required
  ldx #dump_ptr                     ; Read the Operand, which is the relative address
  jsr read_from_stream              ; A is now the relative address of the
                                    ; branch.  dump_ptr now points to the
                                    ; instruction after the branch

  ; What if keep arith in regs instead?  ready for phex16
  @hi = $01   ; Offset from address X in ZP
  @lo = $00

;  bpl :+      ; If A is -ve then pre-decrement HI
;  dec @hi,x
;: clc
;  adc @lo,x
;  sta @lo,x
;  bcc :+
;  inc @hi,x
;: rts

  ldx dump_ptr+@hi
  tay                 ; Sets N based of sign of A
  bpl :+
  dex
: clc
  adc dump_ptr+@lo
  bcc :+
  inx
: jmp phex16

@all_other_modes:
  tay                               ; Y is now the addressing mode ID
  lda @ADDRESSING_MODES,y           ; A is now the number of bytes in the operand
  beq @return                       ; No operand bytes => Nothing to dump
                                    ; If there are two operand bytes then the
                                    ; format will refer to phex16, which
                                    ; expects LO in A and HI in X.  X must be
                                    ; pushed first for printfu
  ldx #dump_ptr
  cmp #2                            ; C is set if the number of operand bytes is 2 and will remain set even after A has changed
  bcc :+
  jsr read_from_stream              ; The first operand byte is LO ( or only)
                                    ; and must end up in A.  The second operand
                                    ; byte ( if present) is HI and must
                                    ; end up in X, yet X must be pushed FIRST,
                                    ; i.e. the first to be read must be the
                                    ; last to be pushed
  pha
: jsr read_from_stream
  pha
  lda @ADDRESSING_MODE_OFFSETS,y    ; A is now the byte offset in to @MODE_FORMS
                                    ; of the form of this addressing mode
  clc
  adc #<@MODE_FORMS                 ; A is now <@MODE_FORMS + offset, with any overflow in C
  tax                               ; X is now <@MODE_FORMS + offset[ addressing_mode_id]
  ldy #>@MODE_FORMS
  bcc :+                            ; TODO: Could skip this if @MODE_FORMS were page-aligned.  In fact, X could simply be the offset
  iny
: jsr printfu
@return:
  rts

.rodata
; Table of addressing modes.  Each byte is simply the number of operand bytes
; for an instruction that uses the mode
@ADDRESSING_MODES:
  .byt 2, 2, 2, 2, 2, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1
; List of mnemonics
@MNEMONICS:
  .byt "brk", "ora", "---", "tsb", "asl", "cl0", "php", "b0c"
  .byt "bpl", "trb", "cl1", "clc", "inc", "b1c", "jsr", "and"
  .byt "bit", "rol", "cl2", "plp", "b2c", "bmi", "cl3", "sec"
  .byt "dec", "b3c", "rti", "eor", "lsr", "cl4", "pha", "jmp"
  .byt "b4c", "bvc", "cl5", "cli", "phy", "b5c", "rts", "adc"
  .byt "stz", "ror", "cl6", "pla", "b6c", "bvs", "cl7", "sei"
  .byt "ply", "b7c", "bra", "sta", "sty", "stx", "se0", "dey"
  .byt "txa", "b0s", "bcc", "se1", "tya", "txs", "b1s", "ldy"
  .byt "lda", "ldx", "se2", "tay", "tax", "b2s", "bcs", "se3"
  .byt "clv", "tsx", "b3s", "cpy", "cmp", "se4", "iny", "dex"
  .byt "wai", "b4s", "bne", "se5", "cld", "phx", "stp", "b5s"
  .byt "cpx", "sbc", "se6", "inx", "nop", "b6s", "beq", "se7"
  .byt "sed", "plx", "b7s"
; Lookup table that maps OpCode to index in @MNEMONICS
@OPCODE_MNEMONIC_IDS:
  .byt $00,$01,$02,$02,$03,$01,$04,$05,$06,$01,$04,$02,$03,$01,$04,$07
  .byt $08,$01,$01,$02,$09,$01,$04,$0a,$0b,$01,$0c,$02,$09,$01,$04,$0d
  .byt $0e,$0f,$02,$02,$10,$0f,$11,$12,$13,$0f,$11,$02,$10,$0f,$11,$14
  .byt $15,$0f,$0f,$02,$10,$0f,$11,$16,$17,$0f,$18,$02,$10,$0f,$11,$19
  .byt $1a,$1b,$02,$02,$02,$1b,$1c,$1d,$1e,$1b,$1c,$02,$1f,$1b,$1c,$20
  .byt $21,$1b,$1b,$02,$02,$1b,$1c,$22,$23,$1b,$24,$02,$02,$1b,$1c,$25
  .byt $26,$27,$02,$02,$28,$27,$29,$2a,$2b,$27,$29,$02,$1f,$27,$29,$2c
  .byt $2d,$27,$27,$02,$28,$27,$27,$2e,$2f,$27,$30,$02,$1f,$27,$29,$31
  .byt $32,$33,$02,$02,$34,$33,$35,$36,$37,$10,$38,$02,$34,$33,$35,$39
  .byt $3a,$33,$33,$02,$34,$33,$35,$3b,$3c,$33,$3d,$02,$28,$33,$28,$3e
  .byt $3f,$40,$41,$02,$3f,$40,$41,$42,$43,$40,$44,$02,$3f,$40,$41,$45
  .byt $46,$40,$40,$02,$3f,$40,$41,$47,$48,$40,$49,$02,$3f,$40,$41,$4a
  .byt $4b,$4c,$02,$02,$4b,$4c,$18,$4d,$4e,$4c,$4f,$50,$4b,$4c,$18,$51
  .byt $52,$4c,$4c,$02,$02,$4c,$18,$53,$54,$4c,$55,$56,$02,$4c,$18,$57
  .byt $58,$59,$02,$02,$58,$59,$0c,$5a,$5b,$59,$5c,$02,$58,$59,$0c,$5d
  .byt $5e,$59,$59,$02,$02,$59,$0c,$5f,$60,$59,$61,$02,$02,$59,$0c,$62
; Lookup table that maps OpCode to addressing mode ID.  FIXME: Pack in to nybbles
@OPCODE_ADDRESSING_MODE_IDS:
  .byt $06,$0b,$07,$07,$0a,$0a,$0a,$0a,$09,$06,$05,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$0a,$0c,$0c,$0a,$07,$03,$05,$07,$00,$02,$02,$08
  .byt $00,$0b,$07,$07,$0a,$0a,$0a,$0a,$09,$06,$05,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$0c,$0c,$0c,$0a,$07,$03,$05,$07,$02,$02,$02,$08
  .byt $09,$0c,$07,$07,$07,$0a,$0a,$0a,$09,$06,$05,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$07,$0c,$0c,$0a,$07,$03,$09,$07,$07,$02,$02,$08
  .byt $09,$0b,$07,$07,$0a,$0a,$0a,$0a,$09,$06,$05,$07,$04,$00,$00,$08
  .byt $08,$0f,$0e,$07,$0c,$0c,$0c,$0a,$07,$03,$09,$07,$01,$02,$02,$08
  .byt $08,$0b,$07,$07,$0a,$0a,$0a,$0a,$07,$06,$07,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$0c,$0c,$0d,$0a,$07,$03,$07,$07,$00,$02,$02,$08
  .byt $06,$0b,$06,$07,$0a,$0a,$0a,$0a,$07,$06,$07,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$0c,$0c,$0d,$0a,$07,$03,$07,$07,$02,$02,$02,$08
  .byt $06,$0b,$07,$07,$0a,$0a,$0a,$0a,$07,$06,$07,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$07,$0c,$0c,$0a,$07,$03,$09,$07,$07,$02,$02,$08
  .byt $06,$0b,$07,$07,$0a,$0a,$0a,$0a,$07,$06,$07,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$07,$07,$0c,$0c,$0a,$07,$03,$09,$07,$07,$02,$02,$08
; Table of offsets past @MODE_FORMS indexed by addressing mode ID
@ADDRESSING_MODE_OFFSETS:
  ; Table indexed by addressing mode ( with gaps that other variables can use)
  ; giving the offset in to the string table ( beginning at @absolute) of the
  ; format for the addressing mode.  Note that program counter relative
  ; adressing is handled separately.
  .byt @absolute - @MODE_FORMS
  .byt @absolute_indexed_indirect - @MODE_FORMS
  .byt @absolute_indexed_with_x - @MODE_FORMS
  .byt @absolute_indexed_with_y - @MODE_FORMS
  .byt @absolute_indirect - @MODE_FORMS
  .byt 0  ; accumulator - may be used for another variable
  .byt @immediate - @MODE_FORMS
  .byt 0  ; implied - may be used for another variable
  .byt 0  ; program_counter_relative - may be used for another variable
  .byt 0  ; stack - may be used for another variable
  .byt @zero_page - @MODE_FORMS
  .byt @zero_page_indexed_indirect - @MODE_FORMS
  .byt @zero_page_indexed_with_x - @MODE_FORMS
  .byt @zero_page_indexed_with_y - @MODE_FORMS
  .byt @zero_page_indirect - @MODE_FORMS
  .byt @zero_page_indirect_indexed_with_y - @MODE_FORMS
  @phex8 = %10010000
  @phex16 = %10110100
@MODE_FORMS:
  @absolute:                          .byt @phex16,0            ; lda $1234
  @absolute_indexed_indirect:         .byt "(",@phex16,",x)",0  ; lda ($1234,x)
  @absolute_indexed_with_x:           .byt @phex16,",x",0       ; lda $1234,x
  @absolute_indexed_with_y:           .byt @phex16,",y",0       ; lda $1234,y
  @absolute_indirect:                 .byt "(",@phex16,")",0    ; jmp ($1234)
  @immediate:                         .byt "#",@phex8,0         ; lda #$12
  @zero_page:                         .byt @phex8,0             ; lda $34
  @zero_page_indexed_indirect:        .byt "(",@phex8,",x)",0   ; lda ($34,x)
  @zero_page_indexed_with_x:          .byt @phex8,",x",0        ; lda $34,x
  @zero_page_indexed_with_y:          .byt @phex8,",y",0        ; lda $34,y
  @zero_page_indirect:                .byt "(",@phex8,")",0     ; lda ($34)
  @zero_page_indirect_indexed_with_y: .byt "(",@phex8,"),y",0   ; lda ($34),y
.code


;read_operand16:
;  ldx #<dump_ptr
;  jsr read_from_stream  ; A is now LO byte of 16-bit value
;  tay
;  jsr read_from_stream
;  tax                   ; X is now HI
;  tya
;  rts
;
;read_operand8:
;  ldx #<dump_ptr
;  jsr read_from_stream
;  rts


; @param  X   Address in ZP of 16-bit value
;
dump_zp16:
  pha
  tya
  pha
  lda $01,x
  jsr phex8
  lda $00,x
  jsr phex8
  pla
  tay
  pla
  rts

.if 1
dump_sp:
  phaxy
  tsx         ; X is now the SP
  inx         ; X += 3 to compensate for the 3 bytes to remember Y, X and A
  inx
  inx
  inx         ; X += 2 to compensate for the 2 bytes by which the stack was adjusted for the return address from this method
  inx
  txa         ; A is now the SP as it was before this method was invoked
  pha
  ldx #<@SP
  ldy #>@SP
  jsr printfu
  plyxa
  rts

@SP:
  .byt "SP:",%10010000,$0d,$0a,0
.endif


delay:
  phx
  phy
  ldy #$10
@inner:
  ldx #$00
: dex
  bne :-
  dey
  bne @inner
  ply
  plx
  rts


; For invoking in the middle of a method to provide a trace of values through execution.
;
; Destroys `brk_sp` so don't use from within monitor
;
trace:
  ;sta @saved_a
  ;sta @saved_x
  ;sta @saved_y
  php           ; Mimic what is pushed to the stack on BRK so that dump_registers gets what it expects
  phaxy

  tsx
  inx           ; SP points to empty slot, so INX so $0100+X points to saved Y instead
  stx brk_sp
  inx           ; The dump should show the part of stack from where SP was before "trace" was invoked, so X needs adjusting past the things pushed on to the stack since.  After this second INX it points to saved X, which we're still not interested in
  inx           ; to saved A
  inx           ; to saved P
  inx           ; to return address
  inx
  inx           ; now $0100+X points to whatever was on the stack before the return address was pushed by JSR
  ;stx dump_ptr  ; FIXME: Don't overwrite dump_ptr
  ldx #$01      ; HI byte of stack
  stx brk_sp+1
  jsr dump_registers

;  lda #$01
;  sta dump_ptr+1
;  lda #<dump_hex      ; FIXME: Don't overwrite dump_func_ptr
;  ldx #>dump_hex
;  jsr set_dump_func
;  lda #1
;  jsr dump

  plyxa
  plp
  ;lda @saved_a
  ;lda @saved_x
  ;lda @saved_y
  rts

;@saved_a: .byt 0
;@saved_x: .byt 0
;@saved_y: .byt 0


; @param  X   LO byte ptr to address to dump
; @param  Y   HI byte ptr to address to dump
;
dump_t:

  phaxy

  stx dump_ptr
  sty dump_ptr+1

  lda #<dump_hex      ; FIXME: Don't overwrite dump_func_ptr
  ldx #>dump_hex
  jsr set_dump_func

  lda #1      ; Numbr of rows to show
  jsr dump

  plyxa

  rts


;------------------------------------------------------------------------------
;
; Library - not specific to the monitor

; Idea: "stack frame" in ZP.  Terrified of using ZP because can never do proper
; job of deciding what is important enough to store there.  Recursion stores
; return address on the stack.  Saving registers also uses stack.  Could use
; stack for method local variables too, but ZP faster.
;   lda #5  ; Requesting 5 bytes of variable space on the stack
;   jsr request_zp_stack_space    ; X is now set to the base address in ZP of the allocated space
;   jsr release_zp_stack_space    ; could either lda #5 first or keep track of sizes of blocks for fewer programming errors

; This idea avoids ZP temp_ptr0 and associated programming errors when one subroutine invokes another that clobbers the same space in ZP


; Looks up an entry in a map of bytes to 16-bit values.  The map is structured as:
;
;   - A byte indicating the number of entries in the map + 1
;   - A list of 8-bit keys, terminated by a zero
;   - A list of 16-bit values ( perhaps pointers) with no termination
;     immediately following the keys
;
;     .byt  3, 4, 9, 0, $6d, $09, $9f, $08   ; 4:$096d, 9:$089f
;
; @param  A   LO byte of ptr to map
; @param  X   HI byte of ptr to map
; @param  Y   The key to look up
; @return   C   Set if found, Clear otherwise, in which case A and X are undefined
; @return   A   LO byte of value
; @return   X   HI byte of value
; @destroys   A X Y C
;
map:
  sta map_ptr
  stx map_ptr+1
                        ; Load the number of entries in the map + 1.  Later on it
                        ; must be added to map_ptr to get to the list of values
  ldx #<map_ptr
  jsr read_from_stream  ; A is now the number of entries in the map + 1 and map_ptr now points at the keys
  sta @entries+1

  tya                   ; A is now the key to look up
  ldx map_ptr           ; Look for the key
  ldy map_ptr+1
  jsr index

  bcc :+                ; If the key was not found then leave the carry clear and return

  ldx #<map_ptr         ; Move map_ptr forward so that it refers to the list of values rather than keys
  pha                   ; A is currently the index of the entry found
  @entries:
  lda #$ff              ; $ff has been replaced with the number of entries in the map + 1
  jsr advance_zp_ptr

  pla                   ; A is now the index of the entry found
  asl
  tay                   ; Y is now the byte offset from the beginning of the list of values
  iny                   ; Y now points to HI
  lda (map_ptr),y
  tax                   ; X is now HI
  dey
  lda (map_ptr),y       ; A is now LO
  sec

: rts


; Finds the index within a C string of the given character.
;
; @param  A   The character to look for
; @param  X   LO byte of ptr to string in which to look
; @param  Y   HI byte of ptr to string in which to look
; @return   C   Set if found, Clear otherwise
; @return   A   The index of the specified character in the string if found,
;               undefined otherwise
; @destroys   X
;
index:
  stx @load+1     ; Self-modifying code
  sty @load+2
  sta @compare+1
  ldx #$ff        ; Start with -1 so that the first INX refers to the first character
@loop:
  inx
@load:
  lda $ffff,x
  beq @absent     ; The end of the string is denoted with a 0
@compare:
  cmp #$ff        ; Compare the character from the string to the specified character
  bne @loop       ; Branch if not the same
  txa             ; A is now the index within the string at which the specified character was found
  sec             ; The C flag should be set to indicate that the character was found
  rts
@absent:
  clc             ; The C flag should be cleared to indicate that the character was absent
  rts


irq_handler:
  ; FIXME: Test the B flag and only invoke brk_handler if 1
  jmp brk_handler


nmi_handler:
  rti


.segment "VECTORS"
  .word nmi_handler, reset_handler, irq_handler

