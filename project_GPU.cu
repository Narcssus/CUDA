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
#define villagerSize 10000
#define random(x) (rand()%x)

void NextGeneration_CPU(int **village,int **next_village)
{
	int villagers=0;
	for (int i=1;i<=villagerSize;i++){
		for(int j=1;j<=villagerSize;j++){
			villagers=0;
			villagers=village[i-1][j-1]	+village[i-1][j]+village[i-1][j+1]
			+village[i][j-1]	+0				+village[i][j+1]
			+village[i+1][j-1]+village[i+1][j]+village[i+1][j+1];
			if(villagers==3)
				*(*(next_village+i)+j)=1;
			else if(villagers==2)
				*(*(next_village+i)+j)=*(*(village+i)+j);
			else
				*(*(next_village+i)+j)=0;
		}
	}
}



__global__ void NextGeneration_GPU(int *g_odata, int *g_idata)
{
	int j = threadIdx.x;
	int sum=blockDim.x;
	int villagers[1024];
	if(j%(villagerSize+2)==0||j%(villagerSize+2)==villagerSize+1||j<villagerSize+2||j>=(villagerSize+2)*(villagerSize+1))	villagers[j]=0;
	else
	{
		villagers[j]=0;
		villagers[j]=	*(g_idata+j-villagerSize-3)
			+*(g_idata+j-villagerSize-2)
			+*(g_idata+j-villagerSize-1)
			+*(g_idata+j-1)
			+*(g_idata+j+1)
			+*(g_idata+j+villagerSize+1)
			+*(g_idata+j+villagerSize+2)
			+*(g_idata+j+villagerSize+3);

		if(villagers[j]!=2&&villagers[j]!=3)
			*(g_odata+j)=0;
		if(villagers[j]==3)
			*(g_odata+j)=1;
		if(villagers[j]==2)
			*(g_odata+j)=*(g_idata+j);
		int a=0;
	}
}





int main() 
{
	int Generation=1;
	 LARGE_INTEGER t_start,t_end,freq;
  float ms;
  QueryPerformanceFrequency(&freq);
	int *villageA, *villageB;
	villageA = (int *)malloc(sizeof(int *) * (villagerSize+2)* (villagerSize+2));
	villageB = (int *)malloc(sizeof(int *) * (villagerSize+2)* (villagerSize+2));
	for(int i=0;i<=villagerSize+1;i++){
		for(int j=0;j<=villagerSize+1;j++){
			villageA[i*(villagerSize+2)+j]=0;
			villageB[i*(villagerSize+2)+j]=0;
		}
	}

	for(int i=1;i<=villagerSize;i++){
		for(int j=1;j<=villagerSize;j++){
			if(random(10)>4)
				villageA[i*(villagerSize+2)+j]=1;
			else
				villageA[i*(villagerSize+2)+j]=0;
		}
	}
	for(int i=1;i<=villagerSize;i++){
		for(int j=1;j<=villagerSize;j++){
	//		cout<<villageA[i*(villagerSize+2)+j]<<" ";
		}
	//	cout<<endl;
	}
//	cout<<"OK"<<endl;
//	getchar();

	//CPU
	/*
	for(Generation=1;Generation<3000;Generation++)
	{
	if(Generation%2==1){
	NextGeneration_CPU(villageA,villageB);
	for(int i=1;i<=villagerSize;i++){
	for(int j=1;j<=villagerSize;j++){
	cout<<villageB[i][j]<<" ";
	}
	cout<<endl;
	}
	}
	else{
	NextGeneration_CPU(villageB,villageA);
	for(int i=1;i<=villagerSize;i++){
	for(int j=1;j<=villagerSize;j++){
	cout<<villageA[i][j]<<" ";
	}
	cout<<endl;
	}
	}
	getchar();
	}
	*/







	int num_elements, num_threads, mem_size, shared_mem_size;

	int *d_idata, *d_odata;


	num_elements = (villagerSize+2)*(villagerSize+2);
	num_threads  = num_elements;
	mem_size     = sizeof(int) * num_elements;


	cudaMalloc((void**)&d_idata, mem_size);
	cudaMalloc((void**)&d_odata, mem_size);

	cudaMemcpy(d_idata, villageA, mem_size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_odata, villageB, mem_size, cudaMemcpyHostToDevice);

	shared_mem_size = sizeof(int) * num_elements;


	  QueryPerformanceCounter(&t_start);

	for(Generation=1;Generation<10;Generation++)
	{
		if(Generation%2==1){
			NextGeneration_GPU<<<1,num_threads>>>(d_odata,d_idata);
			cudaMemcpy(villageB, d_odata, mem_size,cudaMemcpyDeviceToHost);			
				for(int i=1;i<=villagerSize;i++){
					for(int j=1;j<=villagerSize;j++){
				//		cout<<villageB[i*(villagerSize+2)+j]<<" ";
					}
				//	cout<<endl;
				}
			cudaMemcpy(d_idata, villageB, mem_size, cudaMemcpyHostToDevice);
		}
		else{
			NextGeneration_GPU<<<1,num_threads>>>(d_odata,d_idata);
			cudaMemcpy(villageA, d_odata, mem_size,cudaMemcpyDeviceToHost);						
				for(int i=1;i<=villagerSize;i++){
					for(int j=1;j<=villagerSize;j++){
				//		cout<<villageA[i*(villagerSize+2)+j]<<" ";
					}
				//	cout<<endl;
				}
			cudaMemcpy(d_idata, villageA, mem_size, cudaMemcpyHostToDevice);
		}
	//	cout<<endl;
		 

	//	cout<<"finished"<<endl;
	//	getchar();
	}

	 QueryPerformanceCounter(&t_end);
	   ms=1e3*(t_end.QuadPart-t_start.QuadPart)/freq.QuadPart;
cout<<"times"<<ms<<endl;



		free(villageA);
		free(villageB);

		cudaFree(d_idata);
		cudaFree(d_odata);
		getchar();
		cudaDeviceReset();
		return 0;

	}
