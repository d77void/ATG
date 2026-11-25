CFLAGS ?= -O2 -Wall -Wextra

atg-ewmh: atg-ewmh.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< -lX11
