
#include "stdafx.h"
#include <iostream> 
#include <stdio.h>
#include <stdlib.h> 
#include <Windows.h>
using namespace std; 
#define villageSize 8192	//��ׯ��С
#define random(x) (rand()%x)

void NextGeneration(int **village,int **next_village)
{
	int villagers=0;
	for (int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			villagers=0;
			/*����ÿ��������Χ�Ĵ������*/
			villagers=village[i-1][j-1]	+village[i-1][j]+village[i-1][j+1]
			+village[i][j-1]	+0				+village[i][j+1]
			+village[i+1][j-1]+village[i+1][j]+village[i+1][j+1];
			if(villagers==3)		//�������������һ������
				*(*(next_village+i)+j)=1;
			else if(villagers==2)	//�������������һ��������һ��״̬
				*(*(next_village+i)+j)=*(*(village+i)+j);
			else					//���������һ��������
				*(*(next_village+i)+j)=0;
		}
	}
}




int _tmain()
{
	/*��ʱ����*/
	LARGE_INTEGER t_start,t_end,freq;
	float ms;	
	QueryPerformanceFrequency(&freq);

	int Generation=1;
	int **CPUvillageA, **CPUvillageB;	//ʹ���������齻���ʾ��������
	/*������̬�ռ�*/
	CPUvillageA = (int **)malloc(sizeof(int *) * villageSize+2);
	CPUvillageB = (int **)malloc(sizeof(int *) * villageSize+2);
	for(int i=0; i<villageSize+2; i++)	
	{
		CPUvillageA[i] = (int *)malloc(sizeof(int) * villageSize+2);
		CPUvillageB[i] = (int *)malloc(sizeof(int) * villageSize+2);
	}
	/*��ʼ������*/
	for(int i=0;i<=villageSize+1;i++){
		*((CPUvillageA[i])+0)=0;
		*((CPUvillageA[0])+i)=0;
		*((CPUvillageA[i])+villageSize+1)=0;
		*((CPUvillageA[villageSize+1])+i)=0;
	}
	/*ʹ����������������,60%�Ĵ����*/
	for(int i=1;i<=villageSize;i++){
		for(int j=1;j<=villageSize;j++){
			if(random(10)>4)
				*((CPUvillageA[i])+j)=1;
			else
				*((CPUvillageA[i])+j)=0;
		}
	}





	//�ݻ�����
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
	cout<<ms<<endl;		//�������ʱ��
	getchar();
	return 0;

}

