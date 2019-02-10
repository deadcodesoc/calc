typedef union Datum {
    double  val;
    Symbol  *sym;
} Datum;

typedef void (*Inst)(void);
#define STOP    (Inst) 0

extern Inst prog[];

extern void     initcode(void);
extern void     push(Datum);
extern Datum    pop(void);
extern void     constpush(void);
extern void     varpush(void);
extern void     add(void);
extern void     sub(void);
extern void     mul(void);
extern void     div(void);
extern void     mod(void);
extern void     negate(void);
extern void     power(void);
extern void     eval(void);
extern void     assign(void);
extern void     print(void);
extern void     bltin(void);
extern Inst     *code(Inst);
extern void     execute(Inst*);
