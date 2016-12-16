
#include "SPI.h"

#include <avr/interrupt.h>


void static  reset_counter ()
{
  USISR = (1 << USISIF)  // Acknowledge the Start Condition indicator
        | (1 << USIOIF)  // Acknowledge the Counter Overflow indicator
        | (1 << USIPF)   // Acknowledge the Stop Condition indicator
        | (1 << USIDC)   // Acknowledge the Data Output Collision indicator
        | (0 << USICNT0) // Start the USI counter from zero
        ;
}


// Configures all of USICR but in particular such that SCLK is ignored,
// otherwise the whole SPI subsystem receives bytes intended for other devices
// because USI has no concept of this device being selected or not.  It's
// tempting to try using USIOIE for this purpose but hard-to-trace bugs could
// occur if USIOIF is set as a result of an exchange between other devices and
// this causes an interrupt as soon as this device were selected.
//
void static inline  disable_reception ()
{
  USICR = (0 << USISIE)  // DISABLE the START condition interrupt
        | (1 << USIOIE)  // ENABLE the USI counter overflow interrupt.  Not until selected otherwise USI will process exchanges intended for other devices
        | (1 << USIWM0)  // Wire Mode 1 indicates SPI
        | (0 << USICS0)  // Clock Source 2 and USICLK=0 indicates sampling on a RISING SCLK
        | (0 << USICLK)
        | (0 << USITC)   // Don't toggle SCLK.  This is not the Master
        ;
}


void static inline  enable_reception ()
{
  USICR = (0 << USISIE)  // DISABLE the START condition interrupt
        | (1 << USIOIE)  // ENABLE the USI counter overflow interrupt.  Not until selected otherwise USI will process exchanges intended for other devices
        | (1 << USIWM0)  // Wire Mode 1 indicates SPI
        | (2 << USICS0)  // Clock Source 2 and USICLK=0 indicates sampling on a RISING SCLK
        | (0 << USICLK)
        | (0 << USITC)   // Don't toggle SCLK.  This is not the Master
        ;
}


// This does *not* set the DDR.  PB4 must be input with pull-up.
//
void  init_SPI ()
{
  reset_counter ();

  disable_reception ();

  // The Slave Select pin should interrupt the MCU
  GIMSK = (0 << INT1)
        | (0 << INT0)
        | (1 << PCIE) // Pin-change interrupts should be enabled
        ;
  PCMSK = (0 << PCINT7)
        | (0 << PCINT6)
        | (0 << PCINT5)
        | (1 << PCINT4) // PB4
        | (0 << PCINT3)
        | (0 << PCINT2)
        | (0 << PCINT1)
        | (0 << PCINT0)
        ;
  USIDR = 0x00; // To indicate to the master that no bytes are available here yet
}


// This will happen both when /SS is pulled low *and* when it is released.
//
ISR (PCINT_vect)
{
  // If this device is selected then MISO should be driven by this device
  // otherwise it should be allowed to float ( externally pulled up weakly so
  // that this code doesn't have to fuss with enabling the pull-up each time
  // the driver is disabled)
  if (LOW == level_at (SSA_PORT, SSA))
  {
    SPI_slave_select_asserted ();
    enable_reception ();
  }
  else {
    disable_reception ();
  }
  reset_counter ();
}


bool volatile  USIDR_hot = false; // Indicates that USIDR has been loaded with valid data to send by send_byte_via_SPI()


// When the USI counter overflows..
ISR (USI_OVERFLOW_vect)
{
  // 8 bits have been received via SPI
  byte_received_via_SPI (USIDR);
  USIDR = 0x00; // To indicate no bytes
  USIDR_hot = false;
  USISR |= _BV (USIOIF);
}


bool  SPI_is_ready_to_send ()
{
  return ! USIDR_hot;
}


// NOTE: Do not invoke unless ready_to_send_via_SPI() returns true otherwise
// USIDR will be changed mid-exchange and corruption will result.
//
void  send_byte_via_SPI (uint8_t data)
{
  while (USIDR_hot);
  USIDR = data;
  USIDR_hot = true; // Block any attempt to set USIDR again until the data currently in USIDR has been sent.  USIDR is a single-byte buffer
}

