TESTS = test_cpy test_ref

TEST_DATA = s Tai

CFLAGS = -O0 -Wall -Werror -g

# Control the build verbosity                                                   
ifeq ("$(VERBOSE)","1")
    Q :=
    VECHO = @true
else
    Q := @
    VECHO = @printf
endif

GIT_HOOKS := .git/hooks/applied

.PHONY: all clean

all: $(GIT_HOOKS) $(TESTS)

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

OBJS_LIB = \
    tst.o bloom.o

OBJS := \
    $(OBJS_LIB) \
    test_cpy.o \
    test_ref.o

deps := $(OBJS:%.o=.%.o.d)

test_%: test_%.o $(OBJS_LIB)
	$(VECHO) "  LD\t$@\n"
	$(Q)$(CC) $(LDFLAGS)  -o $@ $^ -lm

%.o: %.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) -c -MMD -MF .$@.d $<

test:  $(TESTS)
	echo 3 | sudo tee /proc/sys/vm/drop_caches;
	perf stat --repeat 20 \
                -e cache-misses,cache-references,instructions,cycles \
                ./test_cpy --bench $(TEST_DATA)
	perf stat --repeat 20 \
                -e cache-misses,cache-references,instructions,cycles \
				./test_ref --bench $(TEST_DATA)
				

 bench: $(TESTS)
	@for test in $(TESTS); do\
		./$$test --bench $(TEST_DATA); \
	done
 output.txt: test calculate
	./calculate

plot: output.txt
	gnuplot scripts/runtime.gp
	eog runtime.png
	bench_cpy.txt
	gnuplot scripts/runtime3.gp
	eog runtime3.png
	gnuplot scripts/runtimept.gp
	eog runtime2.png 
			

calculate: calculate.c
	$(CC) $(CFLAGS_common) $^ -o $@

 
clean:
	$(RM) $(TESTS) $(OBJS)
	$(RM) $(deps)
	rm -f  bench_cpy.txt bench_ref.txt ref.txt cpy.txt output.txt caculate

-include $(deps)
