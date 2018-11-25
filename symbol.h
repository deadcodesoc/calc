typedef struct symbol Symbol;

struct symbol {
    char    *name;
    short   type;
    union {
        double  val;
        double  (*ptr)();
    } u;
    Symbol  *next;
};

Symbol *install(const char *, int, double);
Symbol *lookup(const char *);
