.PHONY: all compare clean tidy

.SUFFIXES:
.SUFFIXES: .asm .o .gbc .png
.SECONDEXPANSION:

# Build Pokemon Pinball.
ROM := pokepinball.gbc
OBJS := main.o wram.o sram.o

# If your default python is 3, you may want to change this to python27.
PYTHON := python
PRET := pokemon-reverse-engineering-tools/pokemontools
MD5 := md5sum -c --quiet

$(foreach obj, $(OBJS), \
	$(eval $(obj:.o=)_dep := $(shell $(PYTHON) $(PRET)/scan_includes.py $(obj:.o=.asm))) \
)

# Link objects together to build a rom.
all: $(ROM) compare

# Assemble source files into objects.
# Use rgbasm -h to use halts without nops.
$(OBJS): $$*.asm $$($$*_dep)
	@$(PYTHON) $(PRET)/gfx.py 2bpp $(2bppq)
	@$(PYTHON) $(PRET)/gfx.py 1bpp $(1bppq)
	@$(PYTHON) $(PRET)/pcm.py pcm $(pcmq)
	rgbasm -h -o $@ $<

$(ROM): $(OBJS) contents/contents.link
	rgblink -n $(ROM:.gbc=.sym) -m $(ROM:.gbc=.map) -l contents/contents.link -o $@ $(OBJS)
	rgbfix -jsvc -k 01 -l 0x33 -m 0x1e -p 0 -r 02 -t "POKEPINBALL" -i VPHE $@

# For contributors to make sure a change didn't affect the contents of the rom.
compare: $(ROM)
	@$(MD5) rom.md5

# Remove files generated by the build process.
tidy:
	rm -f $(ROM) $(OBJS) $(ROM:.gbc=.sym) $(ROM:.gbc=.map)

clean: tidy
	find . \( -iname '*.1bpp' -o -iname '*.2bpp' -o -iname '*.pcm' \) -exec rm {} +

%.2bpp: %.png
	$(eval 2bppq += $<)
	@rm -f $@

%.1bpp: %.png
	$(eval 1bppq += $<)
	@rm -f $@

%.pcm: %.wav
	$(eval pcmq += $<)
	@rm -f $@
