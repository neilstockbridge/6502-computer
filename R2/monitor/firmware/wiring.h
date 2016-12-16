/*

ATmega164PA
          ____ ____
    PB0 [|  1 U 40 |] PA0
    PB1 [|  2   39 |] PA1
    PB2 [|  3   38 |] PA2
    PB3 [|  4   37 |] PA3
    PB4 [|  5   36 |] PA4
    PB5 [|  6   35 |] PA5
    PB6 [|  7   34 |] PA6
    PB7 [|  8   33 |] PA7
 /RESET [|  9   32 |] AREF
    VCC [| 10   31 |] GND
    GND [| 11   30 |] AVCC
  XTAL2 [| 12   29 |] PC7
  XTAL1 [| 13   28 |] PC6
    PD0 [| 14   27 |] PC5
    PD1 [| 15   26 |] PC4
    PD2 [| 16   25 |] PC3
    PD3 [| 17   24 |] PC2
    PD4 [| 18   23 |] PC1
    PD5 [| 19   22 |] PC0
    PD6 [|_20___21_|] PD7
*/

#define  A0    PB0
#define  A1    PB1
#define  A2    PB2
#define  A3    PB3
#define  A4    PB4
#define  A5    PB5
#define  A6    PB6
#define  A7    PB7
#define  A8    PA0
#define  A9    PA1
#define  A10   PA2
#define  A11   PA3
#define  A12   PA4
#define  A13   PA5
#define  A14   PA6
#define  A15   PA7
#define  D0    PC0
#define  D1    PC1
#define  D2    PC2
#define  D3    PC3
#define  D4    PC4
#define  D5    PC5
#define  D6    PC6
#define  D7    PC7
#define  RX    PD0
#define  TX    PD1
#define  RESB  PD2
#define  RWB   PD3
#define  STOP  PD4
#define  GO    PD5
#define  BE    PD6
#define  PHI2  PD7


// When writing PORTx or reading PINx registers:
#define  LOW    0
#define  HIGH   1
// When changing DDRx registers:
#define  INPUT  0
#define  OUTPUT 1
#define  ALL_INPUTS  0x00
#define  ALL_OUTPUTS  0xff
#define  ALL_PULL_UPS  0xff

#define  sense_pin( pin)          (DDRD &= ~ _BV (pin))
#define  drive_pin( pin)          (DDRD |= _BV (pin))
#define  level_at( port, pin)     ((port & _BV (pin)) ? HIGH : LOW)
#define  drive_low( port, pin)    (port &= ~_BV (pin))
#define  drive_high( port, pin)   (port |= _BV (pin))
#define  toggle( port, pin)       (port ^= _BV (pin))

#define  disconnect_6502_from_bus()  drive_low (PORTD, STOP); drive_low (PORTD, BE)
#define  reconnect_6502_to_bus()  drive_high (PORTD, BE); drive_high (PORTD, STOP)

// Meaning of the RWB line:
#define  WRITE  0
#define  READ   1
#define  RWB_read()   drive_high (PORTD, RWB)
#define  RWB_write()  drive_low (PORTD, RWB)
#define  drive_RWB()  drive_pin (RWB)
#define  release_RWB()  sense_pin (RWB)

// Configure the data bus pins as OUTPUTs only *after* the data has been loaded
// in to the PORT to prevent them changing value momentarily
#define  drive_data_bus( data)  PORTC = data;  DDRC = ALL_OUTPUTS
// Configure all data bus pins as INPUT ( High-Z )
// Enable pull-ups rather than only for pins where data was last driven 1
#define  release_data_bus()     DDRC = ALL_INPUTS;  PORTC = ALL_PULL_UPS
#define  value_on_data_bus()    PINC

#define  drive_address_bus( address)  PORTA = ((address) >> 8);  PORTB = ((address) & 0xff);  DDRA = ALL_OUTPUTS;  DDRB = ALL_OUTPUTS
#define  release_address_bus()  DDRA = ALL_INPUTS;  DDRB = ALL_INPUTS;  PORTA = ALL_PULL_UPS;  PORTB = ALL_PULL_UPS

// For testing while the Monitor AVR controls PHI2 via GO:
#define  drive_PHI2_high()  drive_high (PORTD, GO)
#define  drive_PHI2_low()  drive_low (PORTD, GO)

#define  drive_RESB_low()   drive_pin (RESB)
#define  release_RESB()     sense_pin (RESB)

