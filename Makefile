PREFIX ?= /usr
SHAREDIR ?= $(PREFIX)/share/quickshell/atg
INSTALLDIR = $(DESTDIR)$(SHAREDIR)

CFLAGS ?= -O2 -Wall -Wextra

.PHONY: all install uninstall clean

all: atg-ewmh

atg-ewmh: atg-ewmh.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< -lX11

install: atg-ewmh
	install -d "$(INSTALLDIR)" "$(INSTALLDIR)/assets" "$(INSTALLDIR)/backdrop" \
		"$(INSTALLDIR)/monitor" "$(INSTALLDIR)/theme"
	install -m 755 atg-ewmh "$(INSTALLDIR)/"
	install -m 644 *.qml osd-backend.sh wallpaper-backend.sh README.md LICENSE "$(INSTALLDIR)/"
	install -m 644 assets/ATG.png "$(INSTALLDIR)/assets/"
	install -m 644 backdrop/d77-logo.svg backdrop/render.py "$(INSTALLDIR)/backdrop/"
	install -m 755 monitor/d77-monitor "$(INSTALLDIR)/monitor/"
	install -m 644 monitor/eww.yuck monitor/eww.scss "$(INSTALLDIR)/monitor/"
	install -m 644 theme/Colors.qml theme/qmldir theme/d77-palette.json theme/matugen.toml \
		"$(INSTALLDIR)/theme/"

uninstall:
	rm -rf -- "$(INSTALLDIR)"

clean:
	rm -f -- atg-ewmh
