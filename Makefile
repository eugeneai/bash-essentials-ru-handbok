.PHONY: all clean

LF= -shell-escape

all:
	lualatex $(LF) bash-ru.tex
	lualatex $(LF) bash-ru.tex

clean:
	latexmk -f -C bash-ru
