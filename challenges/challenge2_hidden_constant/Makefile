CC      = gcc
CFLAGS  = -O1 -Wall
TARGET  = challenge_stripped
DEBUG   = challenge_debug

.PHONY: all clean

all: $(TARGET) $(DEBUG)

$(DEBUG): challenge.c
	$(CC) $(CFLAGS) -g -o $@ $<

$(TARGET): challenge.c
	$(CC) $(CFLAGS) -o $@ $<
	strip $@

clean:
	rm -f $(TARGET) $(DEBUG)
