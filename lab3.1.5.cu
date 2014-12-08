
////////////////////////////////////////////////////////////////////////
// GPU version of Monte Carlo algorithm using NVIDIA's CURAND library
////////////////////////////////////////////////////////////////////////

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "cutil_inline.h"

#include "cuda.h"
#include <curand.h>
#include <Windows.h>
////////////////////////////////////////////////////////////////////////
// CUDA global constants
////////////////////////////////////////////////////////////////////////

__constant__ int   N;
__constant__ float a,b,c;



__global__ void pathcalc(float *x, float *part_result)
{
	float s1, s2, x1, x2, payoff;
	x = x + threadIdx.x + 2*N*blockIdx.x*blockDim.x;

	part_result = part_result + threadIdx.x +     blockIdx.x*blockDim.x;

	// path calculation

	s1 = 0.0f;

	for (int n=0; n<N; n++) {
		x1   = (*x);
		x2   = -(*x);
		x += blockDim.x;     
		s1 = s1+a*x1*x1+b*x1+c;
		s1 = s1+a*x2*x2+b*x2+c;
	}
	*part_result = s1/(2*N);
}



int main(){

	int     size=960000, h_N=100;
	float   aa, bb, cc;
	float  *result, *part_result,*x;
	double  sum;

	curandGenerator_t gen;

	result = (float *)malloc(sizeof(float)*size);

	cudaSafeCall( cudaMalloc((void **)&part_result, sizeof(float)*size) );
	cudaSafeCall( cudaMalloc((void **)&x, sizeof(float)*2*h_N*size) );

	aa = 1.0f;
	bb = 5.0f;
	cc = 9.0f;


	cudaSafeCall( cudaMemcpyToSymbol(N,    &h_N,    sizeof(h_N)) );
	cudaSafeCall( cudaMemcpyToSymbol(a,    &aa,    sizeof(aa)) );
	cudaSafeCall( cudaMemcpyToSymbol(b,    &bb,    sizeof(bb)) );
	cudaSafeCall( cudaMemcpyToSymbol(c,&cc,sizeof(cc)) );


	curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
	curandSetPseudoRandomGeneratorSeed(gen, 1234ULL);
	curandGenerateNormal(gen, x, 2*h_N*size, -1.0f, 1.0f);

	cudaSafeCall( cudaDeviceSynchronize() );

	pathcalc<<<size/64, 64>>>(x, part_result);
	cudaCheckMsg("pathcalc execution failed\n");
	cudaSafeCall( cudaDeviceSynchronize() );

	cudaSafeCall( cudaMemcpy(result, part_result, sizeof(float)*size,
		cudaMemcpyDeviceToHost) );


	sum = 0.0;

	for (int i=0; i<size; i++) {
		sum += result[i];
	}

	printf("a=%f,b=%f,c=%f\nAverage value = %f",aa,bb,cc,sum/size);

	curandDestroyGenerator(gen);

	free(result);
	cudaSafeCall( cudaFree(part_result) );
	cudaSafeCall( cudaFree(x) );

	cudaDeviceReset();
	getchar();
	return 0;
}
