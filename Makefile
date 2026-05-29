# Conservation Spectral SDK — Ada Production Build
# SPDX-License-Identifier: MIT

CC      = gnat
GNATMAKE = gnatmake
CFLAGS  = -gnat12 -gnata -gnatf -gnato -O2 -gnatwn

# -gnat12    : Ada 2012 mode (preconditions, etc.)
# -gnata     : Enable assertions and pre/post conditions
# -gnatf     : Full error messages
# -gnato     : Overflow checks enabled
# -O2        : Optimization level 2
# -gnatwn    : Warnings: non-portable
# -gnatyg    : Style: GNAT style checks
# -gnatyM120 : Max line length 120

TARGET  = main

.PHONY: all clean run test

all: $(TARGET)

$(TARGET): main.adb conservation_spectral.ads conservation_spectral.adb \
           eigen.ads eigen.adb anomaly.ads anomaly.adb \
           generic_conservation.ads generic_conservation.adb
	$(GNATMAKE) $(TARGET) $(CFLAGS) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

test: $(TARGET)
	@echo "Running test suite..."
	@./$(TARGET)
	@echo ""
	@echo "Exit code: $$?"

clean:
	rm -f *.o *.ali $(TARGET) b~*.* 2>/dev/null || true
	rm -rf .objs/ 2>/dev/null || true

# GNAT produces .ali files (Ada Library Information) - needed for smart recompilation
# .o files are standard object files
# b~* files are binder-generated temporaries
