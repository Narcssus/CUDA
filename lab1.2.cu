
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

cudaError_t VectorSum(int *c, const int *a, const int *b, unsigned int size);

__global__ void VectorSum(int *c, const int *a, const int *b)
{
	int i = threadIdx.x;
	c[i] = a[i] + b[i];
}

int main()
{
	const int arraySize = 5;
	const int a[arraySize] = { 1, 2, 3, 4,5};
	const int b[arraySize] = { 10, 20, 30, 40, 50 };
	int c[arraySize] = { 0 };
	int d=1;
	cudaError_t cudaStatus = VectorSum(c, a, b, arraySize);
	if (cudaStatus != cudaSuccess) {
		printf( "addWithCuda failed!");
		return 1;
	}
	printf("\n{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
		c[0], c[1], c[2], c[3], c[4]);
	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return 1;
	}
	getchar();

	return 0;
}
cudaError_t VectorSum(int *c, const int *a, const int *b, unsigned int size)
{
	int *dev_a = 0;
	int *dev_b = 0;
	int *dev_c = 0;
	cudaError_t err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}
	cudaMalloc((void**)&dev_a, size * sizeof(int));
	err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}

	cudaMalloc((void**)&dev_b, size * sizeof(int));
	err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}
	cudaMalloc((void**)&dev_c, size * sizeof(int));
	err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}
	cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
	err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}
	cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
	err = cudaGetLastError();
	//printf("adsdsadasdsa");
	//fprintf(stderr,cudaGetErrorString(err));
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}

	cudaMemcpy(dev_c, c, size * sizeof(int), cudaMemcpyHostToDevice);
	err = cudaGetLastError();
	if(err!=cudaSuccess){
		fprintf(stderr,cudaGetErrorString(err));
		
	}
	VectorSum<<<1, size>>>(c, dev_a, dev_b);
	err = cudaGetLastError();
	if (err != cudaSuccess) {
		fprintf(stderr, cudaGetErrorString(err));

	}
	err = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
	if (err != cudaSuccess) {
		fprintf(stderr, cudaGetErrorString(err));
	}
	return err;
}
