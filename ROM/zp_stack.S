
; A data stack in Zero Page.
;
; The stack pointer might be kept at $0002, initialized to $ff and works in the
; same way as the hardware stack:
;
;   1) Write
;   2) Decrement
;
; It should not be used within interrupt handlers because the above is not
; atomic.
;
; Compared to the hardware stack both performance and code density suffer
; although it does allow efficient and even re-entrant use of ZP scratch space.
;
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

.export zps_init
.export zps_alloc
.export zps_alloc2
.export zps_pha
.export zps_phya
.export zps_release
.export zps_release2

.include "globals.S"


; Initializes the Zero Page Stack.
;
; @return  X  The newly adjusted Zero-Page Stack Pointer, which begins as $ff
;             ( referring to ZP address $00ff) and points not to the data most
;             recently pushed but to the slot that will be used *next*
;
zps_init:
  ldx #$ff
  stx zp_sp
  rts


zps_alloc2:
  dec zp_sp
  ; Fall through


zps_alloc:
  dec zp_sp
  rts


; @return     X     The address in ZP of the data just pushed
;
zps_pha:
  ldx zp_sp ; 2 3
  sta $00,x
  dec zp_sp ; 2 5
  rts


; Pushes a 16-bit pointer to the stack.
;
; @param      A     LO byte of the pointer
; @param      Y     HI byte of the pointer
; @return     X     The address in ZP of the LSB just pushed
; @destroys   None
;
zps_phya:

  ;ldx zp_sp ; 2  3
  ;dex       ; 1  2
  ;dex       ; 1  2
  ;stx zp_sp ; 2  3
  ;inx       ; 1  2
  ;          ; 7 12

  ;ldx zp_sp ; 2  3
  ;dex       ; 1  2
  ;stx zp_sp ; 2  3
  ;dec zp_zp ; 2  5
  ;            7 13

  ;dec zp_sp ; 2  5
  ;ldx zp_sp ; 2  3
  ;dec zp_sp ; 2  5
  ;          ; 6 13

  ;sta $00,x
  ;sty $01,x
  ;rts

  ldx zp_sp ; 2 3
  sty $00,x
  dec zp_sp ; 2 5
  bra zps_pha


; Releases two bytes from the top of the stack.
;
; @destroys   None
;
zps_release2:

  inc zp_sp
  ; Falls through to zps_release


; Releases a byte from the top of the stack.
;
; @destroys   None
;
zps_release:
  inc zp_sp
  rts

