CC = gcc
CFLAGS = -Wall -O2
TARGET = udp_sender

all: $(TARGET)

$(TARGET): udp_sender.c
	$(CC) $(CFLAGS) -o $(TARGET) udp_sender.c

clean:
	rm -f $(TARGET)

