.global delay


delay: // x0: number of cycles to delay for
  cbz  x0, delay.done // break if we have no more cycles to delay
  nop                 // wait a cycle
  sub  x0, x0, 1      // decrement counter
  b delay

delay.done:
  ret
