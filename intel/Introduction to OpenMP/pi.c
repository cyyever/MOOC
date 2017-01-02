#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
	
  double start = omp_get_wtime();

  int num_steps = 10000;
  omp_set_num_threads(num_steps);
  double step = 1.0 / (double)num_steps;
  double *sum = calloc(num_steps , sizeof(double));

#pragma omp parallel
  {
    int ID = omp_get_thread_num();
    double x = (ID +0.5 ) * step;
    sum[ID] = 4.0 / (1.0 + x * x);
  }

  double pi = 0.0;
  for (int i = num_steps - 1; i >= 0; i--) {
    pi += sum[i];
  }

  free(sum);
  pi *= step;

  printf("pi is %f\n", pi);
  printf("use time %f s\n",omp_get_wtime()-start);
  return 0;
}
