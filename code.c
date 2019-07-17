#include <stdio.h>
#include <math.h>
#include "calc.h"
#include "y.tab.h"

#define NSTACK	256

static Datum	stack[NSTACK];
static Datum	*stackp;

#define NPROG	2000
Inst	prog[NPROG];
Inst	*progp;
Inst	*pc;

void
initcode(void)
{
	stackp = stack;
	progp = prog;
}


void
push(Datum d)
{
	if (stackp >= &stack[NSTACK])
		execerror("stack overflow", 0);
	*stackp++ = d;
}

Datum
pop(void)
{
	if (stackp <= stack)
		execerror("stack underflow", 0);
	return *--stackp;
}

Inst *
code(Inst f)
{
	Inst *oprogp = progp;
	if (progp >= &prog[NPROG])
		execerror("program too big", 0);
	*progp++ = f;
	return oprogp;
}

void
constpush(void)
{
	Datum d;
	d.val = ((Symbol *)*pc++)->u.val;
	push(d);
}

void
varpush(void)
{
	Datum d;
	d.sym = (Symbol *)(*pc++);
	push(d);
}

void
add(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val += d2.val;
	push(d1);
}

void
sub(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val -= d2.val;
	push(d1);
}

void
mul(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val *= d2.val;
	push(d1);
}

void
div(void)
{
	Datum d1, d2;
	d2 = pop();
	if (d2.val == 0.0)
		execerror("division by zero", 0);
	d1 = pop();
	d1.val /= d2.val;
	push(d1);
}

void
mod(void)
{
	Datum d1, d2;
	d2 = pop();
	if (d2.val == 0.0)
		execerror("division by zero", 0);
	d1 = pop();
	d1.val = fmod(d1.val, d2.val);
	push(d1);
}

void
negate(void)
{
	Datum d;
	d = pop();
	d.val = -d.val;
	push(d);
}

void
power(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = Pow(d1.val, d2.val);
	push(d1);
}

void
gt(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val > d2.val);
	push(d1);
}

void
ge(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val >= d2.val);
	push(d1);
}

void
lt(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val < d2.val);
	push(d1);
}

void
le(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val <= d2.val);
	push(d1);
}

void
eq(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val == d2.val);
	push(d1);
}

void
ne(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != d2.val);
	push(d1);
}

void
and(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != 0.0 && d2.val != 0.0);
	push(d1);
}

void
or(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != 0.0 || d2.val != 0.0);
	push(d1);
}

void
not(void)
{
	Datum d;
	d = pop();
	d.val = (double)(d.val == 0.0);
	push(d);
}

void
verify(Symbol *s)
{
	if (s->type == UNDEF)
		execerror("undefined variable", s->name);
	if (s->type != VAR && s->type != UNDEF)
		execerror("attempt to evaluate non-variable", s->name);
}

void
preinc(void)
{
	Datum d;
	d.sym = (Symbol *)(*pc++);
	verify(d.sym);
	d.val = d.sym->u.val += 1.0;
	push(d);
}

void
predec(void)
{
	Datum d;
	d.sym = (Symbol *)(*pc++);
	verify(d.sym);
	d.val = d.sym->u.val -= 1.0;
	push(d);
}

void
postinc(void)
{
	Datum d;
	double v;
	d.sym = (Symbol *)(*pc++);
	verify(d.sym);
	v = d.sym->u.val;
	d.sym->u.val += 1.0;
	d.val = v;
	push(d);
}

void
postdec(void)
{
	Datum d;
	double v;
	d.sym = (Symbol *)(*pc++);
	verify(d.sym);
	v = d.sym->u.val;
	d.sym->u.val -= 1.0;
	d.val = v;
	push(d);
}

void
addeq(void)
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d2.val = d1.sym->u.val += d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
subeq(void)
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d2.val = d1.sym->u.val -= d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
muleq(void)
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d2.val = d1.sym->u.val *= d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
diveq(void)
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d2.val = d1.sym->u.val /= d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
modeq(void)
{
	Datum d1, d2;
	long x;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	// d2.val = d1.sym->u.val %= d2.val;
	// error: invalid operands to binary expression ('double' and 'double')
	x = d1.sym->u.val;
	x %= (long) d2.val;
	d2.val = d1.sym->u.val = x;
	d1.sym->type = VAR;
	push(d2);
}

void
eval(void)
{
	Datum d;
	d = pop();
	verify(d.sym);
	d.val = d.sym->u.val;
	push(d);
}

void
assign(void)
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d1.sym->u.val = d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
print(void)
{
	Datum d;
	d = pop();
	printf("\t%.17g\n", d.val);
}

void
prexpr(void)
{
	Datum d;
	d = pop();
	printf("%.17g\n", d.val);
}

void
whilecode(void)
{
	Datum d;
	Inst *savepc = pc;
	execute(savepc+2);
	d = pop();
	while (d.val) {
		execute(*((Inst **)savepc));
		execute(savepc+2);
		d = pop();
	}
	pc = *((Inst **)(savepc+1));
}

void
ifcode()
{
	Datum d;
	Inst *savepc = pc;
	execute(savepc+3);
	d = pop();
	if (d.val)
		execute(*((Inst **)(savepc)));
	else if (*((Inst **)(savepc+1)))
		execute(*((Inst **)(savepc+1)));
	pc = *((Inst **)(savepc+2));
}

void
bltin(void)
{
	Datum d;
	d = pop();
	d.val = (*(double (*)())(*pc++))(d.val);
	push(d);
}

void
execute(Inst *p)
{
	for (pc = p; *pc != STOP; )
		(*(*pc++))();
}
