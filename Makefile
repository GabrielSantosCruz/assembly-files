FILE = dp

$(FILE).o: $(FILE).s
	as -o $(FILE).o $(FILE).s

$(FILE): $(FILE).o
	ld -o $(FILE) $(FILE).o

run: $(FILE)
	./$(FILE)
