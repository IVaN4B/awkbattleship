#!/usr/bin/awk -f
BEGIN{
	_ord_init();
	for(i = 0; i < 10; i++){
		for(j = 0; j < 10; j++){
			field[i, j] = 0;
		}
	}

	add_ship_types();
	cls();
	print_field();
	print "Welcome to Battleship!"
	print "Arrange your fleet:"
	place_ships();
	strike = 0
	hasShips = 0
}

END{
	system("rm -f battlepipe")
}

{
	if( system("test -p battlepipe") != 0 ){
		system("mkfifo battlepipe")
		strike = 1
	}
	cls();
	print_field();
	if( !hasShips ){
		print "Defeat"
		send("You win")
		exit
	}
	if( !strike ){
		getline < "battlepipe"
		close("battlepipe")
		if( NF >= 2 ){
			if( $0 == "You win" ){
				print $0
				exit
			}
			print "Incoming "$1" "$2
			x = getX($1)
			y = $2-1

			cell = field[y, x]
			if( cell > 0 ){
				type = "Destroyed"
				isBelow = (field[y+1,x] == cell)
				isAbove = (field[y-1,x] == cell)
				isLeft = (field[y, x-1] == cell)
				isRight = (field[y, x+1] == cell)
				if( cell > 1 && (isBelow || isAbove || isLeft || isRight)){
					type = "Hit"
				}
				msg = type" "ships[cell]
				field[y, x] = -1
			}else{
				msg = "Missed"
			}
			print msg
			send(msg)
		}
		strike = 1
	}else{
		print "Enter index to strike:"
		while( NF < 2 ){
			getline < "/dev/stdin"
		}
		send($0)


		getline < "battlepipe"
		close("battlepipe")

		print $0
		strike = 0
	}
	print "Hit Enter to continue or Ctrl+D to exit..."
}

function send(msg){
	print msg > "battlepipe"
	close("battlepipe")
}

function _ord_init(low, high, i, t){
    low = sprintf("%c", 7)
    if (low == "\a") {
        low = 0
        high = 127
    } else if (sprintf("%c", 128 + 7) == "\a") {
        low = 128
        high = 255
    } else {
        low = 0
        high = 255
    }

    for (i = low; i <= high; i++) {
        t = sprintf("%c", i)
        _ord_[t] = i
    }
}

function ord(str, c){
	# only first character is of interest
	c = substr(str, 1, 1)
	return _ord_[c]
}

function cls(){
	print "\033[2J \033[H"
}

function print_field(	i,	j){
	print "\t A B C D E F G H I J"
	print "\t\033[48;5;27m\033[30m+-+-+-+-+-+-+-+-+-+-+\033[0m"
	hasShips = 0
	for(i = 0; i < 10; i++){
		printf "%d\t", (i+1)
		for(j = 0; j < 10; j++){
			cell = field[i, j]
			printf "\033[48;5;27m\033[30m|"
			if( cell == 0 ){
				printf " "
			}else if( cell == 1 ){
				printf "\033[48;5;94m ", cell;
			}else if( cell == 2 ){
				printf "\033[48;5;202m ", cell;
			}else if( cell == 3 ){
				printf "\033[48;5;17m ", cell;
			}else if( cell == 4 ){
				printf "\033[48;5;16m ", cell;
			}else if( cell == -1 ){
				printf "\033[48;5;52m ", cell;
			}
			printf "\033[0m"
			if(cell > 1){
				hasShips = 1
			}
		}
		printf "\033[48;5;27m\033[30m|\033[0m";


print "\n\t\033[48;5;27m\033[30m+-+-+-+-+-+-+-+-+-+-+\033[0m"
	}
}

function add_ship_types(){
	ships[1] = "Single-decker"
	ships[2] = "Two-decker"
	ships[3] = "Three-decker"
	ships[4] = "Four-decker"
	total = 4
}

function get_ship_pos(){
	getline < "/dev/stdin"
	if( NF < 3 ){
		print "Not enough info"
		return 0
	}
	return 1
}

function is_cells_free(x, y, dir, size,		px,		py){
	for(i = 0; i < size; i++){
		if( dir == "d"){
			px = x;
			py = y+i-1;
		}else{
			px = x+i;
			py = y-1;
		}
		if( field[py, px] > 0){
			return 0;
		}
	}
	return 1;
}

function place_ships(	i,	k){
	print "Type cell and direction(down or right) to place the ship: (e. g. C 4 d):"
	for(i = total; i > 0; i--){
		type_amount = total-i+1
		for(k = 0; k < type_amount; k++){
			place_ship(i);
			print_field();
		}
	}
}

function place_ship(size, 	pos, 	free, 	x,	y,	px,	 py){
	while( 1 ){
		printf "Place your %s:", ships[size]
		pos = get_ship_pos();
		if( pos ){
			free = is_cells_free(getX($1), $2, $3, size)
			if( free ) break;
			print "Ship collides with others"
		}
	}

	for(i = 0; i < size; i++){
		x = getX($1)
		y = $2
		if( $3 == "d"){
			px = x;
			py = y+i-1;
		}else{
			px = x+i;
			py = y-1;
		}
		field[py, px] = size
	}
	return 0
}

function getX(char){
	num = ord(char)
	num = num - 0x40
	if( num <= 10 && num >= 1 ){
		return (num - 1)
	}
	return -1
}
