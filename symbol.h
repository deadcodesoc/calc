#ifndef SYMBOL_H
#define SYMBOL_H

typedef struct symbol Symbol;

#include "code.h"

struct symbol {
    char    *name;
    short   type;
    union {
        double  val;            /* VAR */
        double  (*ptr)(double); /* BLTIN */
        Inst    *defn;		/* FUNCTION, PROCEDURE */
        char    *str;           /* STRING */
    } u;
    Symbol  *next;  /* to link to another */
};


Symbol *install(const char *, int, double);
Symbol *lookup(const char *);

#endif /* SYMBOL_H */
