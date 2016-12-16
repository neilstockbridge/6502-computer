
.if .defined (TEST)


.export test
.export check_equal
.export check_carry

.import zps_phya
.import zps_release2
.import advance_zp_ptr
.import write_eol
.import pstr
.import phex8
.import add_s8_to_u16
.import erase_4K_of_SPI_flash
.import read_SPI_flash_page
.import power_up_SPI_flash
.import show_cycle_count
.import reset_cycle_counter
.import map
.import printfu

.include "globals.S"


.data
test_id:  ; Index of test so that assertion failures can be traced back to the test easily
  .byte -1
; IRQ pushes PC then P but no registers
captured_A:
  .byt 0
captured_X:
  .byt 0
captured_Y:
  .byt 0
captured_P:
  .byt 0
captured_SP:
  .byt 0
captured_ZPSP:
  .byt 0
.code


; Capture the state of the flags and registers as they were after the test so
; that assertions may be made against them.
; @destroys   AX, Uses stack to push P
.macro capture_state
  php
  sta captured_A
  stx captured_X
  sty captured_Y
  pla
  sta captured_P
  tsx
  stx captured_SP
  ldx zp_sp
  stx captured_ZPSP
  inc test_id
.endmacro

; Make an assertion about the value of A after the test
.macro A_should_be  expected_value
  lda captured_A
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro

; Make an assertion about the value of X after the test
.macro X_should_be  expected_value
  lda captured_X
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro

; Make an assertion about the value of Y after the test
.macro Y_should_be  expected_value
  lda captured_Y
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro

; Make an assertion about the value of P (the processor status flags) after the
; test.
; NV1BDIZC
.macro P_should_be  expected_value
  lda captured_P
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro

; Make an assertion about the value of SP (the stack pointer) after the test.
.macro SP_should_be  expected_value
  lda captured_SP
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro

; Make an assertion about the value of ZPSP (the Zero Page Stack Pointer) after
; the test.
.macro ZPSP_should_be  expected_value
  lda captured_ZPSP
  ldx #expected_value
  jsr check_equal ; A:actual, X:expected
.endmacro


msg:
  .byt "S<", 0


test:
  ;jmp test_instruction_set
  ;jmp test_advance_zp_ptr
  ;jmp test_add_s8_to_u16
  ;jmp test_show_A

;.import write_cstr
;  ldy #>msg
;  lda #<msg
;  jsr zps_phya
;  jsr write_cstr
;  jsr zps_release2
;  rts

  jsr reset_cycle_counter
  nop
  jsr show_cycle_count

  jsr reset_cycle_counter
  jsr show_cycle_count

  jsr reset_cycle_counter
  jsr power_up_SPI_flash
  ;ldy #>$0400
  ;lda #<$0400
  ;jsr zps_phya
  ;jsr read_SPI_flash_unique_identifier
  ;jsr zps_release2
  ;jsr show_cycle_count

  ;lda #$13
  ;jsr erase_4K_of_SPI_flash

  ldya $04, $00     ; $0400-04ff is the buffer to receive the data
  jsr zps_phya      ; X is now the address in ZP of the pointer to $0400
  ldya $03, $09     ; Read from flash address $0000xx
  jsr read_SPI_flash_page
  jsr zps_release2

  rts

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

;@out:
;  lda dump_ptr+1
;  jsr phex8
;  lda dump_ptr
;  jsr phex8
;  jmp write_eol


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

  ; Test parse_hex4
;  lda #$30          ; ASCII '0'
;  jsr parse_hex4
;  ldx #$0           ; Should be parsed as 0
;  jsr check_equal
;
;  lda #$39          ; ASCII '9'
;  jsr parse_hex4
;  ldx #$9           ; Should be parsed as 9
;  jsr check_equal
;
;  lda #$61          ; ASCII 'a'
;  jsr parse_hex4
;  ldx #$a           ; Should be parsed as 0xa
;  jsr check_equal
;
;  lda #$66          ; ASCII 'f'
;  jsr parse_hex4
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
;  jsr write_eol
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
;  jsr write_eol

  rts

@check_flags:
  php
  pla
  and #$c3        ; Mask out the 1BDI flags
  jmp check_equal

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


  .ifref test_instruction_set
  .export test_instruction_set ; So it appears in the .lbl file

test_instruction_set:

  .rodata
  .define MESSAGE .sprintf("Testing instruction set%c%c",$0d,$0a)
  @NOTICE: .byt .strlen(MESSAGE), MESSAGE
  .code

  ldx #<@NOTICE
  ldy #>@NOTICE
  jsr pstr

  ; Check the behaviour of JSR.  Expect:
  ;   // `pc` refers to the Program Counter when it refers to the first byte of
  ;   // the 3-byte JSR instruction.
  ;   address [sp] = (pc + 2) >> 8; // Push HI byte of PC + 2 first
  ;   sp -= 1;
  ;   address [sp] = (pc + 2) & 0xff; // Push LO byte of PC + 2 first
  ;   sp -= 1;
  capture_state     ; Test:00
  SP_should_be $fb  ; Refers to the slot to be used next ($01fb).  Not $01ff because `jsr request` then `jsr test`
  jsr @subroutine   ; This does `capture_state` inside the subroutine, which is Test:01
@return_address:
  ; Grab what was pushed on the stack before any further invocations such as
  ; `check_equal` trash it
  lda $01fb
  sta captured_Y    ; Re-using Y as HI byte, and:
  lda $01fa
  sta captured_A    ; Re-using A as LO byte of return address (minus one)
  SP_should_be $f9  ; 2 less than it was prior to JSR
  A_should_be <(@return_address - 1)
  Y_should_be >(@return_address - 1)

  ; Reassure myself that I know how 8-bit signed math works
  ; Non-overflow scenarios first
  ; Test#0: Add two positive numbers where the result will be 0..7f
  lda #$7e
  clc
  ; Should affect NVZC
  adc #$01
  capture_state
  A_should_be $7f
             ; NV1BDIZC
  P_should_be %00110100 ; Negative: NO   Overflow: NO  Carry: NO

  ; #1  Add a negative number to a positive number
  lda #6          ; Begin with +6
  clc
  adc #-4         ; Add -4
  capture_state
  A_should_be 2   ; Expect 2
             ; NV1BDIZC
  P_should_be %00110101 ; Negative: NO   Overflow: NO  Carry: yes
  ; There's a Carry because if those were unsigned values then there would have
  ; been an unsigned overlow

  ; #2  Add a positive number to a negative number
  lda #-6         ; Begin with -6
  clc
  adc #4          ; Add 4
  capture_state
  A_should_be -2  ; Expect -2
             ; NV1BDIZC
  P_should_be %10110100 ; Negative: yes  Overflow: NO  Carry: NO

  ; #3  Add a negative number to another negative number
  lda #-4
  clc
  adc #-6
  capture_state
  A_should_be -10
             ; NV1BDIZC
  P_should_be %10110101 ; Negative: yes   Overflow: NO  Carry: yes

  ; Test the overflow cases
  ; #4  Add two positive numbers where the result will not fit in 0..7f
  lda #$7f
  clc
  adc #$01
  capture_state
  A_should_be $80
             ; NV1BDIZC
  P_should_be %11110100 ; Negative: yes  Overflow: yes  Carry: NO

  ; Heh: The largest negative number, -128, that could be added will not result
  ; in signed overflow for any positive number (lowest is 0)

  ; #5  -1 + -128
  lda #-1
  clc
  adc #-128
  capture_state
  A_should_be -129
             ; NV1BDIZC
  P_should_be %01110101 ; Negative: NO  Overflow: yes  Carry: yes

  rts

@subroutine:
  capture_state
  rts

  .endif ; ref test_instruction_set


  .ifref test_add_s8_to_u16
  .export test_add_s8_to_u16
  .macro case  p_hi, p_lo, adjustment, expect_hi, expect_lo
  ldya p_hi, p_lo ; Make a pointer in ZP ready for add_s8_to_u16
  jsr zps_phya  ; zps_phya sets X to the address in ZP of the pointer
  lda #adjustment
  jsr add_s8_to_u16
  ldy $01,x     ; Load the pointer from ZP to check its value
  lda $00,x
  capture_state
  X_should_be $fe
  Y_should_be expect_hi
  A_should_be expect_lo
  jsr zps_release2
  .endmacro

test_add_s8_to_u16:

  case $00, $00, +1, $00, $01 ; #0  0000 + 1
  case $00, $01, -1, $00, $00 ; #1  0001 + -1
  case $00, $ff, +1, $01, $00 ; #2  00ff + 1 (Page overflow)
  case $01, $00, -1, $00, $ff ; #3  0100 + -1 (Page underflow)
  case $01, $7f, -128, $00, $ff ; #4  017f + -128

  rts

  .endif ; ref test_add_s8_to_u16


  .ifref test_advance_zp_ptr
  .export test_advance_zp_ptr
  .macro case  p_hi, p_lo, adjustment, expect_hi, expect_lo
  ldya p_hi, p_lo ; Make a pointer in ZP ready for add_s8_to_u16
  jsr zps_phya    ; zps_phya sets X to the address in ZP of the pointer
  lda #adjustment
  jsr advance_zp_ptr
  ldy $01,x     ; Load the pointer from ZP to check its value
  lda $00,x
  capture_state
  X_should_be $fe
  Y_should_be expect_hi
  A_should_be expect_lo
  jsr zps_release2
  .endmacro

test_advance_zp_ptr:

  case $00, $01, $80, $00, $81  ; #0  0001 + 80 = 0081
  case $00, $01, $ff, $01, $00  ; #0  0001 + ff = 0100

  rts

  .endif ; ref test_advance_zp_ptr



  .ifref test_show_A
  .export test_show_A
  .import show_A

test_show_A:
  ; Stack (and ZP stack) should not be leaked
  ; All registers (and processor state) should be preserved
  lda #0
  tax
  tay
  clc
  capture_state   ; Test:00
  A_should_be 0
  X_should_be 0
  Y_should_be 0
  ;            NV1BDIZC
  P_should_be %00110110
  SP_should_be $fb
  ZPSP_should_be $ff
  lda #0    ; Reset the state
  tax
  tay
  clc
  bit msg   ; This affects N and V indicators
  jsr show_A
  capture_state   ; Test:01
  A_should_be 0
  X_should_be 0
  Y_should_be 0
  ;            NV1BDIZC
  P_should_be %01110110
  SP_should_be $fb
  ZPSP_should_be $ff
  ; Run the test again with a different state to check that state really is
  ; being preserved not just matching what the first test expected
  lda #$ff
  tax
  tay
  sec
  capture_state   ; Test:02
  A_should_be $ff
  X_should_be $ff
  Y_should_be $ff
  ;            NV1BDIZC
  P_should_be %11110101
  SP_should_be $fb
  ZPSP_should_be $ff
  lda #$ff
  tax
  tay
  sec
  bit msg
  jsr show_A
  capture_state   ; Test:03
  A_should_be $ff
  X_should_be $ff
  Y_should_be $ff
  ;            NV1BDIZC
  P_should_be %01110101
  SP_should_be $fb
  ZPSP_should_be $ff
  rts

  .endif ; ref test_show_A



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


; Reports a failure if A is not the same as X.
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
  lda test_id
  pha
  ldx #<@FAIL
  ldy #>@FAIL
  jsr printfu

  plyxa

: rts

.data
@FAIL:
  .byt "Test:",I_HEX8,",expected:",I_HEX8,",got:",I_HEX8,$0d,$0a,0
.code


.endif

