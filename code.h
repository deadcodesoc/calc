#ifndef CODE_H
#define CODE_H
#include "symbol.h"

typedef void (*Inst)(void);
#define STOP    (Inst) 0

typedef union Datum {
    double  val;
    Symbol  *sym;
} Datum;

typedef struct Frame {	/* proc/func call stack frame */
	Symbol	*sp;	/* symbol table entry */
	Inst	*retpc;	/* where to resume after return */
	Datum	*argn;	/* n-th argument on stack */
	int	nargs;	/* number of arguments */
} Frame;


extern Inst prog[];
extern Inst *progp, *progbase;
extern unsigned int inbreak;
extern unsigned int incontinue;

extern void     initcode(void);
extern void     push(Datum);
extern Datum    pop(void);
extern void     constpush(void);
extern void     varpush(void);
extern void     add(void);
extern void     sub(void);
extern void     mul(void);
extern void     divop(void);
extern void     mod(void);
extern void     negate(void);
extern void     power(void);
extern void     gt(void);
extern void     ge(void);
extern void     lt(void);
extern void     le(void);
extern void     eq(void);
extern void     ne(void);
extern void     and(void);
extern void     or(void);
extern void     not(void);
extern void     preinc(void);
extern void     predec(void);
extern void     postinc(void);
extern void     postdec(void);
extern void     addeq(void);
extern void     subeq(void);
extern void     muleq(void);
extern void     diveq(void);
extern void     modeq(void);
extern void     eval(void);
extern void     assign(void);
extern void     printtop(void);
extern void     prexpr(void);
extern void     prstr(void);
extern void     whilecode(void);
extern void     dowhilecode(void);
extern void     forcode(void);
extern void     ifcode(void);
extern void     breakcode(void);
extern void     continuecode(void);
extern void     loopcode(void);
extern void     call(void);
extern void     arg(void);
extern void     argassign(void);
extern void	procret(void);
extern void argaddeq(void), argsubeq(void), argmuleq(void);
extern void argdiveq(void), argmodeq(void);
extern void     bltin(void);
extern Inst     *code(Inst);
extern void     execute(Inst*);

#endif /* CODE_H */
