#include <string.h>
#include <stdlib.h>
#include "symbol.h"
#include "util.h"

static Symbol *symlist = NULL;

Symbol *
lookup(const char *s)
{
	for (Symbol *sp = symlist; sp != NULL; sp = sp->next)
		if (strcmp(sp->name, s) == 0)
			return sp;
	return NULL;
}

Symbol *
install(const char *s, int t, double d)
{
	Symbol *sp;
	sp = emalloc(sizeof(Symbol));
	sp->name = emalloc(strlen(s)+1); /* +1 for '\0' */
	strcpy(sp->name, s);
	sp->type = t;
	sp->u.val = d;
	sp->next = symlist;
	symlist = sp;
	return sp;
}
