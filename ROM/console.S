
.export parse_hex4
.export parse_hex8
.export print_space
.export write_eol
.export write_ansi_color
.export pstr
.export write_cstr
.export phex8
.export phex16
.export show_A
.export printfu

.import zps_phya
.import adjust_zp_ptr
.import zps_release2
.import read_from_stream
.import UART_putc

write_char = UART_putc
putc = write_char

.include "globals.S"


; Provides the numeric value of a nybble represented in ASCII.
;
; @param    A   An ASCII character representing a hex nybble '0'..'9' or
;               'a'..'f'.  No error checking is performed and the results are
;               undefined for input outside this range
; @return   A   The value of the nybble
; @destroys   A
;
parse_hex4:
  ; A should be $30..$39 or $61..$66.  No error checking to minimize code size
  cmp #$3a
  sec
  bpl :+      ; (A - $3a) will be +ve when A >= $3a, i.e. 'a'..'f'
  sbc #$30    ; $30 is '0' in ASCII
  rts
: sbc #$61-10    ; $61 is 'a' in ASCII
  rts


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

  jsr parse_hex4
  asl
  asl
  asl
  asl
  sta @or+1
  jsr read_from_stream  ; Read the LO nybble

  jsr parse_hex4
@or:
  ora #$ff              ; Combine the HI and LO
  rts


; Prints a space character.  Saves two bytes loading A with the space character
; code in all the places that a space is required.
;
; @destroys   A
;
print_space:
  lda #$20    ; ASCII space character
  jmp putc


; Prints a line terminator ( End Of Line).
;
; @destroys   A
;
write_eol:
  lda #$0d
  jsr putc
  lda #$0a
  jmp putc


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
  jmp putc


; @param    X   Address in ZP of pointer to NUL-terminated string
; @destroys   The ZP ptr
;
write_cstr:
: jsr read_from_stream
  cmp #0
  beq :+
  jsr write_char
  bra :-
: rts


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
  jmp putc


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
  jmp phex4


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
  jmp phex8


; Intended to show short label then value of A for debugging.
; To reduce keyboard-wear, could use PRIMM but don't like the way data in-line
; with code messes up assembly, so instead use a `BIT abs` instr prior to
; indicate location of string
;
show_A:
  php
  phaxy
  ; Look at return addr to see what the absolute addr of the `bit` instr prior
  tsx ; X is now SP
  ; $0100 + SP is the slot to be used next
  ; $0100 + SP + 1 is Y as saved
  ; $0100 + SP + 4 is P as saved
  ; $0100 + SP + 4 + 1 is the LO byte, and:
  ; $0100 + SP + 4 + 2 is the HI byte of the return address (with one subtracted)
  ldy $0100+4+2,x ; Y is HI
  lda $0100+4+1,x ; A is LO
  jsr zps_phya
  ; Go back 2 bytes to get to the address of the JSR instruction
  ; Go back 3 bytes to get to the address of the BIT instruction that preceeded the JSR
  ; Go forward 1 byte to get to the address of the LO byte of the operand of the BIT instruction
  ; A - 2 - 3 + 1 = A - 4
  lda #-4
  jsr adjust_zp_ptr   ; The pointer on the top of the ZP stack now refers to
                      ; the first byte of the 16-bit operard of the `bit`
                      ; instruction that preceded the `jsr`
  jsr read_from_stream  ; De-reference the pointer
  tay                   ; Y is LO, which is unusual
  jsr read_from_stream
  sta $01,x
  sty $00,x
  jsr write_cstr
  jsr zps_release2
  tsx
  lda $0103,x   ; SP+03: A
  jsr phex8
  jsr write_eol
  plyxa
  plp
  rts


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


