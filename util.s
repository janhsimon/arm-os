.global delay


delay: // x0: number of cycles to delay for
  cbz  x0, delay_break // break if we have no more cycles to delay
  nop                  // wait a cycle
  sub  x0, x0, 1       // decrement counter
  b delay

delay_break:
  ret
