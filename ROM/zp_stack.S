
; A data stack in Zero Page.
;
; The stack pointer might be kept at $0002, initialized to $ff and works in the
; same way the hardware stack:
;
;   1) Write
;   2) Decrement
;
; It should not be used within interrupt handlers because the above is not
; atomic.
;
; Compared to the hardware stack both performance and code density suffer
; although it does allow efficient and even re-entrant use of ZP scratch space.

.include "zero-page.inc"

.export zps_init, zps_phay, zps_release2

; @return  X  The newly adjusted Zero-Page Stack Pointer, which begins as $ff
;             ( referring to ZP address $00ff) and points not to the data most
;             recently pushed but to the slot that will be used *next*
;
zps_init:
  ldx #$ff
  stx zp_sp
  rts


; There are multiple options for accessing the stack
;
;   - Unrolled for performance:
;       ldx zp_sp
;       sta ($00,x)
;       dex
;       sty ($00,x)
;       dex
;       stx zp_sp
;
;   - With tailored subroutines:
;       jsr zps_alloc2  ; Allocates 2 bytes.  Better than a register parameter ( for 1,2,4)
;       sta ($01,x)     ; Frame Pointer relative addresses
;       sty ($02,x)
;
;   - For maximum code density ( the default):
;       jsr zps_pha
;       jsr zps_phy
;

; @return  X  The newly adjusted Zero-Page Stack Pointer
;
zps_pha:
  phx
  dec zp_sp
  ldx zp_sp
  sta $01,x
  plx
  rts


; Pushes a 16-bit pointer to the stack.
; @param  A   LO
; @param  Y   HI
;
zps_phay:
  phx

  ;dec zp_zp ; 2  5
  ;dec zp_zp ; 2  5
  ;ldx zp_sp ; 2  3
             ; 6 13

  ldx zp_sp ; 2  3
  dex       ; 1  2
  dex       ; 1  2
  stx zp_sp ; 2  3
            ; 6 10

  sta $01,x
  sty $02,x

  plx
  rts


zps_release2:

  inc zp_sp
  ; Falls through to zps_release

zps_release:
  inc zp_sp
  rts

