#include <omp.h>
#include <stdio.h>

int main() {
	
  double start = omp_get_wtime();
  int num_steps = 100000;
  omp_set_num_threads(8);
  double step = 1.0 / (double)num_steps;
  double  pi= 0.0;
  double  sum= 0.0;



#pragma omp parallel for reduction (+: sum) 
    for(int i = 0;i<num_steps;i++) {
      double x = (i +0.5 ) * step;
      sum += 4.0 / (1.0 + x * x);
    }

  pi =sum*step;
  printf("pi is %f\n", pi);
  printf("use time %f s\n",omp_get_wtime()-start);
  return 0;
}
