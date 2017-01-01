SRCS=$(wildcard *.c)
BINS=$(patsubst %.c,%,$(SRCS))
CFLAGS=-fopenmp

.PHONY:all clean

all:$(BINS)
clean:
	-$(RM) $(BINS) *.o *~ 
