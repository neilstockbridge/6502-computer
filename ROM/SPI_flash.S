;
; Support for W25X40CL SPI flash memory.
;
; The chip has features (such as 64K block erase) elided here for brevity.
;

.export power_up_SPI_flash
.export read_SPI_flash_unique_identifier
.export read_SPI_flash_page
.export erase_4K_of_SPI_flash
.export write_SPI_flash_page

; Not really part of the API but exported so they appear in the label file for
; disassembly:
.export small_request
.export query_status
.export wait_while_busy
.export wait_until_ready_for_write
.export begin_request
.export send_address_within_flash

.import SPI_select
.import SPI_exchange
.import SPI_release
.import write_to_stream



; Code common to a few places.
;
; @param    A   The request type ("INSTRUCTION NAME" from the data sheet)
; @param    C   Set: "Pump" the device once (for querying status)  Clear: No
;               pumping
; @return   A   The response from the flash (if C was set)
;
small_request:
  pha               ; Preserve A across SPI_select
  jsr SPI_select
  pla
  jsr SPI_exchange
  bcc jmp_SPI_release
  lda #$ff          ; pump
  jsr SPI_exchange
  pha               ; Preserve A across SPI_release
  jsr SPI_release
  pla
  rts



; @return   A   The Status Register.  Bit0 is BUSY (Should be 0 before making a
;               request), Bit1 is WEL (Should be 1 before making erase or
;               program requests)
;
query_status:
  lda #$05          ; 05h: Read Status Register
  sec               ; Yes please, pump once to read the status
  jmp small_request



; @destroys   A
;
wait_while_busy:
: jsr query_status
  bit #$01
  ; TODO: This can hang the CPU, so consider a time out (and exception)
  bne :-  ; Loop while BUSY is 1
  rts



; @destroys   A
;
wait_until_ready_for_write:
: jsr query_status
  bit #$02
  beq :-  ; Loop while WEL is 0
  rts



; Must be invoked at least once after power-up.  No problem if invoked again.
;
; @destroys  A
;
power_up_SPI_flash:
  lda #$ab          ; ABh: Release Power Down / Device ID
  clc
  jmp small_request
  ; /CS must remain high for 3 us



; Provides a 64-bit identifier unique to the flash chip.
;
; @param      X   The address in ZP of a pointer to a buffer that will receive
;                 the unique identifier (8 bytes)
; @destroys   AXY
;
read_SPI_flash_unique_identifier:

  lda #$4b            ; 4Bh: Read Unique ID
  clc
  jsr begin_request

  ldy #4
: lda #$ff  ; It probably doesn't matter what data is sent but use a
            ; non-existent request code just to be safe
  jsr SPI_exchange
  dey
  bne :-

  ldy #8
: lda #$ff
  jsr SPI_exchange
  jsr write_to_stream
  dey
  bne :-

jmp_SPI_release:    ; `small_request` branches here
  jmp SPI_release   ; Use the `rts` in SPI_release



; Code common to a few requests.
;
; @param      A   The request type ("INSTRUCTION NAME" from the data sheet)
; @param      C   Set: Enable for write prior to command  Clear: No Write
;                 Enable
; @destroys   A
;
begin_request:
  pha                 ; Preserve A for later on
  php                 ; Preserve C across `wait_while_busy`
  jsr wait_while_busy
  plp
  bcc :+              ; Only enable for writing if carry is set
  lda #$06            ; 06h: Write Enable
  clc
  jsr small_request
  jsr wait_until_ready_for_write
: jsr SPI_select
  pla                 ; Recall A as the parameter passed
  jmp SPI_exchange    ; Use the `rts` in SPI_exchange



; Sends the 24-bit (byte-aligned) address within flash memory for read, erase
; and write operations.
;
; @param      A   LO byte, and:
; @param      Y   HI byte.  The (byte-aligned) address within the flash from
;                 which reading will begin is `Y << 16 | A << 8`
; @return     Y   Set to zero, used by loops in read and write
; @destroys   A
;
send_address_within_flash:

  pha               ; Preserve A for later

  tya               ; A is now HI byte of requested flash address
  jsr SPI_exchange  ; A23-16

  pla               ; A is now LO byte of requested flash address
  jsr SPI_exchange  ; A15-8

  lda #$00          ; A7-0
  tay               ; ..so Y is zero ready for the loop
  jmp SPI_exchange  ; Use the `rts` in SPI_exchange



; Reads 256 bytes from the SPI flash to memory.
;
; Self-modifying!  Not thread-safe.
;
; @param      A   LO byte, and:
; @param      Y   HI byte.  The (byte-aligned) address within the flash from
;                 which reading will begin is `Y << 16 | A << 8`
; @param      X   The address in ZP of a pointer to a buffer that will receive
;                 the bytes as they are read
; @destroys   AY
;
read_SPI_flash_page:

  pha               ; Remember for later

  lda #$03          ; 03h: Read Data
  clc
  jsr begin_request

  pla               ; Recall the value of A as given when invoked
  jsr send_address_within_flash

  stx @indirect_store + 1 ; Self-modifying code
: lda #$ff
  jsr SPI_exchange
  ;jsr write_to_stream  ; Modifies pointer
@indirect_store:
  sta ($ff),y           ; TODO: Check that this crosses page boundaries OK
  iny
  bne :-

  jmp SPI_release ; Use the `rts` in SPI_release



; Erases a 4K block of flash.  Blocks must be erased before programming unless
; no bits currently 0 are required to be 1.
;
; @param      A   LO byte, and:
; @param      Y   HI byte.  The (byte-aligned) address within the flash at
;                 which erasing will begin is `Y << 16 | (A & 0xf0) << 8`
; @destroys   AY
;
erase_4K_of_SPI_flash:

  pha               ; Remember for later

  lda #$20          ; 20h: Sector erase (4K)
  sec               ; Yes, please: Enable for writing
  jsr begin_request

  pla               ; Recall the value of A as given when invoked
  jsr send_address_within_flash

  jmp SPI_release   ; Use the `rts` in SPI_release



; Writes 256 bytes from memory to the the SPI flash.
;
; Self-modifying!  Not thread-safe.
;
; @param      A   LO byte, and:
; @param      Y   HI byte.  The (byte-aligned) address within the flash at
;                 which writing will begin is `Y << 16 | A << 8`
; @param      X   The address in ZP of a pointer to a buffer that contains the
;                 bytes to be written.  The pointer is modified as the bytes
;                 are written
; @destroys   AY
;
write_SPI_flash_page:

  pha               ; Remember LO byte of requested flash address for later

  lda #$02          ; 02h: Page Program
  sec               ; Yes, please: Enable for writing
  jsr begin_request

  pla               ; Recall the value of A as given when invoked
  jsr send_address_within_flash

  ;jsr read_from_stream  ; Modifies pointer
  stx @indirect_load + 1 ; Self-modifying code
@indirect_load:
: lda ($ff),y
  jsr SPI_exchange
  iny
  bne :-

  jmp SPI_release ; Use the `rts` in SPI_release

