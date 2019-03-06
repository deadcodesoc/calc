#include "symbol.h"
#include "math.h"
#include "code.h"

extern  void init(void);
extern  int follow(int, int, int);
extern  int yyparse(void);
extern  void execerror(char*, char*);
extern  void warning(char*, char*);
