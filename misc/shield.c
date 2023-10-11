/*  
This file is a dependency of the julia function get_libshield.
This funciton compiles this file together with a header "shield.h" and an associated shield binary dump shield_dump.o.
shield_dump.o is obtained by calling 
    ld -r -b binary "shield" -o "shield_dump.o"
Where "shield" is a binary file containing the raw array of a grid.

To this day I have no idea how to write a makefile.
 Run as
    library:
        gcc -c -fPIC shield.c -o shield.o
        gcc -shared shield_dump.o shield.o shield.h  -o libshield.so

*/

#include<stdio.h>
#include<stdbool.h>
#include <math.h>
#include "shield.h"

// Turns out using -1 is accidentally clever.
// -1 is shorthand for "any action" since its bit-representation is 111111...1
const int OUT_OF_BOUNDS = -1;

int convert_index(int indices[])
{
    int index = 0;
    int multiplier = 1;
    int dim;
    for (dim = 0; dim < dimensions; dim++)
    {
        index += multiplier*indices[dim];
        multiplier *= size[dim];
    }
    return index;
}

long get_index(int indices[])
{
    int index = convert_index(indices);
    // Multiply by 8 because we go from char to int64.
    return (long) ((long*) _binary_shield_start)[index];
}

int box(double  value, int dim)
{
    return (int) floor((value - lower_bounds[dim])/granularity[dim]);
}

long get_value_from_vector(double s[])
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

    // SEARCH-AND-REPLACED: The term (double s1, double s2) should not be changed since it will be altered programatically
long get_value(double s1, double s2)
{
    // SEARCH-AND-REPLACED: The term {s1, s2} should not be changed since it will be altered programatically
    return get_value_from_vector((double[]){s1, s2});
}
