#include "calc.h"

void *
emalloc(size_t n)	/* check return from malloc */
{
	char *p = malloc(n);
	if (p == 0)
		execerror("out of memory", (char *) 0);
	return p;
}
