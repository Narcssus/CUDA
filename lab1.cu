#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <cuda.h>
int main()
{
	CUresult status;
	int numDevices;
	cudaGetDeviceCount(&numDevices);
	printf("%d devices detected:\n",numDevices);
	cudaDeviceProp  device;

	for(int i=0;i<numDevices;i++)
	{
		char szName[256];
		cudaGetDeviceProperties(&device,i);
		cudaDeviceProp sDevProp = device;
		printf( "设备名称: %s\n", sDevProp.name );
		printf( "主计算能力:%d、次计算能力: %d\n", sDevProp.major,sDevProp.minor );
		printf( "设备可用全局内存: %0.lf\n",(double) sDevProp.totalGlobalMem);
		printf( "每线程块最大线程数: %d\n", sDevProp.maxThreadsPerBlock);
		printf( "设备可用全局内存容量: %d\n", sDevProp.totalConstMem);
		printf( "每线程块可用共享内存容量: %d\n", sDevProp.sharedMemPerBlock );
		printf( "每线程块可用寄存器数量: %d\n", sDevProp.regsPerBlock );
		printf( "设备中的处理器簇数量: %d\n", sDevProp.multiProcessorCount);
		printf( "每个处理器簇最大驻留线程数: %d\n", sDevProp.maxThreadsPerMultiProcessor );
		printf( "线程束中线程容量: %d\n", sDevProp.warpSize );
		printf( "全局内存总线宽度: %d\n", sDevProp.memoryBusWidth );
		printf( "时钟频率: %d\n", sDevProp.clockRate );
		cudaSetDevice(numDevices);
	}


	getchar();
	return 0;
Error:
	fprintf(stderr,"CUDA failure code : 0x%x\n",status);
	return 1;
}


