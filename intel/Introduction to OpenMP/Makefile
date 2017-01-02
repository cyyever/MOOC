SRCS=$(wildcard *.c)
BINS=$(patsubst %.c,%,$(SRCS))
#CC=gcc-7
CC=/opt/intel/bin/icc
CFLAGS=-fopenmp -O3
#CC=clang-3.9
#CFLAGS=-fopenmp=libomp

.PHONY:all clean

all:$(BINS)
clean:
	-$(RM) $(BINS) *.o *~ 
