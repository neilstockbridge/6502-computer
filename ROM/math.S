
.export add_u8_to_u16
.export add_s8_to_u16


; Adds an unsigned 8-bit value to an unsigned 16-bit value stored in ZP.
;
; @param      X   The address in ZP of the 16-bit value
; @param      A   The amount to add to the 16-bit value
; @destroys   A
;
add_u8_to_u16:
  clc
  adc $00,x
  sta $00,x
  bcc :+
  inc $01,x
: rts


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

