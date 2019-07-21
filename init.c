#include <math.h>
#include "calc.h"
#include "y.tab.h"

static struct {		/* Constants */
	char *name;
	double cval;
} consts[] = {
	"PI",	 3.14159265358979323846,
	"E",	 2.71828182845904523536,
	"GAMMA", 0.57721566490153286060,  /* Euler */
	"DEG",	57.29577951308232087680,  /* deg/radian */
	"PHI",   1.61803398874989484820,  /* golden ratio */
	0,	 0
};

static struct {		/* Built-ins */
	char *name;
	double	(*func)();
} builtins[] = {
	"sin",	sin,
	"cos",	cos,
	"tan",	tan,
	"atan",	atan,
	"asin",	Asin,	/* checks range */
	"acos", Acos,	/* checks range */
	"sinh",	Sinh,	/* checks range */
	"cosh",	Cosh,	/* checks range */
	"tanh",	tanh,
	"log",	Log,	/* checks range */
	"lg",   Log2,	/* checks range */
	"log10", Log10,	/* checks range */
	"exp",	Exp,	/* checks range */
	"sqrt",	Sqrt,	/* checks range */
	"int",	integer,
	"abs",	fabs,
	0,	0
};

static struct {		/* Keywords */
	char	*name;
	int	kval;
} keywords[] = {
	"print",	PRINT,
	"while",	WHILE,
	"do",		DO,
	"if",		IF,
	"else",		ELSE,
	"for",		FOR,
	0,		0,
};

void
init(void)	/* install constants and built-ins in table */
{
	int i;
	Symbol *s;
	for (i = 0; consts[i].name; i++)
		install(consts[i].name, VAR, consts[i].cval);
	for (i = 0; builtins[i].name; i++) {
		s = install(builtins[i].name, BLTIN, 0.0);
		s->u.ptr = builtins[i].func;
	}
	for (i = 0; keywords[i].name; i++)
		install(keywords[i].name, keywords[i].kval, 0.0);
}
