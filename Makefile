### Build Options ###

BASEROM      := baserom.us.z64
TARGET       := marioparty2
COMPARE      ?= 1
NON_MATCHING ?= 1
CHECK        ?= 0
VERBOSE      ?= 0

ifeq ($(wildcard $(BASEROM)),)
$(error Baserom `$(BASEROM)' not found.)
endif

ifeq ($(NON_MATCHING),1)
override COMPARE=0
endif

ifeq ($(VERBOSE),0)
V := @
endif

BUILD_DIR := build
ROM       := $(BUILD_DIR)/$(TARGET).z64
ELF       := $(BUILD_DIR)/$(TARGET).elf
LD_SCRIPT := $(TARGET).ld
LD_MAP    := $(BUILD_DIR)/$(TARGET).map

PYTHON     := venv/bin/python3
N64CKSUM   := $(PYTHON) tools/n64cksum.py
SPLAT      := venv/bin/splat split marioparty2.yaml
VERIFY     := $(PYTHON) tools/verify_rom.py

# Requires mips-linux-gnu binutils + Linux x86 GCC 2.7.2 (see install.sh)
CROSS    := mips-linux-gnu-
AS       := $(CROSS)as
LD       := $(CROSS)ld
OBJCOPY  := $(CROSS)objcopy
STRIP    := $(CROSS)strip
CC       := tools/gcc_2.7.2/gcc
CC_HOST  := gcc

ASFLAGS  := -G 0 -I include -mips3 -mabi=32
CFLAGS   := -O1 -G0 -mips3 -mgp32 -mfp32
CPPFLAGS := -I include -I src -DF3DEX_GBI_2 -D_LANGUAGE_C
LDFLAGS  := -T undefined_syms.txt -T undefined_funcs.txt -T undefined_funcs_auto.txt -T undefined_syms_auto.txt -T $(LD_SCRIPT) -Map $(LD_MAP) --no-check-sections

OBJECTS := $(shell grep -E 'build.+\.o' $(LD_SCRIPT) -o 2>/dev/null)
DEPENDS := $(OBJECTS:=.d)

.PHONY: all clean distclean split verify setup

all: verify

setup: split

split:
	$(V)$(SPLAT)

verify:
	$(V)$(VERIFY)

clean:
	$(V)rm -rf build

distclean: clean
	$(V)rm -rf asm src/overlays
	$(V)rm -f undefined_*auto.txt marioparty2.ld

# Full matching build (requires cross toolchain on Linux/x86 or Rosetta + QEMU)
$(ROM): $(ELF)
	$(V)$(OBJCOPY) $< $@ -O binary
	$(V)$(N64CKSUM) $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS)
	$(V)$(LD) $(LDFLAGS) -o $@

$(BUILD_DIR)/src/%.c.o: src/%.c
	@mkdir -p $(dir $@)
	$(V)export COMPILER_PATH=tools/gcc_2.7.2 && $(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<
	$(V)$(STRIP) $@ -N dummy-symbol-name 2>/dev/null || true

$(BUILD_DIR)/asm/%.s.o: asm/%.s
	@mkdir -p $(dir $@)
	$(V)$(AS) $(ASFLAGS) -o $@ $<

MAKEFLAGS += --no-builtin-rules
