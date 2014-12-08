#include <iostream> 
#include <stdio.h>
#include <stdlib.h> 
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <Windows.h>
#include "device_functions.h"
#include <cuda.h>
using namespace std; 
#define villageSize 6 //村庄大小
#define random(x) (rand()%x)

void NextGeneration_CPU(int **village,int **next_village)
{
	int villagers=0;
	for (int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			villagers=0;
			/*计算每个村民周围的村民个数*/
			villagers=village[i-1][j-1]	+village[i-1][j]+village[i-1][j+1]
			+village[i][j-1]	+0				+village[i][j+1]
			+village[i+1][j-1]+village[i+1][j]+village[i+1][j+1];
			if(villagers==3)			//如果有三个，下一代生存
				*(*(next_village+i)+j)=1;
			else if(villagers==2)		//如果有两个，下一代保存这一代状态
				*(*(next_village+i)+j)=*(*(village+i)+j);
			else						//其他情况下一代死亡。
				*(*(next_village+i)+j)=0;
		}
	}
}



__global__ void NextGeneration_GPU(int *g_odata, int *g_idata)
{
	int j=threadIdx.x+threadIdx.y*blockDim.x;
	int sum=blockDim.x;
	int villagers[1024];
	if(j%(villageSize+2)==0||j%(villageSize+2)==villageSize+1||j<villageSize+2||j>=(villageSize+2)*(villageSize+1))	villagers[j]=0;
	else
	{
		villagers[j]=0;
		/*计算每个村民周围的村民个数*/
		villagers[j]=	*(g_idata+j-villageSize-3)
			+*(g_idata+j-villageSize-2)
			+*(g_idata+j-villageSize-1)
			+*(g_idata+j-1)
			+*(g_idata+j+1)
			+*(g_idata+j+villageSize+1)
			+*(g_idata+j+villageSize+2)
			+*(g_idata+j+villageSize+3);

		if(villagers[j]!=2&&villagers[j]!=3)	//如果不为2或3个，下一代死亡
			*(g_odata+j)=0;
		if(villagers[j]==3)				//如果有三个，下一代生存
			*(g_odata+j)=1;
		if(villagers[j]==2)				//如果有两个，下一代保存这一代状态
			*(g_odata+j)=*(g_idata+j);
		int a=0;
	}
}





int main() 
{
	int Generation=1;	//代数
	/*计时变量*/
	LARGE_INTEGER t_start,t_end,freq;
	float ms;
	QueryPerformanceFrequency(&freq);
	//GPU 村落初始化
	int *GPUvillageA, *GPUvillageB;//使用两个数组交替表示两代村民
	GPUvillageA = (int *)malloc(sizeof(int *) * (villageSize+2)* (villageSize+2));
	GPUvillageB = (int *)malloc(sizeof(int *) * (villageSize+2)* (villageSize+2));
	for(int i=0;i<=villageSize+1;i++){
		for(int j=0;j<=villageSize+1;j++){
			GPUvillageA[i*(villageSize+2)+j]=0;
			GPUvillageB[i*(villageSize+2)+j]=0;
		}
	}
	/*使用随机变量构造初代,40%的存活率*/
	for(int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			if(random(10)>4)
				GPUvillageA[i*(villageSize+2)+j]=1;
			else
				GPUvillageA[i*(villageSize+2)+j]=0;
		}
	}

	//CPU 村落初始化
	int **CPUvillageA, **CPUvillageB;//使用两个数组交替表示两代村民
	/*声明动态空间*/
	CPUvillageA = (int **)malloc(sizeof(int *) * villageSize+2);
	CPUvillageB = (int **)malloc(sizeof(int *) * villageSize+2);
	for(int i=0; i<villageSize+2; i++)
	{
		CPUvillageA[i] = (int *)malloc(sizeof(int) * villageSize+2);
		CPUvillageB[i] = (int *)malloc(sizeof(int) * villageSize+2);
	}
	/*初始化数组*/
	for(int i=0;i<=villageSize+1;i++){
		*((CPUvillageA[i])+0)=0;
		*((CPUvillageA[0])+i)=0;
		*((CPUvillageA[i])+villageSize+1)=0;
		*((CPUvillageA[villageSize+1])+i)=0;
	}
	/*使用随机变量构造初代,40%的存活率*/
	for(int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			if(random(10)>4)
				*((CPUvillageA[i])+j)=1;
			else
				*((CPUvillageA[i])+j)=0;
		}
	}


	/*CPU进化*/
	QueryPerformanceCounter(&t_start);
	for(Generation=1;Generation<1000;Generation++)
	{
		if(Generation%2==1){
			NextGeneration_CPU(CPUvillageA,CPUvillageB);
		}
		else{
			NextGeneration_CPU(CPUvillageB,CPUvillageA);
		}
	}
	QueryPerformanceCounter(&t_end);
	ms=1e3*(t_end.QuadPart-t_start.QuadPart)/freq.QuadPart;
	cout<<"CPU runTime: "<<ms<<endl;

	/*GPU进化*/
	int num_elements, mem_size;
	int *d_idata, *d_odata;	

	num_elements = (villageSize+2)*(villageSize+2);
	mem_size     = sizeof(int) * num_elements;


	cudaMalloc((void**)&d_idata, mem_size);
	cudaMalloc((void**)&d_odata, mem_size);

	cudaMemcpy(d_idata, GPUvillageA, mem_size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_odata, GPUvillageB, mem_size, cudaMemcpyHostToDevice);


	QueryPerformanceCounter(&t_start);

	for(Generation=1;Generation<1000;Generation++)
	{
		if(Generation%2==1){
			if(num_elements<1024)
				NextGeneration_GPU<<<1,num_elements>>>(d_odata,d_idata);
			else
				NextGeneration_GPU<<<num_elements/1024,1024>>>(d_odata,d_idata);
			cudaMemcpy(GPUvillageB, d_odata, mem_size,cudaMemcpyDeviceToHost);			
			cudaMemcpy(d_idata, GPUvillageB, mem_size, cudaMemcpyHostToDevice);
		}
		else{
			if(num_elements<1024)
				NextGeneration_GPU<<<1,num_elements>>>(d_odata,d_idata);
			else
				NextGeneration_GPU<<<num_elements/1024,1024>>>(d_odata,d_idata);
			cudaMemcpy(GPUvillageA, d_odata, mem_size,cudaMemcpyDeviceToHost);						
			cudaMemcpy(d_idata, GPUvillageA, mem_size, cudaMemcpyHostToDevice);
		}
	}

	QueryPerformanceCounter(&t_end);
	ms=1e3*(t_end.QuadPart-t_start.QuadPart)/freq.QuadPart;
	cout<<"GPU runTime: "<<ms<<endl;



	free(GPUvillageA);
	free(GPUvillageB);

	cudaFree(d_idata);
	cudaFree(d_odata);
	getchar();
	cudaDeviceReset();
	return 0;

}
