#!/usr/bin/python

S = None
IFILE = "./bash-ru-orig.tex"
OFILE = "./bash-ru.tex"


def auto(l):
    global S
    l = l.strip()
    ps = S
    c = True  # Wether to skip line

    if (l.startswith("\\begin{longtable")):
        S = "LT"
    elif (S == "LT" and l.startswith("\\end{minipage}")):
        S = "EMP"
    elif (S == "EMP" and l.startswith("\\begin{verbatim}")):
        S = "B"
        c = False
    elif (S == "B" and l.startswith("\\end{verbatim}")):
        S = "E"
        c = False
    elif (S == "E" and l.startswith("\\end{minipage}")):
        S = "EM"
    elif (S == "EM" and l.startswith("\\end{longtable}")):
        S = None
    else:
        c = False

    return c
    # if ps != S:
    #     print("S:", S)


def main():
    o = open(OFILE, "w")
    with open(IFILE) as i:
        for l in i:
            c = auto(l)
            if c:
                continue
            if S is None:
                o.write(l)
                continue
            if S in ["B", "E"]:
                o.write(l)


if __name__ == "__main__":
    main()
