.PHONY: all clean

all:
	lualatex bash-ru.tex
	lualatex bash-ru.tex

clean:
	latexmk -C bash-ru
