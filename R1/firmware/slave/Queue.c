
#include "Queue.h"

#include <stdio.h>


#define  next_Queue_index( i )  ( (i + 1) & QUEUE_MASK )


void  init_queue( Queue *q )
{
  q->head = 0;
  q->tail = 0;
  q->max_length = 0;
  q->overflowed = false;
}


uint8_t  queue_capacity( Queue *q )
{
  return sizeof( q-> data ) - 1;
}


// Do not enqueue if queue_length == queue_capacity.
//
uint8_t  queue_length( Queue *q )
{
  return ( sizeof(q->data) + q->head - q->tail ) & QUEUE_MASK;
}


void  enqueue( Queue *q, uint8_t data )
{
  // if the queue is full then warn and new data overwrites old
  uint8_t  next_head = next_Queue_index( q->head );
  // If an item is enqueued when the queue is already full then the queue would
  // appear empty and all items on the queue would be lost
  if ( next_head == q->tail )
  {
    q->overflowed = true;
  }
  else {
    q->data[ q->head] = data;
    q->head = next_Queue_index( q->head );

    if ( q->max_length < queue_length(q) )
      q->max_length = queue_length(q);
  }
}


uint8_t  dequeue( Queue *q )
{
  // If the buffer is empty 0xff should be returned although this should never
  // happen becuase an invocation of dequeue should always be preceded by a
  // queue_length() check
  q->overflowed = false;
  if ( q->tail == q->head )
  {
    return 0xff;
  }
  else {
    uint8_t  old_tail = q->tail;
    q->tail = next_Queue_index( q->tail );
    return q->data[ old_tail];
  }
}

