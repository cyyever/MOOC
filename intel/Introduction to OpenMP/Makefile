BINS=hello_world linked linked_task mandel pi pi_mc pi_reduction pi_sync prod_cons
CC=gcc-7
CFLAGS=-fopenmp -O3 
#CC=clang-5.0
#CFLAGS=-fopenmp=libomp -O3
CFLAGS+=-fsanitize=thread -g

.PHONY:all clean

all:$(BINS)
pi_mc:pi_mc.c random.c

clean:
	-$(RM) $(BINS) *.o *~ 
