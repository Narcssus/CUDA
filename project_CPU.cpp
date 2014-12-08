
#include "stdafx.h"
#include <iostream> 
#include <stdio.h>
#include <stdlib.h> 
#include <Windows.h>
using namespace std; 
#define villageSize 8192	//村庄大小
#define random(x) (rand()%x)

void NextGeneration(int **village,int **next_village)
{
	int villagers=0;
	for (int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			villagers=0;
			/*计算每个村民周围的村民个数*/
			villagers=village[i-1][j-1]	+village[i-1][j]+village[i-1][j+1]
			+village[i][j-1]	+0				+village[i][j+1]
			+village[i+1][j-1]+village[i+1][j]+village[i+1][j+1];
			if(villagers==3)		//如果有三个，下一代生存
				*(*(next_village+i)+j)=1;
			else if(villagers==2)	//如果有两个，下一代保存这一代状态
				*(*(next_village+i)+j)=*(*(village+i)+j);
			else					//其他情况下一代死亡。
				*(*(next_village+i)+j)=0;
		}
	}
}




int _tmain()
{
	/*计时变量*/
	LARGE_INTEGER t_start,t_end,freq;
	float ms;	
	QueryPerformanceFrequency(&freq);

	int Generation=1;
	int **CPUvillageA, **CPUvillageB;	//使用两个数组交替表示两代村民
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
	/*使用随机变量构造初代,60%的存活率*/
	for(int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			if(random(10)>4)
				*((CPUvillageA[i])+j)=1;
			else
				*((CPUvillageA[i])+j)=0;
		}
	}





	//演化过程
	QueryPerformanceCounter(&t_start);
	for(Generation=1;Generation<1000;Generation++)
	{
		if(Generation%2==1){
			NextGeneration(CPUvillageA,CPUvillageB);
		}
		else{
			NextGeneration(CPUvillageB,CPUvillageA);
		}
	}
	QueryPerformanceCounter(&t_end);
	ms=1e3*(t_end.QuadPart-t_start.QuadPart)/freq.QuadPart;
	cout<<ms<<endl;		//输出运行时间
	getchar();
	return 0;

}

