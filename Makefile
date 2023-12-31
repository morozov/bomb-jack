GAME=Bomb-Jack

URL=https://www.worldofspectrum.org/pub/sinclair/games/b/BombJack.tzx.zip

PNG=$(GAME).png
SCL=$(GAME).scl
SCR=$(GAME).scr
SCZ=$(GAME).scz
TAP=Bomb\ Jack.tap
TRD=$(GAME).trd
TZX=Bomb\ Jack.tzx
ZIP=BombJack.tzx.zip

HOB_BOOT=boot.$$B
HOB_SCRN=screenz.$$C
HOB_DATA=data.$$C

all: $(SCL) $(PNG)

$(SCL): $(TRD)
	trd2scl '$<' '$@'

# The compressed screen is created by Laser Compact v5.2
# and cannot be generated at the build time
# see https://spectrumcomputing.co.uk/?cat=96&id=21446
$(TRD): $(HOB_BOOT) $(HOB_SCRN) $(HOB_DATA)
# Create a temporary file first in order to make sure the target file
# gets created only after the entire job has succeeded
	$(eval TMPFILE=$(shell mktemp))

	createtrd $(TMPFILE)

# Calculate the total program size in sectors and write it to the first file (offset 13)
# Got to use the the octal notation since it's the only format of binary data POSIX printf understands
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html#tag_20_94_13
	total_size=0; \
	for i in $(patsubst %, '%', $+); do \
		size=$$(dd if="$$i" bs=1 skip=14 count=1 2>/dev/null | od -An -t u1); \
		total_size=$$(( total_size + size )); \
		hobeta2trd "$$i" $(TMPFILE); \
	done; \
	printf "\\$$(printf %o $$total_size)" | dd of=$(TMPFILE) bs=1 seek=13 conv=notrunc status=none

# Remove remaining files from the catalog (fill the bytes starting at offset 16 with zeroes)
	dd if=/dev/zero of=$(TMPFILE) bs=1 seek=16 count=$$((($(words $^) - 1) * 16)) conv=notrunc status=none

# Rename the temporary file to target name
	mv $(TMPFILE) '$@'

$(ZIP):
	wget $(URL)

$(TZX): $(ZIP)
	unzip -u '$<' && touch -c '$@'

$(TAP): $(TZX)
	tzx2tap '$<'

screen-encoded.000 data-encoded.000: $(TAP)
# Cannot use the `-f` flag of tapto0 because it will make
# headerless files from the same *.tap override each other
	$(eval TMPDIR=$(shell mktemp -d))
	cp $(TAP) $(TMPDIR)
	cd $(TMPDIR); tapto0 $(TAP)
	cp $(TMPDIR)/headless.000 screen-encoded.000
	cp $(TMPDIR)/headless.001 data-encoded.000
	rm -r $(TMPDIR)

$(SCR): screen-encoded.000
	0tobin '$<'
	tools/decode.py < screen-encoded.bin > "$@"

screenz.bin: $(SCR)
	laser521 -d '$<' '$@'

screenz.000: screenz.bin
	binto0 '$<' 3

$(HOB_SCRN): screenz.000
	0tohob '$<'

$(PNG): $(SCR)
	SOURCE_DATE_EPOCH=1970-01-01 convert '$<' -scale 200% '$@'

data.bin: data-encoded.000
	0tobin '$<'
	tools/decode.py < data-encoded.bin > "$@"

data.000: data.bin
	binto0 '$<' 3

$(HOB_DATA): data.000
	0tohob '$<'

boot.bin: src/boot.asm
	pasmo --bin '$<' '$@'

boot.bas: src/boot.bas boot.bin
# Replace the __LOADER__ placeholder with the machine codes with bytes represented as {XX}
	sed "s/__LOADER__/$(shell hexdump -ve '1/1 "{%02x}"' boot.bin)/" '$<' > '$@'

boot.tap: boot.bas
	bas2tap -sboot -a10 '$<' '$@'

boot.000: boot.tap
	tapto0 -f '$<'

$(HOB_BOOT): boot.000
	0tohob '$<'

clean:
	rm -f \
		*.000 \
		*.001 \
		*.\$$B \
		*.\$$C \
		*.bas \
		*.bin \
		*.png \
		*.scl \
		*.scr \
		*.tap \
		*.trd \
		*.tzx \
		*.zip
