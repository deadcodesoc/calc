YFLAGS=		-d
OBJS=		calc.o init.o math.o symbol.o code.o util.o

calc:		$(OBJS)
		cc $(OBJS) -lm -o calc

calc.o:				calc.h
init.o symbol.o math.o code.o:	calc.h symbol.h math.h code.h y.tab.h util.h

clean:
	rm -f *~ *.o y.tab.[ch] calc

.PHONY: clean
