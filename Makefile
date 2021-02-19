.PHONY: all clean

LF= -shell-escape

all:
	lualatex $(LF) bash-ru.tex
	lualatex $(LF) bash-ru.tex

clean:
	latexmk -C bash-ru
