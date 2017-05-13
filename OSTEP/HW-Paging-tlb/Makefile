SRCS=$(wildcard *.c)
BINS=$(patsubst %.c,%,$(SRCS))
CC=clang -std=c11
CFLAGS=-O0 -Wall -Wextra -Werror -ferror-limit=1
.PHONY:all test clean install
all:$(BINS)
clean:
	-$(RM) $(BINS) *.o *~ 
