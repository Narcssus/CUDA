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
		printf( "�豸����: %s\n", sDevProp.name );
		printf( "����������:%d���μ�������: %d\n", sDevProp.major,sDevProp.minor );
		printf( "�豸����ȫ���ڴ�: %0.lf\n",(double) sDevProp.totalGlobalMem);
		printf( "ÿ�߳̿�����߳���: %d\n", sDevProp.maxThreadsPerBlock);
		printf( "�豸����ȫ���ڴ�����: %d\n", sDevProp.totalConstMem);
		printf( "ÿ�߳̿���ù����ڴ�����: %d\n", sDevProp.sharedMemPerBlock );
		printf( "ÿ�߳̿���üĴ�������: %d\n", sDevProp.regsPerBlock );
		printf( "�豸�еĴ�����������: %d\n", sDevProp.multiProcessorCount);
		printf( "ÿ�������������פ���߳���: %d\n", sDevProp.maxThreadsPerMultiProcessor );
		printf( "�߳������߳�����: %d\n", sDevProp.warpSize );
		printf( "ȫ���ڴ����߿��: %d\n", sDevProp.memoryBusWidth );
		printf( "ʱ��Ƶ��: %d\n", sDevProp.clockRate );
		cudaSetDevice(numDevices);
	}


	getchar();
	return 0;
Error:
	fprintf(stderr,"CUDA failure code : 0x%x\n",status);
	return 1;
}


