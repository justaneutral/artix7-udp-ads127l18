#!/bin/bash

#Usage: ./udp_sender <IP> <PORT> <MESSAGE_LENGTH> <INTERVAL_NS>
#This will:
#Send 64-byte messages to 192.168.1.128:1234
#Wait 10ms between sends (10,000,000 nanoseconds)

./udp_sender.exe 192.168.1.128 1234 64 10000000

