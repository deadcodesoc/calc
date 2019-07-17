typedef union Datum {
    double  val;
    Symbol  *sym;
} Datum;

typedef void (*Inst)(void);
#define STOP    (Inst) 0

extern Inst prog[];
extern Inst *progp;

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
extern void     print(void);
extern void     prexpr(void);
extern void     whilecode(void);
extern void     bltin(void);
extern Inst     *code(Inst);
extern void     execute(Inst*);
