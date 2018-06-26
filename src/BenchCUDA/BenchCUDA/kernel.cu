/*
	BECHMARK BASICO PARA HARDWARE. POR CARLOS ANDRES GARNICA (HARDWARE ELITE)
	
	PROGRAMA QUE SUMA 2 VECTORES Y SU RESULTADO LO GUARDA EN UN NUEVO VECTOR.
	El programa realiza estas sumas tanto por CPU como por GPU.\nSe llenan de numero 
	aleatorio en arrays de 100 mil elementos, el numero aleatorio que salga se 
	guardara en ambos arrays a sumar, por lo que los resultados no varian ni para la 
	CPU ni para la GPU.

	NOTA: El programa solo sirve para PCs con GPU NVIDIA y que sean compatibles con la 
	tecnologia CUDA.
*/
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstdio>
#include <chrono>
#include <random>
#include <limits>

#define ITER 100000

using namespace std;

typedef chrono::high_resolution_clock Clock;

// Version CPU de la función suma de vectores
void vector_add_cpu(long long *a, long long *b, long long *c, long long n) {
	int i;
	for (i = 0; i < n; ++i) {
		c[i] = a[i] + b[i];
	}
}

// Versión GPU de la función suma de vectores
__global__ void vector_add_gpu(long long *gpu_a, long long *gpu_b, long long *gpu_c, long long n) {
	int i = threadIdx.x;
	// No es necesario el loop for por que el runtime de CUDA
	// maneja estos hilos ITER (100.000) veces
	gpu_c[i] = gpu_a[i] + gpu_b[i];
	
}

// Funcion que obtiene un numero aleatorio para el llenado de los arrays
long long obtenerAleatorio() {
	random_device rd;
	mt19937 gen(rd());
	uniform_int_distribution<long long> dis(0, numeric_limits<int>::max());
	return dis(gen);
}

// Imprime el arreglo final sumado por el CPU
void imprimirArregloCPU(long long *c) {
	for (int i = 0; i < 15; i++) {
		cout << c[i] << " ";
	}
	cout << endl;
}

// Imprime el arreglo final sumado por el GPU
void imprimirArregloGPU(long long *gpu_c) {
	for (int i = 0; i < 15; i++) {
		cout << gpu_c[i] << " ";
	}
	cout << endl;
}

bool imprimirDatosGPUs() {
	int cantGPUs = 0;
	cudaGetDeviceCount(&cantGPUs);
	cout << endl << "GPUs:\n______________________________" << endl;
	if (cantGPUs > 0) {
		cout << "Tarjetas Graficas nVIDIA detectadas: " << cantGPUs << "\nINFORMACION:\n" << endl;
	}
	else {
		cout << "No se detectaron GPUs nVIDIA. Recuerde tener los controladores de sus dispositivos actualizados o instalados." << endl;
		return false;
	}
	for (int i = 0; i < cantGPUs; i++) {
		cudaDeviceProp prop;
		cudaGetDeviceProperties(&prop, i);
		cout << "Numero " << i;
		cout << endl << "Nombre: " << prop.name;
		cout << endl << "Reloj de Memoria (MHz): " << prop.memoryClockRate*0.001;
		cout << endl << "Ancho del bus de memoria (bits): " << prop.memoryBusWidth;
		cout << endl << "Ancho de banda maximo de memoria teorico (GB/s): " << 2.0*prop.memoryClockRate*(prop.memoryBusWidth / 8) / 1.0e6;
		cout << endl << "Reloj actual del GPU (MHz): " << prop.clockRate*0.001 << endl << endl;
	}
	return true;
}

int main() {

	long long *a, *b, *c;
	long long *gpu_a, *gpu_b, *gpu_c;

	a = (long long *)malloc(ITER * sizeof(long long));
	b = (long long *)malloc(ITER * sizeof(long long));
	c = (long long *)malloc(ITER * sizeof(long long));

	// Necesitamos variables accesibles en CUDA,
	// para eso cudaMallocManaged nos las provee
	cudaMallocManaged(&gpu_a, ITER * sizeof(long long));
	cudaMallocManaged(&gpu_b, ITER * sizeof(long long));
	cudaMallocManaged(&gpu_c, ITER * sizeof(long long));
	
	cout << "BECHMARK BASICO PARA HARDWARE. POR CARLOS ANDRES GARNICA (HARDWARE ELITE)" << endl << endl;
	cout << "PROGRAMA QUE SUMA 2 VECTORES Y SU RESULTADO LO GUARDA EN UN NUEVO VECTOR." << endl;
	cout << "El programa realiza estas sumas tanto por CPU como por GPU.\nSe llenan de numero aleatorio en arrays de 100 mil elementos, el numero aleatorio que salga se guardara en ambos arrays a sumar, por lo que los resultados no varian ni para la CPU ni para la GPU" << endl;
	//SI NO SE DETECTAN DISPOSITIVOS NVIDIA EN EL PC, SE TERMINA LA EJECUCION
	if (!imprimirDatosGPUs()) {
		return 0;
	}
	// SE LLENA LAS MATRICAS A Y B TANTO DE LA GPU COMO DE LA CPU PARA HACER LAS SUMAS ALEATORIAS
	for (int i = 0; i < ITER; ++i) {
		long long numAleatorio = obtenerAleatorio();
		a[i] = numAleatorio;
		b[i] = numAleatorio;
		
		gpu_a[i] = numAleatorio;
		gpu_b[i] = numAleatorio;
	}
	cout << "______________________________\n";
	cout << "TIEMPOS: " << endl;
	// Llama a la versión CPU y la temporiza
	auto cpu_start = Clock::now();
	vector_add_cpu(a, b, c, ITER);
	auto cpu_end = Clock::now();
	cout << "Suma de vectores con la CPU: "<< chrono::duration_cast<chrono::nanoseconds>(cpu_end - cpu_start).count()<< " nanosegundos.\n";

	// Llama a la versión GPU y la temporiza
	// Los triples <> es una extensión del runtime CUDA que permite
	// que los parametros de una llamada al kernel CUDA sean pasados
	// En este ejemplo estamos pasando un thread block con ITER threads
	auto gpu_start = Clock::now();
	vector_add_gpu <<<1, ITER >>> (gpu_a, gpu_b, gpu_c, ITER);
	cudaDeviceSynchronize();
	auto gpu_end = Clock::now();
	cout << "Suma de vectores con la GPU: "<< chrono::duration_cast<chrono::nanoseconds>(gpu_end - gpu_start).count() << " nanosegundos.\n";

	/*
		IMPRIME LOS RESULTADOS DE LAS SUMAS GUARDADAS EN LOS VECTORES CORRESPONDIENTES, TANTO DEL CPU COMO DEL GPU. SI AMBOS SON IGUALES, ES CORRECTO LOS
		DATOS DE TIEMPO DEL BECHMARCK
	*/
	cout << "______________________________\n";
	cout << "Resultados de las sumas (Se imprimen los primeros 15 resultados del arreglo): " << endl;
	cout << "CPU: " << endl;
	imprimirArregloCPU(c);
	cout << "GPU: " << endl;
	imprimirArregloGPU(c);

	//LIBERAR MEMORIA DE LA GRAFICA
	cudaFree(a);
	cudaFree(b);
	cudaFree(c);

	cudaFree(gpu_a);
	cudaFree(gpu_b);
	cudaFree(gpu_c);

	// Libere la memoria basada en la función CPU
	free(a);
	free(b);
	free(c);
	system("pause");
	return 0;
}
