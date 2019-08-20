typedef struct symbol Symbol;

struct symbol {
    char    *name;
    short   type;
    union {
        double  val;            /* VAR */
        double  (*ptr)(double); /* BLTIN */
        char    *str;           /* STRING */
    } u;
    Symbol  *next;
};

Symbol *install(const char *, int, double);
Symbol *lookup(const char *);
