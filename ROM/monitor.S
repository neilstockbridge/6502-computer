
; A monitor program driven by a VT100 ; terminal ( perhaps using ANSI escape
; codes) over a serial terminal.
;
; NOTE: This began on a C64, so there may be opportunities to make things more
; compact with W65C02 instructions

; PLAN
;   - Zero-page stack idea
;   - Disassembly
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
; c[AAAA]   Continue from BRK ( or to specified address)
; bl        BREAKPOINT LIST
; bs0,1234  BREAKPOINT, SET #0 at address 1234.  Two bytes at address are saved in slot #0 and replace with BRK #0
; br7       BREAKPOINT, REMOVE #7
; r         Show processor registers ( as they were at BRK)
; s         Single Step
; a 1234    Begin assembly at 1234
; ?         memset, memmove, directory, load/save region to/from file
;
;
; # Ideas
;
;   - Auto-single-step: BRK then dump registers ( and perhaps inspect the
;     instruction and dump memory that it references) then set a BRK at the
;     next instruction and return.  Provides a trace over serial of the whole
;     execution.  Would likely need to switch it on and off to capture the
;     trouble section only otherwise too much output to wade through

.import UART_getc, UART_putc

getc = UART_getc
putc = UART_putc

.export printfu, phex8, phex4, pstr, print_space, con_next_line, map, index, read_from_stream, add_to_ptr, inc_ptr ; so that they apear in the label file
.export reset_handler, irq_handler, nmi_handler
.export init, main, cmdline, cursor, request, brk_handler, dump_registers, set_dump_func, dump, dump_hex, dump_ascii, dump_instructions, trace, check_equal, check_carry, check_equal, check_carry
.if .defined(test)
.export test
.endif
.if .defined(dump_sp)
.export dump_sp
.endif


.macro  phaxy
  pha
  phx
  phy
.endmacro


.macro  plyxa
  ply
  plx
  pla
.endmacro


.include "zero-page.inc"

K_ENTER = $0d
K_BACKSPACE = $7f


reset_handler:
init:
  ldx #$ff  ; Initialize the stack pointer
  txs

  lda #<dump_instructions      ; Default dump interpretation
  ldx #>dump_instructions
  jsr set_dump_func

  lda #$39  ; Default
  jsr write_ansi_color
  ldx #<@READY
  ldy #>@READY
  .define init_msg .sprintf("%c%cNeil's 6502 SBC R1%c%c15K RAM SYSTEM%c%cREADY%c%c", $0d, $0a, $0d, $0a, $0d, $0a, $0d, $0a)
  .rodata
  @READY: .byt .strlen(init_msg), init_msg
  .code
  jsr pstr

  stz dump_ptr
  lda #$f0
  sta dump_ptr+1
  ; Fall through to main

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
  jsr con_next_line     ; Move the cursor to the next line
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

  cmp #$69              ; 'i'
  bne @maybe_dump

  jsr read_from_stream  ; Read the character following 'I'
  tay                   ; Y is now the character that followed 'I'
  lda #<@DUMP_FUNC_MAP
  ldx #>@DUMP_FUNC_MAP
  jsr map
  bcc @bad_request
  jsr set_dump_func
  rts

@maybe_dump:
  cmp #$64              ; 'd'
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

  ;jsr con_next_line
  ;jsr test
  rts

@maybe_dump_registers:
  cmp #$72             ; 'r'
  bne @maybe_continue

  jmp dump_registers

@maybe_continue:
  cmp #$63          ; 'c'
  bne @maybe_test

  ; The stack holds the return address in main then Y,X,A,flags,PC(BRK)
  pla   ; Discard the return address in "main"
  pla
  ; The main IRQ/BRK handler saved A, X and Y, so restore them:
  plyxa
  rti

@maybe_test:
  cmp #$74          ; 't'
  bne @bad_request

  jsr dump_sp
  brk
  nop   ; "signature" ( BRK parameter)

  lda #$62  ; 'b' for back from monitor
  jsr putc
  jsr dump_sp

  jsr parse_hex8  ; Abuse dump_ptr to store parameters for test
  sta dump_ptr+1
  jsr parse_hex8
  sta dump_ptr
  jsr parse_hex8

  ;.if .defined(test)
  jsr test
  ;.endif
  rts

@bad_request:
  ldx #<@BAD_REQUEST
  ldy #>@BAD_REQUEST
  jsr pstr

  rts

.data
@DUMP_FUNC_MAP:
  .byt 4, "h",      "a",        "i", 0
@DUMP_FUNC_MAP_VALUES:
  .word    dump_hex, dump_ascii, dump_instructions

@BAD_REQUEST:
  .byt .strlen("Bad request\r\n"), "Bad request",$0d,$0a
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
  jsr printfu
  rts

@FLAGS: .byt "NV1BDIZC"
@REGS:
  .byt %10010000,%10010000," A:",%10010000," X:",%10010000," Y:",%10010000," S:",%10010000,"  ",printfu_putc,printfu_putc,printfu_putc,printfu_putc,printfu_putc,printfu_putc,printfu_putc,printfu_putc,$0d,$0a,0

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
  jsr con_next_line ; Move the console cursor to the next line
  dec lines_to_dump
  bne:-
  rts


; Limit to 40 columns
; Each line begins with an address.  Generic for different dump types
;1000  00 00 00 00 00 00 00 00  abcdefgh
;
dump_hex:
  ldy #8            ; Number of bytes to dump
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
  jsr add_to_ptr
  tya                               ; A is now the mnemonic ID once more
  jsr add_to_ptr                    ; mnemonic_stream now points to @MNEMONICS + 3 * mnemonic_id
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
: jsr phex16
  rts

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
  .byt $00,$0b,$00,$00,$0a,$0a,$0a,$0a,$09,$06,$05,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$0a,$0c,$0c,$0a,$07,$03,$05,$00,$00,$02,$02,$08
  .byt $00,$0b,$00,$00,$0a,$0a,$0a,$0a,$09,$06,$05,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$0c,$0c,$0c,$0a,$07,$03,$05,$00,$02,$02,$02,$08
  .byt $09,$0c,$00,$00,$00,$0a,$0a,$0a,$09,$06,$05,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$00,$0c,$0c,$0a,$07,$03,$09,$00,$00,$02,$02,$08
  .byt $09,$0b,$00,$00,$0a,$0a,$0a,$0a,$09,$06,$05,$00,$04,$00,$00,$08
  .byt $08,$0f,$0e,$00,$0c,$0c,$0c,$0a,$07,$03,$09,$00,$01,$02,$02,$08
  .byt $08,$0b,$00,$00,$0a,$0a,$0a,$0a,$07,$06,$07,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$0c,$0c,$0d,$0a,$07,$03,$07,$00,$00,$02,$02,$08
  .byt $06,$0b,$06,$00,$0a,$0a,$0a,$0a,$07,$06,$07,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$0c,$0c,$0d,$0a,$07,$03,$07,$00,$02,$02,$02,$08
  .byt $06,$0b,$00,$00,$0a,$0a,$0a,$0a,$07,$06,$07,$07,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$00,$0c,$0c,$0a,$07,$03,$09,$07,$00,$02,$02,$08
  .byt $06,$0b,$00,$00,$0a,$0a,$0a,$0a,$07,$06,$07,$00,$00,$00,$00,$08
  .byt $08,$0f,$0e,$00,$00,$0c,$0c,$0a,$07,$03,$09,$00,$00,$02,$02,$08
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
  @immediate:                         .byt "#",@phex8,0        ; lda #$12
  @zero_page:                         .byt @phex8,0            ; lda $34
  @zero_page_indexed_indirect:        .byt "(",@phex8,",x)"     ; lda ($34,x)
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


test:
.if .defined(test)

  ; For brute-force testing from Ruby.
  ; A: 8-bit signed
  ; dump_ptr: 16-bit unsigned

  ; add-s8-to-u16.S:
  ; subroutine + test

  ; Works but larger and slower ( probably)
  ; When Carry, inc or dec depending on sign (N) of s8 (A)
;  pha
;  clc
;  adc dump_ptr
;  sta dump_ptr
;  pla             ; Sets N but not C
;  bmi :+
;  bcc @out
;  inc dump_ptr+1
;  bra @out
;: bvs @out
;  dec dump_ptr+1
;  bra @out

  jsr add_s8_to_u16

@out:
  lda dump_ptr+1
  jsr phex8
  lda dump_ptr
  jsr phex8
  jsr con_next_line
  rts

  ; add_to_ptr

  lda #$01
  sta $02
  lda #$00
  sta $03
  ldx #$02
  lda #$80
  jsr add_to_ptr
  lda $02
  ldx #$81
  jsr check_equal
  lda $03
  ldx #$00
  jsr check_equal


;  ldx #<@VALUES
;  ldy #>@VALUES
;  lda #0            ; 0:$1234
;  jsr load_from_xy
;  tay               ; Preserve Actual LO because A is about to be bashed
;  txa               ; A is now actual HI
;  ldx #$12          ; X is expected HI
;  jsr check_equal
;
;  tya               ; A is now actual LO once again
;  ldx #$34          ; X is expected LO
;  jsr check_equal
;
;  ldx #<@VALUES
;  ldy #>@VALUES
;  lda #1            ; 1:$6789
;  jsr load_from_xy
;  tay               ; Preserve Actual LO because A is about to be bashed
;  txa               ; A is now actual HI
;  ldx #$67          ; X is expected HI
;  jsr check_equal
;
;  tya               ; A is now actual LO once again
;  ldx #$89          ; X is expected LO
;  jsr check_equal


  ; map

  lda #<@MAP
  ldx #>@MAP
  ldy #9            ; Maps to $6789
  jsr map           ; A is now actual LO and X is actual HI
  stx @actual_hi+1  ; X will be destroyed so keep it somewhere
  ;     NV1BDIZC
  ldx #%00000001    ; C should be 1
  jsr check_carry

  ldx #$89          ; X is now expected LO
  jsr check_equal

  @actual_hi:
  lda #$ff          ; A is now actual HI
  ldx #$67
  jsr check_equal


  ; old map

;  lda #>@VALUES
;  pha
;  lda #<@VALUES
;  pha
;  ldx #<@KEYS
;  ldy #>@KEYS
;  lda #9          ; Maps to $6789
;  jsr map
;  stx @saved_x+1
;  tay             ; Save A in Y
;  ;     NV1BDIZC
;  ldx #%00000001  ; C should be 1
;  jsr check_carry
;
;  ; X should be $67
;  txa             ; A is now what X was after "map"
;  ldx #$67
;  @saved_x:
;  lda #$ff
;  jsr check_equal
;
;  tya             ; Restore A from Y.  It's now what A was after "map"
;  ldx #$89
;  jsr check_equal
;  jsr dump_sp


  ; Test parse_hex8

;  lda #<@FIVE_A
;  sta tmp_ptr0
;  lda #>@FIVE_A
;  sta tmp_ptr0+1
;
;  ldx #<tmp_ptr0
;  jsr parse_hex8
;
;  ldx #$5a
;  jsr check_equal

  ;lda #$5a
  ;ldx #$1e
  ;jsr check_equal  ; to test check_equal with its new use of printfu

;  ;     NV1BDIZC
;  ldx #%00000010
;  lda #$ff
;  sta tmp0
;  inc tmp0        ; See which flags INC affects when it overflows.  Z is set but C is not
;  jsr @check_flags

;  ;     NV1BDIZC
;  ldx #%00000011
;  lda #$ff
;  clc
;  adc #1          ; Adding #1 to #$ff sets both Z AND C flags
;  jsr @check_flags
;
;  lda #5
;  ldx #<@LOOKUP
;  ldy #>@LOOKUP
;  jsr index
;  ;     NV1BDIZC
;  ldx #%00000001  ; C should be 1
;  jsr check_carry
;  bcs :+
;  ldx #2
;  jsr check_equal
;:
;
;  lda #2
;  ldx #<@LOOKUP
;  ldy #>@LOOKUP
;  jsr index
;  ;     NV1BDIZC
;  ldx #%00000000  ; C should be 0
;  jsr check_carry
;
;  lda #>@VALUES
;  pha
;  lda #<@VALUES
;  pha
;  ldx #<@KEYS
;  ldy #>@KEYS
;  lda #2          ; This key is not in the map
;  jsr map
;  ;     NV1BDIZC
;  ldx #%00000000  ; C should be 0
;  jsr check_carry

  ; Test parse_nybble
;  lda #$30          ; ASCII '0'
;  jsr parse_nybble
;  ldx #$0           ; Should be parsed as 0
;  jsr check_equal
;
;  lda #$39          ; ASCII '9'
;  jsr parse_nybble
;  ldx #$9           ; Should be parsed as 9
;  jsr check_equal
;
;  lda #$61          ; ASCII 'a'
;  jsr parse_nybble
;  ldx #$a           ; Should be parsed as 0xa
;  jsr check_equal
;
;  lda #$66          ; ASCII 'f'
;  jsr parse_nybble
;  ldx #$f           ; Should be parsed as 0xf
;  jsr check_equal

  ; Test read_from_stream
;  lda #<(@T+1)
;  sta tmp_ptr0
;  lda #>(@T+1)
;  sta tmp_ptr0+1
;
;  ldx #<tmp_ptr0
;  jsr read_from_stream
;  ldx #$61 ; 'a'
;  jsr check_equal
;
;  ldx #<tmp_ptr0
;  jsr read_from_stream
;  ldx #$3a ; ':'
;  jsr check_equal

  ; Test printfu
;  ldx #<@T
;  ldy #>@T
;  jsr pstr
;  tsx
;  txa
;  jsr phex8
;  jsr con_next_line
;
;  lda #>@B   ; Y first
;  pha
;  lda #<@B
;  pha
;  lda #$5a
;  pha
;  ldx #<@A
;  ldy #>@A
;  jsr printfu
;
;  ldx #<@T
;  ldy #>@T
;  jsr pstr
;  tsx
;  txa
;  jsr phex8
;  jsr con_next_line

  rts

@check_flags:
  php
  pla
  and #$c3        ; Mask out the 1BDI flags
  jsr check_equal
  rts

.data
@MAP:
  .byt 3
@KEYS:
  .byt      4,     9, 0
@VALUES:
  .word $1234, $6789
@LOOKUP:
  .byt 1,3,5,7,9,0
@FIVE_A:
  .byt "5a"
@T:
  .byt 2,"a:"
@A:
  .byt "hello. b:",%10010000,",s:",%11100001,0
@B:
  .byt 5,"exstr"
.code
.endif


; Prints an error message if C is not the same as X
;
; @param  C   The actual value
; @param  X   The expected value
; @destroys  None
;
check_carry:
  pha             ; Save A
  php             ; Isolate C
  pla
  ;     NV1BDIZC
  and #%00000001
  jsr check_equal
  pla             ; Restore A
  rts


; Prints an error message if A is not the same as X
;
; @param  A   The actual value
; @param  X   The expected value
; @destroys  None
;
check_equal:

  stx @compare+1  ; Modify the CMP instruction below so that it compares A to the current value of X
@compare:
  cmp #$ff
  beq :+          ; If A == X then that's good and we're done

  phaxy           ; Save all registers to avoid the need at invocation and because speed doesn't matter here

  pha             ; Push A first.  It's what we got
  txa             ; Push X.  It's what we expected
  pha
  ldx #<@ISSUE
  ldy #>@ISSUE
  jsr printfu

  plyxa

: rts

.data
@ISSUE:
  .byt "Expected:",%10010000,",got:",%10010000,$0d,$0a,0
.code


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


; Adds a signed 8-bit value to an unsigned 16-bit value.
;
; @param  A   The signed 8-bit value
; @param  X   The address in ZP of the unsigned 16-bit value
; @preserves  X Y
;
add_s8_to_u16:

  @hi = $01   ; Offset from address X in ZP
  @lo = $00

  bpl :+      ; If A is -ve then pre-decrement HI
  dec @hi,x
: clc
  adc @lo,x
  sta @lo,x
  bcc :+
  inc @hi,x
: rts


; A cut-down printf.  Would be interesting to compare the code savings between
; this ( assuming no extra coolness like padding is required of printf) to
; printf to multiple seperate printing calls ( pstr, phex8, pstr, etc.) in the
; caller.
;
; Only support ASCII ( codes <= 127) is supported so that the MSB:1 can be used
; for placeholders.
;
;       ; Params for formatters pushed Y, then X then A, rightmost placeholder
;       ; first so that printfu can work up the stack.  It does kung-fu to
;       ; remember the return address of the caller.
;       lda #>@mystr  ; Y: HI
;       pha
;       lda #<@mystr  ; X: LO
;       pha
;       lda #$5a      ; A: byte to turn in to hex
;       pha
;       ldx <@format
;       ldy <@format
;       jsr printfu
;     @format:
;       .byt "f1:", %10010000, ",f2:", %11100001
;                    ^^^^   ^            |||   \Formatter#1
;                    |YXA   \Formatter#0 \Takes Y and X as params
;                    \Placeholder flag
;
; @param  X   LO byte of address of format string
; @param  Y   HI byte of address of format string
; @destroys   A X Y
; @returns  Only if the pushing of parameters on to the stack matches with the
;           formatter parameters in the format string
;
printfu:
  ; FIXME: There's currently a problem using formatter#1 (pstr), or maybe it's
  ; just with pulling X and/or Y or more than one parameter from the stack

  ; Remember the return address because this code is going to pull the
  ; parameters off the stack ( so the caller doesn't need to)
  pla
  sta @ret_addr_lo+1
  pla
  sta @ret_addr_hi+1

  stx @strbase+1
  sty @strbase+2
  ldy #$00        ; Y is the offset from the beginning of the string data

@loop:
@strbase:
  lda $ffff,y     ; Load a character
  beq @finished   ; If the terminator is found
  bpl @ascii      ; If MSB is 0 then this is a normal ASCII character, not a placeholder

  sty printfu_y_safe    ; Remember Y because the formatter might require it as a parameter or destroy it
  asl                   ; *2 turns the formatter index in to a byte offset in to the table.  ( & 0xf) << 1 would be more natural
  sta printfu_flags     ; Use a ZP location for ASL because A is destroyed by all the PLAs below
  and #$1e              ; This would normally be "and #$0f" but it's been pre-ASL'd above
  tax                   ; X is now the byte offset into @formatters of the ptr to the formatter routine
  lda @formatters,x     ; Copy the pointer to the formatter routine to the self-modified JSR below
  sta @formatter_ptr+1
  lda @formatters+1,x
  sta @formatter_ptr+2
  ;lda printfu_flags
  ;jsr phex8
  ;jsr dump
  asl printfu_flags ; Shift left so that the bit that indicates if the formatter takes Y as a parameter is shifted out in to the C flag
  bcc :+            ; If the formatter doesn't take Y as a param then it won't have been pushed to the stack, so don't pull it off
  pla
  tay               ; The Y parameter is now set.  Don't destroy it while preparing the rest
: asl printfu_flags ; The bit controlling the X parameter is now in C
  bcc :+            ; If the formatter doesn't take X as a param then it won't have been pushed to the stack, so don't pull it off
  pla
  tax
: asl printfu_flags ; The bit controlling the A parameter is now in C
  bcc :+            ; If the formatter doesn't take A as a param then it won't have been pushed to the stack, so don't pull it off
  pla
:
@formatter_ptr:
  jsr $ffff
  ldy printfu_y_safe    ; Restore Y
  iny
  bne @loop

@ascii:
  jsr putc        ; Print the character
  iny             ; Advance to the next character
  bne @loop       ; Loop unless there are no more characters ( zero used here to prevent infinite loop as Y overflows)

@finished:
@ret_addr_hi:     ; Restore the return address on the stack
  lda #$ff
  pha
@ret_addr_lo:
  lda #$ff
  pha
  rts

; A list of pointers to functions that format values for placeholders
@formatters:
  .word phex8, pstr, phex4, putc, phex16

printfu_putc = %10010011


; @param  X   Index in ZP of ptr to two hex digits represented in ASCII.
; @return   A   The value of the hex byte
; @destroys   A
;
parse_hex8:
;  sta @ptr+1
;  stx @ptr+2
;@ptr:
;  lda $ffff   ; Load the character that contains the representation of the nybble.  $ffff is a placeholder for self-modifying code
  jsr read_from_stream  ; Read the HI nybble

  jsr parse_nybble
  asl
  asl
  asl
  asl
  sta @or+1
  jsr read_from_stream  ; Read the LO nybble

  jsr parse_nybble
@or:
  ora #$ff              ; Combine the HI and LO
  rts


; Provides the numeric value of a nybble represented in ASCII.
;
; @param    A   An ASCII character representing a hex nybble '0'..'9' or
;               'a'..'f'.  No error checking is performed and the results are
;               undefined for input outside this range
; @return   A   The value of the nybble
; @destroys   A
;
parse_nybble:
  ; A should be $30..$39 or $61..$66.  No error checking to minimize code size
  cmp #$3a
  sec
  bpl :+      ; (A - $3a) will be +ve when A >= $3a, i.e. 'a'..'f'
  sbc #$30    ; $30 is '0' in ASCII
  rts
: sbc #$61-10    ; $61 is 'a' in ASCII
  rts


; Prints a 16-bit value in hex.
;
; @param      A   The LO byte of the value to print
; @param      X   The HI byte of the value to print
; @destroys   A X Y C
; TODO: Consider writing "@preserves" rather than "@destroys"
;
phex16:
  pha
  txa
  jsr phex8
  pla
  jsr phex8
  rts


; Prints a byte in hex
;
; @param      A   The byte to print
; @destroys   A Y C
;
phex8:
  tay ; Save the LO nybble while A is trashed
  lsr
  lsr
  lsr
  lsr
  jsr phex4
  tya ; Get the LO nybble back
  jsr phex4
  rts


; Prints a hex nybble
;
; @param      A   The value to print
; @destroys   A C
;
phex4:
  and #$0f
  cmp #$0a
  clc
  bpl @gt10
  adc #$30      ; $30 is ASCII '0'
  bpl @print
@gt10:
  adc #-10+$61  ; $61 is ASCII 'a'
@print:
  jsr putc
  rts


; Pascal-style strings, or C strings?
; Try out Pascal because I can't remember the drawbacks.  Fast strlen is a benefit.  Not supporting strings longer than 255 characters
;
;  X: LO byte of ptr to string
;  Y: HI byte of ptr to string
;
; Destroys: A, X, Y
;
pstr:
  stx tmp_ptr0      ; Use some scratch space in ZP for the pointer to the string data
  sty tmp_ptr0+1
  ldy #$00          ; Y is the offset from the beginning of the string data
  lda (tmp_ptr0),y
  beq @done         ; If the length is 0 then return
  iny               ; Advance to the first character in the string
  tax               ; X is now the number of characters remaining to print
: lda (tmp_ptr0),y  ; Load a character
  iny               ; Advance to the next character
  jsr putc          ; Print the character
  dex               ; One less characters to print
  bne :-            ; Loop unless there are no more characters
@done:
  rts


; Prints a space character.  Saves two bytes loading A with the space character
; code in all the places that a space is required.
;
; @destroys   A
;
print_space:
  lda #$20    ; ASCII space character
  jsr putc
  rts


; Prints a line terminator ( End Of Line).
;
; @destroys   A
;
con_next_line:
  lda #$0d
  jsr putc
  lda #$0a
  jsr putc
  rts


; Writes an ANSI escape sequence for changing the foreground color.
;
; @params  A  Code for the color:
;               - $30 Black
;               - $31 Red
;               - $32 Green
;               - $33 Yellow
;               - $34 Blue
;               - $35 Magenta
;               - $36 Cyan
;               - $37 Light gray
;               - $39 Default foreground color
; @params  C  Set for "bold" ( high intensity)  seems to actually set bold rather than hi-int, which I don't want
;
write_ansi_color:

  pha
  lda #$1b  ; ESC
  jsr putc
  lda #$5b  ; '['
  jsr putc
  lda #$33  ; '3'
  jsr putc
  pla
  jsr putc
  ;bcc :+
  ;lda #$3b  ; ';'
  ;jsr putc
  ;lda #$30  ; '1'
  ;jsr putc
;:
  lda #$6d  ; 'm'
  jsr putc
  rts

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
  jsr add_to_ptr

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


; A Stream just a 16-bit pointer in ZP to a stream of bytes ; ( typically a
; string).  This method reads a byte from the memory location referenced by the
; pointer and then advances the pointer.
;
; @param    X   The address in ZP of the Stream
; @return   A   The next byte from the stream
; @destroys  A
;
read_from_stream:
  lda ($00,x)
  jsr inc_ptr
  rts


; @param  X  The address in ZP of the pointer
; @param  A  The amount by which to advance the pointer
; @destroys   A
;
add_to_ptr:
  clc
  adc $00,x
  sta $00,x
  bcc :+
  inc $01,x
: rts


; Advances a pointer to the next byte.
;
; @param  X   The address in ZP of the pointer
; @destroys  Nothing
;
inc_ptr:
  inc $00,x
  bne :+
  inc $01,x
: rts


irq_handler:
  ; FIXME: Test the B flag and only invoke brk_handler if 1
  jmp brk_handler


nmi_handler:
  rti


.segment "VECTORS"
  .word nmi_handler, reset_handler, irq_handler

