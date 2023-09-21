/*  
    This file 

    To this day I have no idea how to write a makefile.
    Some files are required which can be generated with the julia function `get_libshield(shield; [working_dir])` that should be lying around somewhere.
 Run as
    test: 
        echo "\n\n" && gcc -Wall shield.c -o shield.o && ./shield.o

    library:
        gcc -c -fPIC shield.c -o shield.o && gcc -shared -o libshield.so shield.o

*/

#include<stdio.h>
#include<stdbool.h>
#include "shield.h"

// Turns out using -1 is accidentally clever.
// -1 is shorthand for "any action" since its bit-representation is 111111...1
const int OUT_OF_BOUNDS = -1;

int get_index(int indices[])
{
    int index = 0;
    int multiplier = 1;
    int dim;
    for (dim = 0; dim < dimensions; dim++)
    {
        index += multiplier*indices[dim];
        multiplier *= size[dim];
    }
    // Multiply by 8 because we go from char to int64.
    return (int) _binary_shield_start[index*8];
}

int box(double  value, int dim)
{
    return (int) ((value - lower_bounds[dim])/granularity[dim]);
}

int get_value_from_vector(double s[])
{
    int indices[dimensions];
    int dim;
    for (dim = 0; dim < dimensions; dim++)
    {
        if (s[dim] < lower_bounds[dim] || s[dim] >= upper_bounds[dim])
        {
            return OUT_OF_BOUNDS;
        }
        indices[dim] = box(s[dim], dim);
    }

    return get_index(indices);
}

int get_value(double s1, double s2)
{
    return get_value_from_vector((double[]){s1, s2});
}

int main() {
    return 0;
}