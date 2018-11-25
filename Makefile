YFLAGS=		-d
OBJS=		calc.o init.o math.o symbol.o

calc:		$(OBJS)
		cc $(OBJS) -lm -o calc

calc.o:				calc.h
init.o symbol.o math.o:		calc.h symbol.h math.h y.tab.h

clean:
	rm -f *~ *.o y.tab.[ch] calc

.PHONY: clean
