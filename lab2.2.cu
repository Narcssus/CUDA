#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <math.h>
#include<time.h>
#include<stdlib.h>

#define arrayLength 10000
float a[10240000],b[10240000];
float c[1048576];
cudaError_t addWithCuda(float *c, const float *a, const float *b, unsigned int size);

double randf() 
{ 
	return (double)(rand()/(double)RAND_MAX); 
}
__global__ void calculWithGPU(float *c, const float *a, const float *b,int k)
{
	int i = blockIdx.x;
	int j = threadIdx.x;
	c[i+j*1024]=c[i+j*1024]+(a[i*1024+k]-b[j*1024+k])*(a[i*1024+k]-b[j*1024+k]);
}

void calculWithCPU()
{
	for(int i=0;i<1024;i++)
	{
		for(int j=0;j<1024;j++)
		{
			for(int k=0;k<arrayLength;k++)
			{
				c[i+j*1024]=c[i+j*1024]+(a[i*1024+k]-b[j*1024+k])*(a[i*1024+k]-b[j*1024+k]);
			}
			c[i+j*1024]=sqrtf(c[i+j*1024]);
		}
	}

}

int main()
{
	cudaEvent_t start = 0;
	cudaEvent_t stop = 0;
	time_t t_start,t_end;  
	//*********以下是生成随机数程序**********************
	srand(time(NULL)); 
	for(int i=0;i<1024;i++){
		for(int j=0;j<arrayLength;j++){
			a[i*arrayLength+j]=randf();
		}
	}
	for(int i=0;i<1024;i++){
		for(int j=0;j<arrayLength;j++){
			b[i*arrayLength+j]=randf();
		}
	}
	for(int i=0;i<1048576;i++)
	{
		c[i]=0;
	}
	//*********以下是CPU程序*******************************
	/*
	t_start = time(NULL) ;
	calculWithCPU();
	t_end = time(NULL) ;
	printf("CPU spends %ld s to finish the mission.Press ENTER to see the data\n",t_end-t_start );
	getchar();
	for(int i=0;i<1024*1024;i++)
	{
		printf("%f\n",c[i]);
	}
	getchar();
	*/
	//*************以下是GPU程序****************************
	
	t_start = time(NULL) ;
	cudaError_t cudaStatus = addWithCuda(c, a, b, 10240000);
	for(int i=0;i<1024*1024;i++)
	{
		c[i]=sqrtf(c[i]);
	}
	t_end = time(NULL) ;
	printf("GPU spends %ld s to finish the mission.Press ENTER to see the data\n",t_end-t_start );
	getchar();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addWithCuda failed!");
		return 1;
	}

	for(int i=0;i<1024*1024;i++)
	{
		printf("%f\n",c[i]);
		//getchar();
	}

	getchar();
	return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(float *c, const float *a, const float *b, unsigned int size)
{
	float *dev_a = 0;
	float *dev_b = 0;
	float *dev_c = 0;
	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}

	// Allocate GPU buffers for three vectors (two input, one output).
	cudaStatus = cudaMalloc((void**)&dev_c, 1048576 * sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(float), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(float), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}
	cudaStatus = cudaMemcpy(dev_c, c, 1048576 * sizeof(float), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}
	// Launch a kernel on the GPU with one thread for each element.
	for(int k=0;k<arrayLength;k++)
		calculWithGPU<<<1024, 1024>>>(dev_c, dev_a, dev_b,k);

	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(c, dev_c, 1048576 * sizeof(float), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

Error:
	cudaFree(dev_c);
	cudaFree(dev_a);
	cudaFree(dev_b);

	return cudaStatus;
}
