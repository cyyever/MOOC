/* Udacity Homework 3
   HDR Tone-mapping

  Background HDR
  ==============

  A High Dynamic Range (HDR) image contains a wider variation of intensity
  and color than is allowed by the RGB format with 1 byte per channel that we
  have used in the previous assignment.  

  To store this extra information we use single precision floating point for
  each channel.  This allows for an extremely wide range of intensity values.

  In the image for this assignment, the inside of church with light coming in
  through stained glass windows, the raw input floating point values for the
  channels range from 0 to 275.  But the mean is .41 and 98% of the values are
  less than 3!  This means that certain areas (the windows) are extremely bright
  compared to everywhere else.  If we linearly map this [0-275] range into the
  [0-255] range that we have been using then most values will be mapped to zero!
  The only thing we will be able to see are the very brightest areas - the
  windows - everything else will appear pitch black.

  The problem is that although we have cameras capable of recording the wide
  range of intensity that exists in the real world our monitors are not capable
  of displaying them.  Our eyes are also quite capable of observing a much wider
  range of intensities than our image formats / monitors are capable of
  displaying.

  Tone-mapping is a process that transforms the intensities in the image so that
  the brightest values aren't nearly so far away from the mean.  That way when
  we transform the values into [0-255] we can actually see the entire image.
  There are many ways to perform this process and it is as much an art as a
  science - there is no single "right" answer.  In this homework we will
  implement one possible technique.

  Background Chrominance-Luminance
  ================================

  The RGB space that we have been using to represent images can be thought of as
  one possible set of axes spanning a three dimensional space of color.  We
  sometimes choose other axes to represent this space because they make certain
  operations more convenient.

  Another possible way of representing a color image is to separate the color
  information (chromaticity) from the brightness information.  There are
  multiple different methods for doing this - a common one during the analog
  television days was known as Chrominance-Luminance or YUV.

  We choose to represent the image in this way so that we can remap only the
  intensity channel and then recombine the new intensity values with the color
  information to form the final image.

  Old TV signals used to be transmitted in this way so that black & white
  televisions could display the luminance channel while color televisions would
  display all three of the channels.
  

  Tone-mapping
  ============

  In this assignment we are going to transform the luminance channel (actually
  the log of the luminance, but this is unimportant for the parts of the
  algorithm that you will be implementing) by compressing its range to [0, 1].
  To do this we need the cumulative distribution of the luminance values.

  Example
  -------

  input : [2 4 3 3 1 7 4 5 7 0 9 4 3 2]
  min / max / range: 0 / 9 / 9

  histo with 3 bins: [4 7 3]

  cdf : [4 11 14]


  Your task is to calculate this cumulative distribution by following these
  steps.

*/

#include "utils.h"

__global__
void find_max(const float* const d_logLuminance,
		       const size_t numPixels,
		       float *d_max_logLum
		       )
{
  extern __shared__ float sdata[];

  int x = blockIdx.x * blockDim.x + threadIdx.x;
  int tid  = threadIdx.x;

  // load shared mem from global mem
  sdata[tid] = d_logLuminance[x];
  __syncthreads();            // make sure entire block is loaded!

  // do reduction in shared mem
  for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1)
  {
    if (tid < s)
    {
      if(sdata[tid]<sdata[tid+s]) {
	sdata[tid] = sdata[tid + s];
      }
    }
    __syncthreads();        // make sure all adds at one stage are done!
  }

  // only thread 0 writes result for this block back to global mem
  if (tid == 0)
  {
    d_max_logLum[blockIdx.x] = sdata[0];
  }
}

__global__
void find_min(const float* const d_logLuminance,
		       const size_t numPixels,
		       float *d_min_logLum
		       )
{
  extern __shared__ float sdata[];

  int x = blockIdx.x * blockDim.x + threadIdx.x;
  int tid  = threadIdx.x;

  // load shared mem from global mem
  sdata[tid] = d_logLuminance[x];
  __syncthreads();            // make sure entire block is loaded!

  // do reduction in shared mem
  for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1)
  {
    if (tid < s)
    {
      if(sdata[tid]>sdata[tid+s]) {
	sdata[tid] = sdata[tid + s];
      }
    }
    __syncthreads();        // make sure all adds at one stage are done!
  }

  // only thread 0 writes result for this block back to global mem
  if (tid == 0)
  {
    d_min_logLum[blockIdx.x] = sdata[0];
  }
}

__global__
void gen_histo(const float* const d_logLuminance,
		       const size_t numPixels,
		       const size_t numBins,
		       unsigned int *d_histo,
		       const float logLumMin,
		       const float logLumRange
		       )
{

  extern __shared__  int s_histo[];

  int x = blockIdx.x * blockDim.x + threadIdx.x;

  for(int idx=threadIdx.x;idx<numBins;idx+=blockDim.x) {
    s_histo[idx] = 0;
  }
  __syncthreads();            // make sure entire block is loaded!

  if (x<numPixels) {
    unsigned int bin = static_cast<unsigned int>((d_logLuminance[x] - logLumMin) / logLumRange * numBins);
    if(bin>=numBins) {
      bin=numBins-1;
    }
    atomicAdd(&(s_histo[bin]), 1);
  }
  __syncthreads();            // make sure entire block is loaded!

  for(int idx=threadIdx.x;idx<numBins;idx+=blockDim.x) {
      atomicAdd(&(d_histo[idx]), s_histo[idx]);
  }
}

__global__
void get_cdf(const unsigned int * const d_histo,
		       const size_t numBins,
		       unsigned int * d_cdf
		       )
{
  int x = blockIdx.x * blockDim.x + threadIdx.x;
  if(x!=0) {
    return;
  }

  d_cdf[0]=0;
  for(int i=1;i<numBins;i++) {
    d_cdf[i]=d_histo[i-1]+d_cdf[i-1];
  }
}

void your_histogram_and_prefixsum(const float* const d_logLuminance,
                                  unsigned int* const d_cdf,
                                  float &min_logLum,
                                  float &max_logLum,
                                  const size_t numRows,
                                  const size_t numCols,
                                  const size_t numBins)
{
  //TODO
  /*Here are the steps you need to implement
    1) find the minimum and maximum value in the input logLuminance channel
       store in min_logLum and max_logLum
    2) subtract them to find the range
    3) generate a histogram of all the values in the logLuminance channel using
       the formula: bin = (lum[i] - lumMin) / lumRange * numBins
    4) Perform an exclusive scan (prefix sum) on the histogram to get
       the cumulative distribution of luminance values (this should go in the
       incoming d_cdf pointer which already has been allocated for you)       */

  //Step 1
  //first we find the minimum and maximum across the entire image

  float *d_min_logLum;
  float *d_max_logLum;
  size_t numPixels=numCols*numRows;
  {
    const dim3 blockSize(256, 1, 1);
    dim3 gridSize((numPixels+blockSize.x-1)/blockSize.x , 1 , 1);

    checkCudaErrors(cudaMalloc(&d_min_logLum,gridSize.x*sizeof(float)));

    find_min<<<gridSize, blockSize, blockSize.x*sizeof(float)>>>(d_logLuminance, numPixels, d_min_logLum);

    checkCudaErrors(cudaMalloc(&d_max_logLum,gridSize.x*sizeof(float)));
    find_max<<<gridSize, blockSize, blockSize.x*sizeof(float)>>>(d_logLuminance, numPixels, d_max_logLum);

    while(gridSize.x>1) {
      int groupSize=gridSize.x;
      gridSize.x=(groupSize+blockSize.x-1)/blockSize.x;
      find_min<<<gridSize, blockSize, blockSize.x*sizeof(float)>>>(d_min_logLum, groupSize, d_min_logLum);
      find_max<<<gridSize, blockSize, blockSize.x*sizeof(float)>>>(d_max_logLum, groupSize, d_max_logLum);
    }
  }

  // Call cudaDeviceSynchronize(), then call checkCudaErrors() immediately after
  // launching your kernel to make sure that you didn't make any mistakes.
  cudaDeviceSynchronize(); checkCudaErrors(cudaGetLastError());

  checkCudaErrors(cudaMemcpy(&min_logLum, d_min_logLum, sizeof(float), cudaMemcpyDeviceToHost));
  checkCudaErrors(cudaMemcpy(&max_logLum, d_max_logLum, sizeof(float), cudaMemcpyDeviceToHost));

  //Step 2 && Step 3
  unsigned int *d_histo;
  {
    const dim3 blockSize(256, 1, 1);
    const dim3 gridSize((numPixels+blockSize.x-1)/blockSize.x , 1 , 1);

    checkCudaErrors(cudaMalloc(&d_histo,numBins*sizeof(unsigned int)));
    checkCudaErrors(cudaMemset(d_histo,0,numBins*sizeof(unsigned int)));

    gen_histo<<<gridSize, blockSize,numBins*sizeof(unsigned int)>>>(d_logLuminance, numPixels, numBins,d_histo,min_logLum,max_logLum-min_logLum);

    // Call cudaDeviceSynchronize(), then call checkCudaErrors() immediately after
    // launching your kernel to make sure that you didn't make any mistakes.
    cudaDeviceSynchronize(); checkCudaErrors(cudaGetLastError());
  }

  //Step 4
  {
    const dim3 blockSize(256, 1, 1);
    get_cdf<<<1, blockSize>>>(d_histo, numBins,d_cdf);

    // Call cudaDeviceSynchronize(), then call checkCudaErrors() immediately after
    // launching your kernel to make sure that you didn't make any mistakes.
    cudaDeviceSynchronize(); checkCudaErrors(cudaGetLastError());
  }
}
