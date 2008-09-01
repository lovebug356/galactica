/*
 * Copyright (C) 2008
 *       pancake <@youterm.com>
 *
 * radare is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * radare is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with radare; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include <stdarg.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/socket.h>

void cons_set_raw(int b);

int
read_key () {
  int key = 0;
  cons_set_raw(1);
  read(0, &key, 1);
  cons_set_raw(0);
  return key;
}

static struct termios tio_old, tio_new;
static int termios_init = 0;

void cons_set_raw(int b)
{
  if (b) {
    if (termios_init == 0) {
      tcgetattr(0, &tio_old);
      memcpy (&tio_new,&tio_old,sizeof(struct termios));
      tio_new.c_iflag &= ~(BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
      tio_new.c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
      tio_new.c_cflag &= ~(CSIZE|PARENB);
      tio_new.c_cflag |= CS8;
      tio_new.c_cc[VMIN]=1; // Solaris stuff hehe
      termios_init = 1;
    }
    tcsetattr(0, TCSANOW, &tio_new);
  } else
    tcsetattr(0, TCSANOW, &tio_old);
  fflush(0);
}
