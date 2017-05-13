#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
        #include <sys/time.h>

int main(int argc,char **argv)
{
  if(argc!=3) {
    printf("Usage: %s [page number] [trial number]\n",argv[0]);
    return -1;
  }
  int page_number=atoi(argv[1]);
  int trial_number=atoi(argv[2]);

  long page_size=sysconf(_SC_PAGESIZE);
  if(page_size<=0) {
    printf("invalid page size %ld\n",page_size);
    return -1;
  }

  size_t array_size=page_size*page_number;
  int *a=malloc(array_size);
  if(!a) {
    printf("malloc failed");
    return -1;
  }

  size_t  jump = page_size/ sizeof(int);
  // 执行demand zeroing
  for (size_t i = 0; i < (size_t)page_number*jump; i += jump) {
    a[i] += 1;
  }

  struct timeval start,end;

  if(gettimeofday(&start,NULL)!=0) {
    printf("gettimeofday failed");
    return -1;
  }

  for(size_t j=0;j<(size_t)trial_number;j++) {
    for (size_t i = 0; i < (size_t)page_number*jump; i += jump) {
      a[i] += 1;
    }
  }

  if(gettimeofday(&end,NULL)!=0) {
    printf("gettimeofday failed");
    return -1;
  }

  double used_time=(end.tv_sec-start.tv_sec)*1000000+end.tv_usec-start.tv_usec;
  printf("%f nanoseconds\n",used_time*1000/(trial_number*page_number));

  free(a);
  return 0;
}
