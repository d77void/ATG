#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned long read_cardinal(Display *display, Window root, Atom property,
                                   unsigned long fallback)
{
    Atom type;
    int format;
    unsigned long count, remaining;
    unsigned char *value = NULL;
    if (XGetWindowProperty(display, root, property, 0, 1, False, XA_CARDINAL,
                           &type, &format, &count, &remaining, &value) == Success &&
        type == XA_CARDINAL && format == 32 && count == 1) {
        fallback = *(unsigned long *)value;
    }
    if (value)
        XFree(value);
    return fallback;
}

static void write_names(Display *display, Window root, Atom property, Atom utf8)
{
    XTextProperty names;
    putchar('[');
    if (XGetTextProperty(display, root, &names, property)) {
        if (names.nitems && names.format == 8 &&
            (names.encoding == utf8 || names.encoding == XA_STRING)) {
            const unsigned char *name = names.value;
            const unsigned char *end = name + names.nitems;
            while (name < end) {
                if (name != names.value)
                    putchar(',');
                putchar('"');
                while (name < end && *name) {
                    unsigned char byte = *name++;
                    if (byte == '"' || byte == '\\')
                        putchar('\\');
                    if (byte < 0x20 || (byte >= 0x80 && names.encoding == XA_STRING))
                        printf("\\u%04x", (unsigned int)byte);
                    else
                        putchar(byte);
                }
                putchar('"');
                if (name < end)
                    ++name;
            }
        }
        XFree(names.value);
    }
    putchar(']');
}

static void watch_desktops(Display *display, Window root, Atom current)
{
    Atom count = XInternAtom(display, "_NET_NUMBER_OF_DESKTOPS", False);
    Atom names = XInternAtom(display, "_NET_DESKTOP_NAMES", False);
    Atom utf8 = XInternAtom(display, "UTF8_STRING", False);
    XSelectInput(display, root, PropertyChangeMask);

    for (;;) {
        printf("{\"count\":%lu,\"current\":%lu,\"names\":",
               read_cardinal(display, root, count, 0),
               read_cardinal(display, root, current, UINT32_MAX));
        write_names(display, root, names, utf8);
        puts("}");
        if (fflush(stdout) == EOF)
            return;

        XEvent event;
        do {
            XNextEvent(display, &event);
        } while (event.type != PropertyNotify ||
                 (event.xproperty.atom != current && event.xproperty.atom != count &&
                  event.xproperty.atom != names));
    }
}

static int select_desktop(Display *display, Window root, Atom current,
                          unsigned long desktop)
{
    XEvent event = {0};
    event.xclient.type = ClientMessage;
    event.xclient.window = root;
    event.xclient.message_type = current;
    event.xclient.format = 32;
    event.xclient.data.l[0] = desktop;
    event.xclient.data.l[1] = CurrentTime;
    int sent = XSendEvent(display, root, False,
                         SubstructureNotifyMask | SubstructureRedirectMask, &event);
    return sent ? EXIT_SUCCESS : EXIT_FAILURE;
}

int main(int argc, char **argv)
{
    int watch = argc == 2 && strcmp(argv[1], "watch") == 0;
    if (!watch && (argc != 3 || strcmp(argv[1], "select") != 0)) {
        fputs("Usage: atg-ewmh watch | select INDEX\n", stderr);
        return EXIT_FAILURE;
    }

    unsigned long desktop = 0;
    if (!watch) {
        char *end;
        errno = 0;
        desktop = strtoul(argv[2], &end, 10);
        if (argv[2][0] < '0' || argv[2][0] > '9' || *end || errno ||
            desktop >= UINT32_MAX) {
            fputs("atg-ewmh: invalid desktop index\n", stderr);
            return EXIT_FAILURE;
        }
    }

    Display *display = XOpenDisplay(NULL);
    if (!display) {
        fputs("atg-ewmh: could not open the X display\n", stderr);
        return EXIT_FAILURE;
    }

    Window root = DefaultRootWindow(display);
    Atom current = XInternAtom(display, "_NET_CURRENT_DESKTOP", False);
    int status = EXIT_SUCCESS;
    if (watch)
        watch_desktops(display, root, current);
    else
        status = select_desktop(display, root, current, desktop);

    XCloseDisplay(display);
    return status;
}
