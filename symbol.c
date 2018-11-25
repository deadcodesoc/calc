#include <string.h>
#include <stdlib.h>

#include "symbol.h"

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
	if ((sp = malloc(sizeof(Symbol))) == NULL)
		return NULL;
	sp->name = strdup(s);
	if (sp->name == NULL) {
		free(sp);
		return NULL;
	}
	sp->type = t;
	sp->u.val = d;
	sp->next = symlist;
	symlist = sp;
	return sp;
}
