#include "symbol.h"
#include "math.h"
#include "code.h"
#include "util.h"

extern  void init(void);
extern  int follow(int, int, int);
extern  int yyparse(void);
extern  int moreinput(void);
extern  void execerror(char*, char*);
extern  void define(Symbol*);
extern  void defnonly(char *);
extern  void warning(char*, char*);
extern  int backslash(int);
extern  void varread(void);
