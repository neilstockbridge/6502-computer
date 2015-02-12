
#ifndef __QUEUE_H
#define __QUEUE_H


#include <stdbool.h>
#include <stdint.h>


// This must be an integer power of 2
#define  QUEUE_BUFFER_SIZE  ( 1 << 4 )

#define  QUEUE_MASK         ( (QUEUE_BUFFER_SIZE) - 1 )

typedef struct
{
  uint8_t  head; // refers to the empty slot for the next item
  uint8_t  tail; // refers to the slot with the oldest data.  when == head, the queue is empty
  uint8_t  data[ QUEUE_BUFFER_SIZE]; //
  bool     overflowed;
  uint8_t  max_length;
}
Queue;


extern
void  init_queue( Queue *q )
;

extern
uint8_t  queue_capacity( Queue *q )
;

extern
uint8_t  queue_length( Queue *q )
;

extern
void  enqueue( Queue *q, uint8_t data )
;

extern
uint8_t  dequeue( Queue *q )
;


#endif

