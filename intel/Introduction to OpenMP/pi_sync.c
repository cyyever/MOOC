#include <omp.h>
#include <stdio.h>

int main() {
	
  double start = omp_get_wtime();
  int num_steps = 100000;
  omp_set_num_threads(8);
  double step = 1.0 / (double)num_steps;
  double  pi= 0.0;

#pragma omp parallel
  {
    int nthreads=omp_get_num_threads();
    double sum = 0.0;
    for(int i = omp_get_thread_num();i<num_steps;i+=nthreads) {
      double x = (i +0.5 ) * step;
      sum += 4.0 / (1.0 + x * x);
    }
#pragma omp atomic
      pi+=sum;
  }

  pi *=step;
  printf("pi is %f\n", pi);
  printf("use time %f s\n",omp_get_wtime()-start);
  return 0;
}
