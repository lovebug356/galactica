#include <stdarg.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/socket.h>

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
