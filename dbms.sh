#!/bin/bash
shopt -s extglob
export LC_COLLATE=C
#------------------------------Create DB function-------------------------------
create_db() {
	read -p "Enter DB Name: " db_name
	if $( validate_name "$db_name" ) && ! [[ "$db_name" =~ [[:space:]] ]]
	then
		if [[ -e $db_name && -d $db_name ]]
		then
			echo "Error! Duplicated DB Name, DB already exists!"
		else
			mkdir "./$db_name"
			echo "Database $db_name created successfully"
		fi
	else
		echo "Invalid DB name, Enter a valid name"
	fi
}

#------------------------------List DB function---------------------------------
list_db() {
        echo "Available DB: "
        ls -F | grep /
 }

#------------------------------Connect DB function------------------------------
connect_db(){
	read -p "Enter DB name: " db_name
	if $( validate_name "$db_name" ) && ! [[ "$db_name" =~ [[:space:]] ]]
	then
		if [[ -e $db_name  && -d $db_name ]]
		then
			echo "DB $db_name connected Successfully"	
		else
			echo "Error!, Database Not Exists! Or It Should Be A Directory"
		fi
	else
		echo "Invalid Database Name, Enter a Valid Name."
	fi
}

#-----------------------------Drop DB function----------------------------------
drop_db(){
	read -p "Enter Database Name: " db_name
	if $( validate_name "$db_name" ) && ! [[ "$db_name" =~ [[:space:]] ]]
	then
		if [[ -e $db_name && -d $db_name ]]
		then
			rm -r $db_name
			echo "DB $db_name Deleted Successfully"
		else
			echo "Error!, Database Not Exists!"
		fi
	else
		echo "Invalid Database Name, Enter a Valid Name."
	fi
}

#-----------------------------Validate name function----------------------------
# Ensures that the dbname is non zero length and not null
validate_name() {
	[[ -n "$1" && "$1" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]
}

#-----------------------------Main menu function--------------------------------
main_menu(){
	echo "------------------------------------------------------------------"
	echo "                welcome the the DB                                "
	echo "------------------------------------------------------------------"
	PS3="Enter your choice>>>  "
	select choice in "Create DB" "List DB" "Connect to DB" "Drop DB" "Exit"
	do
		case $REPLY in 
			1)
				create_db
				;;
			2)
				list_db
				;;
		        3)
				connect_db
				;;
			4)
				drop_db
				;;
			5)
				break
				;;
			*)
				echo "Invalid Option"
		esac
	done
}
main_menu
