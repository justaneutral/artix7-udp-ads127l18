#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>

#define MAX_MSG_LEN 65507  // Max UDP payload (practical limit)

static void random_fill(unsigned char *buf, size_t len) {
    for (size_t i = 0; i < len; ++i) {
        buf[i] = (unsigned char)('A' + rand() % 26);
    }
}

static void print_char_line(const unsigned char *buf, size_t len) {
    for (size_t i = 0; i < len; ++i) {
        unsigned char c = buf[i];
        putchar(isprint(c) ? c : '.');
    }
    putchar('\n');
}

static void print_hex_line(const unsigned char *buf, size_t len) {
    for (size_t i = 0; i < len; ++i) {
        printf("%02X", buf[i]);
        if (i + 1 < len) putchar(' ');
    }
    putchar('\n');
}

int main(int argc, char *argv[]) {
    if (argc != 5 && argc != 6) {
        fprintf(stderr,
                "Usage:\n"
                "  %s <IP> <PORT> <MESSAGE_LENGTH> <INTERVAL_NS> [<MESSAGE>]\n"
                "Notes:\n"
                "  - If MESSAGE is provided (quoted if it has spaces), its length overrides MESSAGE_LENGTH.\n",
                argv[0]);
        return EXIT_FAILURE;
    }

    const char *ip_str = argv[1];
    int port = atoi(argv[2]);
    long interval_ns = atol(argv[4]);

    int msg_len = atoi(argv[3]);
    int have_message = (argc == 6);
    const unsigned char *message_arg = NULL;

    if (have_message) {
        message_arg = (const unsigned char *)argv[5];
        msg_len = (int)strlen((const char *)message_arg);
    }

    if (msg_len <= 0 || msg_len > MAX_MSG_LEN) {
        fprintf(stderr, "Invalid message length (1-%d). Got %d\n", MAX_MSG_LEN, msg_len);
        return EXIT_FAILURE;
    }

    // Prepare send buffer
    unsigned char *msg = (unsigned char *)malloc((size_t)msg_len);
    if (!msg) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    // If message provided, copy; otherwise fill randomly each send
    if (have_message) {
        if (msg_len > MAX_MSG_LEN) {
            fprintf(stderr, "Message too long; truncating to %d bytes\n", MAX_MSG_LEN);
            msg_len = MAX_MSG_LEN;
        }
        memcpy(msg, message_arg, (size_t)msg_len);
    }

    // Create UDP socket
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket");
        free(msg);
        return EXIT_FAILURE;
    }

    // Non-blocking socket
    if (fcntl(sock, F_SETFL, O_NONBLOCK) == -1) {
        perror("fcntl");
        // Not fatal, but warn:
        fprintf(stderr, "Warning: failed to set O_NONBLOCK; receives may block.\n");
    }

    struct sockaddr_in target;
    memset(&target, 0, sizeof(target));
    target.sin_family = AF_INET;
    target.sin_port = htons((uint16_t)port);
    if (inet_pton(AF_INET, ip_str, &target.sin_addr) != 1) {
        fprintf(stderr, "Invalid IP address: %s\n", ip_str);
        close(sock);
        free(msg);
        return EXIT_FAILURE;
    }

    // Sleep interval
    struct timespec interval = {
        .tv_sec = interval_ns / 1000000000L,
        .tv_nsec = interval_ns % 1000000000L
    };

    // Seed RNG for random messages if needed
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    srand((unsigned int)(ts.tv_nsec ^ ts.tv_sec));

    // Stats
    unsigned long long total_sent_bytes = 0;
    unsigned long long total_received_bytes = 0;

    struct timespec last_print, now;
    clock_gettime(CLOCK_MONOTONIC, &last_print);

    // Receive buffer
    unsigned char rbuf[MAX_MSG_LEN];

    while (1) {
        if (!have_message) {
            random_fill(msg, (size_t)msg_len);
        }

        ssize_t s = sendto(sock, msg, (size_t)msg_len, 0,
                           (struct sockaddr *)&target, sizeof(target));
        if (s > 0) {
            total_sent_bytes += (unsigned long long)s;
        } else if (s < 0 && errno != EWOULDBLOCK && errno != EAGAIN) {
            perror("sendto");
        }

        // Non-blocking receive loop
        for (;;) {
            ssize_t r = recv(sock, rbuf, sizeof(rbuf), 0);
            if (r > 0) {
                total_received_bytes += (unsigned long long)r;
                if (have_message) {
                    // Print dumps for each received datagram
                    printf("[RECV %zd bytes] chars: ", r);
                    print_char_line(rbuf, (size_t)r);
                    printf("[RECV %zd bytes]  hex : ", r);
                    print_hex_line(rbuf, (size_t)r);
                }
                // Try to drain socket
                continue;
            } else if (r == -1 && (errno == EWOULDBLOCK || errno == EAGAIN)) {
                break; // no more data
            } else if (r == -1) {
                perror("recv");
                break;
            } else { // r == 0 (UDP "connectionless": 0 typically shouldn't happen)
                break;
            }
        }

        // Print stats every second
        clock_gettime(CLOCK_MONOTONIC, &now);
        if ((now.tv_sec - last_print.tv_sec) >= 1) {
            printf("Total sent bytes: %llu, Total received bytes: %llu\n",
                   (unsigned long long)total_sent_bytes,
                   (unsigned long long)total_received_bytes);
            fflush(stdout);
            last_print = now;
        }

        nanosleep(&interval, NULL);
    }

    // Unreachable in current loop, but for completeness:
    close(sock);
    free(msg);
    return 0;
}

