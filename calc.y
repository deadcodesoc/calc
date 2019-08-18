%{
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <setjmp.h>
#include <string.h>
#include "calc.h"

#define code2(c1,c2)	code(c1); code(c2)
#define code3(c1,c2,c3)	code(c1); code(c2); code(c3)

int yylex(void);
void yyerror(char *);

unsigned int lineno = 1;
unsigned int inloop = 0;
unsigned int inbreak = 0;
unsigned int incontinue = 0;
%}

%union {
	Symbol	*sym;
	Inst	*inst;
}
%type	<inst> expr stmt stmtlist asgn cond do while if end for break continue
%type	<inst> loop
%token	<sym> NUMBER PRINT VAR BLTIN UNDEF DO WHILE IF ELSE FOR BREAK CONTINUE
%token	<sym> LOOP
%right	'=' ADDEQ SUBEQ MULEQ DIVEQ MODEQ
%left	OR
%left	AND
%left	GT GE LT LE EQ NE
%left	'+' '-'
%left	'*' '/' '%'
%left	UNARYMINUS NOT INC DEC
%right	'^'

%%

list:	/* empty */
	| list sep
	| list asgn sep		{ code2((Inst)pop, STOP); return 1; }
	| list stmt sep		{ code(STOP); return 1; }
	| list expr sep		{ code2(print, STOP); return 1; }
	| list error sep	{ yyerrok; }
	;

asgn:	  VAR '=' expr				{ $$ = $3; code3(varpush, (Inst)$1, assign); }
	| VAR ADDEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, addeq); }
	| VAR SUBEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, subeq); }
	| VAR MULEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, muleq); }
	| VAR DIVEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, diveq); }
	| VAR MODEQ expr			{ $$ = $3; code3(varpush, (Inst)$1, modeq); }
	;

stmt:     expr					{ code((Inst)pop); }
	| PRINT expr				{ code(prexpr); $$ = $2; }
	| break	{ if (!inloop) execerror("break illegal outside of loops", 0); }
	| continue { if (!inloop) execerror("continue illegal outside of loops", 0); }
	| loop {inloop++;} stmt {--inloop;} end {
		($1)[1] = (Inst)$3;	/* body of loop */
		($1)[2] = (Inst)$5; }	/* end */
	| while '(' cond ')' {inloop++;} stmt {--inloop;} end {
		($1)[1] = (Inst)$6;	/* body of loop */
		($1)[2] = (Inst)$8; }	/* end, if cond fails */
	| do {inloop++;} stmt {--inloop;} WHILE '(' cond ')' end {
		($1)[1] = (Inst)$3;	/* body of loop */
		($1)[2] = (Inst)$9; }	/* end, if cond fails */
	| for '(' cond ';' cond ';' cond ')' {inloop++;} stmt {--inloop;} end {
		($1)[1] = (Inst)$5;	/* condition */
		($1)[2] = (Inst)$7;	/* post loop */
		($1)[3] = (Inst)$10;	/* body of loop */
		($1)[4] = (Inst)$12; }	/* end, if cond fails */
	| if '(' cond ')' stmt end {
		($1)[1] = (Inst)$5;	/* then part */
		($1)[3] = (Inst)$6; }	/* end, if cond fails */
	| if '(' cond ')' stmt end ELSE stmt end {
		($1)[1] = (Inst)$5;	/* then part */
		($1)[2] = (Inst)$8;	/* else part */
		($1)[3] = (Inst)$9; }	/* end, if cond fails */
	| '{' stmtlist '}'			{ $$ = $2; }
	;

cond:    expr					{ code(STOP); }
	;

loop:	 LOOP { $$ = code3(loopcode, STOP, STOP); }
	;

while:   WHILE	{ $$ = code3(whilecode, STOP, STOP); }
	;

do:	 DO { $$ = code3(dowhilecode, STOP, STOP); }
	;

for:	 FOR { $$ = code(forcode); code3(STOP, STOP, STOP); code(STOP); }
	;

if:	IF { $$ = code(ifcode); code3(STOP, STOP, STOP); }
	;

break:	BREAK { $$ = code(breakcode); }
	;

continue: CONTINUE { $$ = code(continuecode); }
	;

end:						{ code(STOP); $$ = progp; }
	;

stmtlist:					{ $$ = progp; }
	| stmtlist sep
	| stmtlist stmt
	;

sep:      '\n' | ';'
	;

expr:	NUMBER					{ $$ = code2(constpush, (Inst)$1); }
	| VAR					{ $$ = code3(varpush, (Inst)$1, eval); }
	| asgn
	| BLTIN '(' expr ')'			{ $$ = $3; code2(bltin, (Inst)$1->u.ptr); }
	| expr '+' expr				{ code(add); }
	| expr '-' expr				{ code(sub); }
	| expr '*' expr				{ code(mul); }
	| expr '/' expr				{ code(div); }
	| expr '%' expr				{ code(mod); }
	| expr '^' expr				{ code(power); }
	| '(' expr ')'				{ $$ = $2; }
	| '[' expr ']'				{ $$ = $2; }
	| '{' expr '}'				{ $$ = $2; }
	| '-' expr %prec UNARYMINUS		{ $$ = $2; code(negate); }
	| expr GT expr				{ code(gt); }
	| expr GE expr				{ code(ge); }
	| expr LT expr				{ code(lt); }
	| expr LE expr				{ code(le); }
	| expr EQ expr				{ code(eq); }
	| expr NE expr				{ code(ne); }
	| expr AND expr				{ code(and); }
	| expr OR expr				{ code(or); }
	| NOT expr				{ $$ = $2; code(not); }
	| INC VAR				{ $$ = code2(preinc, (Inst)$2); }
	| DEC VAR				{ $$ = code2(predec, (Inst)$2); }
	| VAR INC				{ $$ = code2(postinc, (Inst)$1); }
	| VAR DEC				{ $$ = code2(postdec, (Inst)$1); }
	;

%%

char *progname = NULL;
jmp_buf begin;
char	*infile;	/* input file name */
FILE	*fin;		/* input file pointer */
char	**gargv;	/* global argument list */
int	gargc;

int c = '\n';		/* global for use by warning() */

int
yylex(void)
{
	int c;
	while ((c = getc(fin)) == ' ' || c == '\t')	/* skip white spaces */
		;
	if (c == EOF)					/* the $end */
		return 0;
	if (c == '#') {					/* comment */
		while ((c = getc(fin)) != '\n' && c >= 0)
			;
		if (c == '\n')
			lineno++;
		return c;
	}
	if (c == '.' || isdigit(c)) {			/* a number */
		double d;
		ungetc(c, fin);
		fscanf(fin, "%lf", &d);
		yylval.sym = install("", NUMBER, d);
		return NUMBER;
	}
	if (isalpha(c)) {
		Symbol *s;
		char  sbuf[100], *p = sbuf;
		do {
			if (p >= sbuf + sizeof(sbuf) - 1) {
				*p = '\0';
				execerror("name too long", sbuf);
			}
			*p++ = c;
		} while((c=getc(fin)) != EOF && isalnum(c));
		ungetc(c, fin);
		*p = '\0';
		if ((s=lookup(sbuf)) == 0) {
			s = install(sbuf, UNDEF, 0.0);
			if (s == NULL)
				execerror("out of memory", NULL);
		}
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	switch (c) {
	case '+':	return follow('+', INC, follow('=', ADDEQ, '+'));
	case '-':	return follow('-', DEC, follow('=', SUBEQ, '-'));
	case '*':	return follow('=', MULEQ, '*');
	case '/':	return follow('=', DIVEQ, '/');
	case '%':	return follow('=', MODEQ, '%');
	case '>':	return follow('=', GE, GT);
	case '<':	return follow('=', LE, LT);
	case '=':	return follow('=', EQ, '=');
	case '!':	return follow('=', NE, NOT);
	case '|':	return follow('|', OR, '|');
	case '&':	return follow('&', AND, '&');
	case '\n':	lineno++; return '\n';
	default:	return c;
	}
}

int
follow(int expect, int ifyes, int ifno)
{
	int c = getc(fin);
	if (c == expect)
		return ifyes;
	ungetc(c, fin);
	return ifno;
}

void
yyerror(char *s)
{
	warning(s, NULL);
}

void
execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

void
warning(char *s, char *t)	/* print warning message */
{
	fprintf(stderr, "%s: %s ", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	if (infile)
		fprintf(stderr, " in %s", infile);
	fprintf(stderr, " near line %d\n", lineno);
	while (c != '\n' && c != EOF)
		if ((c = getc(fin)) == '\n')	/* flush rest of input line */
			lineno++;
}

int
moreinput(void)
{
	if (gargc-- <= 0)
		return 0;
	if (fin && fin != stdin)
		fclose(fin);
	infile = *gargv++;
	lineno = 1;
	if (strcmp(infile, "-") == 0) {
		fin = stdin;
		infile = 0;
	} else if ((fin=fopen(infile, "r")) == NULL) {
		fprintf(stderr, "%s: can't open %s\n", progname, infile);
		return moreinput();
	}
	return 1;
}

void
run(void)	/* execute until EOF */
{
	setjmp(begin);
	for (initcode(); yyparse(); initcode())
		execute(prog);
}

int
main(int argc, char *argv[])
{
	static int first = 1;
#if YYDEBUG > 0
	extern int yydebug;
	yydebug=3;
#endif
	progname = argv[0];
	init();
	if (argc == 1) {	/* fake an argument list */
		static char *stdinonly[] = { "-" };
		gargv = stdinonly;
		gargc = 1;
	} else if (first) {	/* for interrupts */
		first = 0;
		gargv = argv+1;
		gargc = argc-1;
	}
	while (moreinput())
		run();
	return 0;
}
