#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <termios.h>

int
console_width () {
  struct winsize ws;

  if (ioctl(0, TIOCGWINSZ, &ws) == -1 )
    return 80;
  else
    return (int) ws.ws_col;
}

unsigned char *expand_string (const unsigned char *message, int length) {
  unsigned char *temp = malloc (length + 1);
  memset (temp, message[0], length);
  temp[length] = 0x00;
  return temp;
}
