#!/bin/sh

table_menu(){
    select choice in "Create table" "List table" "Select From Table" "Drop Table" "Delete From Table" "Update Table" "Insert Into Table" "Back To Main Menu" ;  
    do
        case $REPLY in
            1) create_table ;;
            2) list_table ;;
            3) select_from_table ;;
            4) drop_table ;;
            5) delete_from_table ;;
            6) update_table ;;
            7) insert_into_table ;;
            8) back_to_menu ;;
            *) echo "Invalid Choice! Choose option between 1 to 8." ;;
        esac
    done
}

# -------------------------------- Create Table FN  -----------------------------------
create_table() {
    while true 
    do
        read -p "Enter Table Name: " tb_name
        if validate_name "$tb_name" && ! [[ "$tb_name" =~ [[:space:]] ]] 
        then
            if [[ -e "./$db_name/$tb_name" ]] 
            then
                echo "Error! Duplicated Table Name, Table Already Exists!"
            else
                touch "./$db_name/$tb_name"
                touch "./$db_name/metadata_$tb_name"
                
                while true 
                do
                    read -p "Enter number of fields: " num_of_fields
                    if [[ ! $num_of_fields =~ ^[0-9]+$ ]] || [[ "$num_of_fields" -lt 1 ]]
                    then
                        echo "Invalid input. Please enter a valid input."
                    else
                        break
                    fi
                done

                declare -a colnames=()
                declare -a coltypes=()
                for ((i=0; i<$num_of_fields; i++))
                do
                    while true 
                    do
                        read -p "Enter Column Name: " colname
                        if ! validate_name "$colname" || [[ "$colname" =~ [[:space:]] ]] 
                        then
                            echo "Invalid Column Name, Enter a Valid Name."
                        elif [[ " ${colnames[@]} " =~ " ${colname} " ]]
                        then
                            echo "Column Name '$colname' already exists. Enter a different name."
                        else
                            colnames+=("$colname")
                            break
                        fi
                    done

                    while true 
                    do
                        read -p "Enter Column Type (str/int): " coltype
                        case $coltype in
                            "str" | "int")
                                coltypes+=("$coltype")
                                break
                                ;;
                            *)
                                echo "Invalid column type. Enter 'str' or 'int'"
                                ;;
                        esac
                    done
                done

                echo "Choose One Primary Key from the above List:"
                for col in "${colnames[@]}"
                do
                    echo "- $col"
                done

                while true 
                do
                    read -p "Enter Primary Key Name: " pk
                    if [[ " ${colnames[@]} " =~ " ${pk} " ]] 
                    then
                        break
                    else
                        echo "Invalid Input. Please choose a field from the list."
                    fi
                done

                for ((i=0; i<$num_of_fields; i++))
                do
                    metadata="${colnames[$i]}:${coltypes[$i]}"
                    # Set primary key flag based on user input
                    if [[ "${colnames[$i]}" == "${pk}" ]]
                    then
                        metadata+=":1"
                    else
                        metadata+=":0"
                    fi

                    echo "$metadata" >> "./$db_name/metadata_$tb_name"
                done

                echo "Table '$tb_name' Created Successfully."
                break
            fi
        else
            echo "Invalid Table Name, Enter a Valid Name."
        fi
    done
}

# -------------------------------- List Table FN ----------------------------------
list_table(){
    if [  $(ls ./$db_name | grep -v "^metadata_" | wc -l ) -gt 0 ]
    then
        echo "Available Tables: " 
        ls ./$db_name | grep -v "^metadata_"
    else 
        echo " No Tables Created Yet "
    fi
}

# -------------------------------- Drop Table FN ----------------------------------
drop_table() {
    while true
    do
        if [ -z "$(ls -A "./$db_name")" ]
        then
            echo "No tables found in the database."
            break
        fi
        
        echo "Tables in the database:"
        list_table # call list_table function
        
        read -p "Enter name of table to drop: " tb_name
        case $tb_name in
            # Check if tb_name is not empty or contain any special characters
            *[!\ \/\\\*\-\+\#\$\%\^\&\*0-9]*) 
                if [[ -f "./$db_name/$tb_name" ]]
                then
                    rm "./$db_name/$tb_name"
                    rm "./$db_name/metadata_$tb_name"
                    echo "Table '$tb_name' dropped successfully."
                    break
                else
                    echo "Table not found! Enter a valid table name."
                fi
                ;;
            *)
                echo "Invalid input! Enter a valid table name."
                ;;
        esac
    done
}

# -------------------------------- Delete Table FN --------------------------------
delete_from_table(){
    while true
    do
        if [ -z "$(ls -A "./$db_name")" ]
        then
            echo "No tables found in the database."
            break
        fi
        
        echo "Tables in the database:"
        list_table # call list_table function
        
        read -p "Enter name of table to delete from: " tb_name
        case $tb_name in
            *[!\ \/\\\*\-\+\#\$\%\^\&\*0-9]*) 
                if [[ -f "./$db_name/$tb_name" ]] 
                then
                    if [[ -s ./$db_name/metadata_$tb_name ]] && [[ -s ./$db_name/$tb_name ]]
                    then
                        echo "Choose Delete option:"
                        select opt in "Delete All" "Delete Row"
                        do
                            case $opt in
                                "Delete All")
                                    if [ "$(wc -l < "./$db_name/$tb_name")" -gt 0 ]
                                    then
                                        > "./$db_name/$tb_name"
                                        echo "All data deleted from table '$tb_name'."
                                    else
                                        echo "Table '$tb_name' is already empty."
                                    fi
                                    break
                                    ;;

                                "Delete Row")
                                    echo "Available columns in table '$tb_name':"
                                    awk -F: '{print NR ". " $1}' "./$db_name/metadata_$tb_name"

                                    while true
                                    do
                                        read -p "Enter column name: " colname
                                        if ! validate_name "$colname" || [[ "$colname" =~ [[:space:]] ]] 
                                        then
                                            echo "Invalid Column Name, Enter a Valid Name."
                                            continue
                                        fi
                                        
                                        # Check if the column exists in the metadata
                                        if ! grep -q "^$colname:" "./$db_name/metadata_$tb_name"
                                        then
                                            echo "Column '$colname' does not exist in table '$tb_name'."
                                            continue
                                        fi
                                        
                                        # Get the type of the column from the metadata file
                                        coltype=$(awk -F: -v colname="$colname" '$1 == colname {print $2}' "./$db_name/metadata_$tb_name")
                                        break
                                    done
                                    
                                    while true
                                    do
                                        read -p "Enter value of $colname to delete: " value

                                        # Check if the value exists in the table
                                        if ! grep -q "\<$value\>" "./$db_name/$tb_name"
                                        then
                                            echo "Value '$value' not found in table '$tb_name'."
                                            continue
                                        fi

                                        # Check if the value matches the column type
                                        case $coltype in
                                            int)
                                                if [[ ! "$value" =~ ^[0-9]+$ ]]
                                                then
                                                    echo "Invalid value. Expected an integer."
                                                    continue
                                                fi
                                                ;;
                                            str)
                                                if ! validate_name "$value" || [[ "$value" =~ [[:space:]] ]]
                                                then
                                                    echo "Invalid value. Enter a valid string."
                                                    continue
                                                fi
                                                ;;
                                            *)
                                                echo "Unknown column type '$coltype'."
                                                continue
                                                ;;
                                        esac
                                        break
                                    done

                                    # Delete rows based on specified field and value
                                    columns=$(awk -F ':' '{print $1}' "./$db_name/metadata_$tb_name")
                                    index=$(echo "$columns" | grep -wn "$colname" | cut -d: -f1)

                                    awk -F ':' -v col="$index" -v val="$value" '
                                        BEGIN { OFS=FS }
                                        { if ($col != val) print $0 } ' "./$db_name/$tb_name" > "./$db_name/$tb_name.tmp" && mv "./$db_name/$tb_name.tmp" "./$db_name/$tb_name"
                                    echo "Rows with '$colname = $value' deleted from table '$tb_name'."
                                    break
                                    ;;
                                *)
                                    echo "Invalid choice. Choose 1 or 2."
                                    ;;
                            esac
                        done
                        break
                    else
                        echo "Metadata or data file is empty for table $tb_name."
                        break
                    fi        
                else
                    echo "Table '$tb_name' not found! Enter a valid table name."
                fi
                ;;
            *)
                echo "Invalid input! Enter a valid table name."
                ;;
        esac
    done
}

# -------------------------------- Insert Table FN --------------------------------
insert_into_table() {
  echo "Available tables in $db_name"
  list_table 
  read -p "Enter table Name: " tb_name
  echo "Selected table: $tb_name"

  if [[ -f ./$db_name/$tb_name ]] && [[ -s ./$db_name/metadata_$selected_tb_name ]] 
  then
    record_values=()
    columns=($(cut -d ':' -f 1 ./$db_name/metadata_$tb_name))
    constraints=($(cut -d ':' -f 2 ./$db_name/metadata_$tb_name))
    primary_keys=($(cut -d ':' -f 3 ./$db_name/metadata_$tb_name))

    for (( i=0; i<${#columns[@]}; i++ ))
    do
      field="${columns[$i]}"
      while true
      do
        read -p "Enter $field Value: " value

        value=${value% }
        if [[ "${constraints[$i]}" == "int" ]]
        then
          if ! [[ "$value" =~ ^[0-9]+$ ]]
          then
            echo "Enter a valid number , shouldn't be empty or containing space or special character"
            continue
          fi

        elif [[ "${constraints[$i]}" == "str" ]]
        then
          if ! validate_name "$value" || [[ "$value" =~ [[:space:]] ]]
          then
            echo "Enter a valid string, shouldn't contain space or special character and shouldn't be an empty"
            continue
          fi
        fi

        if [[ "${primary_keys[$i]}" == "1" && "${constraints[$i]}" == "int" ]]
        then
          if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]
          then
            echo "Primary key value should be a positive non-zero integer."
            continue
          fi

          if grep -qw "$value" ./$db_name/$tb_name
          then
            echo "Primary key value already exists. Please enter a unique value."
            continue
          fi
        fi

        if [[ "${primary_keys[$i]}" == "1" && "${constraints[$i]}" == "str" ]]
        then
          if [[ -z "$value" ]] || [[ "$value" =~ [Nn][Uu][Ll][Ll] ]]
          then
            echo "String value cannot be null."
            continue
          fi

          if grep -qw "$value" ./$db_name/$tb_name
          then
            echo "Primary key value already exists. Please enter a unique value."
            continue
          fi
        fi

        break
      done

      record_values+=":$value"
    done

    echo ${record_values:1} >> ./$db_name/$tb_name
    echo "Data Entered Successfully"
  else
    echo "Data or metadata file does not exist or is not accessible."
  fi
}

# -------------------------------- Select Table FN --------------------------------
select_from_table(){
    echo "Choose the table you want to select from:"
    list_table
    while true
    do
        read -p "Please enter your choice: " selected_tb_name
        if validate_name "$selected_tb_name" && ! [[ "$selected_tb_name" =~ [[:space:]] ]] 
        then
            if [[ -f ./$db_name/$selected_tb_name ]] 
            then
                if [[ -s ./$db_name/metadata_$selected_tb_name ]] && [[ -s ./$db_name/$selected_tb_name ]]
                then
                    select choice in "Select * From $selected_tb_name" "Select Column From $selected_tb_name" "Select Row From $selected_tb_name" " Back "
                    do
                        case $REPLY in
                            1)
                                cat ./$db_name/$selected_tb_name
                                echo
                                ;;
                            2)
                                echo "Selecting a column from $selected_tb_name"
                                max_col=$(cut -d ':' -f 1  ./$db_name/metadata_$selected_tb_name | wc -l) 
                                while true
                                do
                                    echo "Available columns in $selected_tb_name:"
                                    cut -d ':' -f 1  ./$db_name/metadata_$selected_tb_name | cat -n
                                    read -p "Enter column number you want to select: " selected_col
                                    if ! [[ "$selected_col" =~ ^[0-9]+$ ]]
                                    then
                                        echo "Invalid input, enter a number."
                                        continue
                                    fi
                                    if [[ "$selected_col" -lt 1 || "$selected_col" -gt "$max_col" ]]
                                    then
                                        echo "Column number is out of range. Please select a column between 1 and $max_col."
                                        continue
                                    fi

                                    echo "Selected column $selected_col from $selected_tb_name:"
                                    cut -d ':' -f "$selected_col" ./$db_name/$selected_tb_name  
                                    echo "choose another choice"
                                    break
                                done
                                ;;
                            3)
                                echo "Selecting a column from $selected_tb_name"
                                max_col=$(cut -d ':' -f 1 ./$db_name/metadata_$selected_tb_name | wc -l) 
                                while true 
                                do
                                    echo "Available columns in $selected_tb_name:"
                                    cut -d ':' -f 1 ./$db_name/metadata_$selected_tb_name | cat -n
                                    read -p "Enter column number you want to select: " selected_col
                                    if ! [[ "$selected_col" =~ ^[0-9]+$ ]]
                                    then
                                        echo "Invalid input, enter a number."
                                        continue
                                    fi
                                    if [[ "$selected_col" -lt 1 || "$selected_col" -gt "$max_col" ]]
                                    then
                                        echo "Column number is out of range. Please select a column between 1 and $max_col."
                                        continue
                                    fi

                                    type=$(cat -n ./$db_name/metadata_$selected_tb_name | grep "^[[:space:]]*$selected_col" | cut -d ':' -f 2)
                                    read -p "Enter Value for column. Note: data type of column is $type: " selected_value

                                    if [[ "$type" == "str" ]]
                                    then 
                                        if ! validate_name "$selected_value" || [[ "$selected_value" =~ [[:space:]] ]]
                                        then
                                            echo "Enter a valid string, shouldn't contain space or special character and shouldn't be empty."
                                            continue
                                        fi
                                    elif [[ "$type" == "int" ]]
                                    then
                                        if ! [[ "$selected_value" =~ ^[0-9]+$ ]] 
                                        then
                                            echo "Enter a valid number, shouldn't be empty or containing space or special character."
                                            continue
                                        fi
                                    else 
                                        echo "Invalid input."
                                        continue
                                    fi  

                                    matched_record=$(awk -F ':' -v col="$selected_col" -v val="$selected_value" '$col == val {print $0}' "./$db_name/$selected_tb_name")
                                    if [ -n "$matched_record" ]
                                    then 
                                        echo "matched record is:"
                                        echo "$matched_record"
                                        echo "choose another choice"
                                        break
                                    else
                                        echo "no matched record existing"
                                        echo "choose another choice"
                                        break
                                    fi         
                                done
                                ;;
                            4) 
                                tabel_menu
                                ;;
                            *)
                                echo "Invalid option, please choose 1, 2, 3, or 4."
                                ;;
                        esac
                    done
                    break
                else
                    echo "Metadata or data file is empty for table $selected_tb_name."
                    break
                fi  
            else
                echo "Data file does not exist or is not accessible."
            fi
        else
            echo "Table name is invalid: it can't be a regex, be empty, or contain spaces."
        fi
    done
}

# -------------------------------- Update Table FN --------------------------------
update_table(){
    echo "Choose the table you want to update:"
    list_table
    while true
    do
        read -p "Please enter your choice: " updated_tb_name
        if validate_name "$updated_tb_name" && ! [[ "$updated_tb_name" =~ [[:space:]] ]]
        then
            if [[ -f ./$db_name/$updated_tb_name ]]
            then
                if [[ -s ./$db_name/metadata_$updated_tb_name ]] && [[ -s ./$db_name/$updated_tb_name ]]
                then
                    select choice in "Update by field in table $updated_tb_name" "Update Column in table $updated_tb_name" "Back"
                    do
                        case $REPLY in
                            1)
                                echo "Choose a column from $updated_tb_name"
                                max_col=$(cut -d ':' -f 1 ./$db_name/metadata_$updated_tb_name | wc -l) 
                                echo "Available columns in $updated_tb_name:"
                                cut -d ':' -f 1 ./$db_name/metadata_$updated_tb_name | cat -n
                                while true
                                do
                                    read -p "Enter column number you want to select: " updated_col

                                    if ! [[ "$updated_col" =~ ^[0-9]+$ ]]; then
                                        echo "Invalid input, enter a number."
                                        continue
                                    fi

                                    if [[ "$updated_col" -lt 1 || "$updated_col" -gt "$max_col" ]]; then
                                        echo "Column number is out of range. Please select a column between 1 and $max_col."
                                        continue
                                    fi
                                    
                                    type=$(cat -n ./$db_name/metadata_$updated_tb_name | grep "^[[:space:]]*$updated_col" | cut -d ':' -f 2)
                                    pk=$(cat -n ./$db_name/metadata_$updated_tb_name | grep "^[[:space:]]*$updated_col" | cut -d ':' -f 3)

                                    while true
                                    do
                                        read -p "Enter value for the column. Note: data type of column is $type: " oldvalue

                                        if [[ "$type" == "str" ]]; then 
                                            if ! validate_name "$oldvalue" || [[ "$oldvalue" =~ [[:space:]] ]]; then
                                                echo "Enter a valid string, shouldn't contain space or special character and shouldn't be empty."
                                                continue
                                            fi
                                        elif [[ "$type" == "int" ]]; then
                                            if ! [[ "$oldvalue" =~ ^[0-9]+$ ]]; then
                                                echo "Enter a valid number, shouldn't be empty or containing space or special character."
                                                continue
                                            fi
                                        else 
                                            echo "Invalid input."
                                            continue
                                        fi   
                                    break
                                    done 

                                    lineunm=$(grep -c "$oldvalue" ./$db_name/$updated_tb_name)

                                    if [ "$lineunm" -lt 1 ]; then 
                                        echo "The value you entered doesn't exist in the table."
                                    else 
                                        while true; do
                                            read -p "Enter the new value of $updated_col: " newvalue

                                            if [[ "$type" == "str" ]]; then 
                                            
                                                if ! validate_name "$newvalue" || [[ "$newvalue" =~ [[:space:]] ]]; then
                                                    echo "Enter a valid string, shouldn't contain space or special character and shouldn't be empty."
                                                    continue
                                                fi
                                            elif [[ "$type" == "int" ]]; then 
                                            
                                                if ! [[ "$newvalue" =~ ^[0-9]+$ ]]; then
                                                    echo "Enter a valid number, shouldn't be empty or containing space or special character."
                                                    continue
                                                fi
                                            else
                                                echo "Invalid data type. Please enter 'str' or 'int'."
                                                continue
                                            fi

                                            if [[ "$pk" == "1" ]]; then
                                                if [[ "$oldvalue" == "$newvalue" ]]; then
                                                echo "No change detected in primary key value. Update ignored."
                                                continue
                                                fi
                                                if [[ "$type" == "int" ]]; then
                                                    if ! [[ "$newvalue" =~ ^[1-9][0-9]*$ ]]; then 
                                                    echo "Primary key value should be a positive non-zero integer."
                                                    continue
                                                    fi
                                                elif [[ "$type" == "str" ]]; then
                                                    if [[ -z "$newvalue" ]] || [[ "$newvalue" =~ [Nn][Uu][Ll][Ll] ]]; then 
                                                    echo "String value cannot be null."
                                                    continue
                                                    fi
                                                fi
                                                if grep -qw "$newvalue" ./$db_name/$updated_tb_name; then
                                                    echo "Primary key value already exists. Please enter a unique value."
                                                    continue
                                                fi

                                            fi

                                            sed -i "s/$oldvalue/$newvalue/" ./$db_name/$updated_tb_name
                                            echo "Record updated successfully"

                                            break
                                        done
                                    fi
                                    echo "select another choice from pdate list"
                                    break
                                done
                                ;;
                            2)
                                echo "Choose a column from $updated_tb_name"
                                max_col=$(cut -d ':' -f 1 ./$db_name/metadata_$updated_tb_name | wc -l) 
                                echo "Available columns in $updated_tb_name:"
                                cut -d ':' -f 1 ./$db_name/metadata_$updated_tb_name | cat -n
                                while true; do
                                    
                                    read -p "Enter column number you want to update: " updated_col

                                    if ! [[ "$updated_col" =~ ^[0-9]+$ ]]; then
                                        echo "Invalid input, enter a number."
                                        continue
                                    fi

                                    if [[ "$updated_col" -lt 1 || "$updated_col" -gt "$max_col" ]]; then
                                        echo "Column number is out of range. Please select a column between 1 and $max_col."
                                        continue
                                    fi
                                    
                                    type=$(cat -n ./$db_name/metadata_$updated_tb_name | grep "^[[:space:]]*$updated_col" | cut -d ':' -f 2)
                                    pk=$(cat -n ./$db_name/metadata_$updated_tb_name | grep "^[[:space:]]*$updated_col" | cut -d ':' -f 3)

                                    if [[ "$pk" == "1" ]]; then
                                        echo "Primary key column cannot be updated."
                                        break
                                    fi

                                    while true
                                    do
                                        echo "Warning! All Column data will be Updated..."
                                        read -p "Enter new value for the column. Note: data type of column is $type: " newvalue

                                        if [[ "$type" == "str" ]]; then 
                                            if ! validate_name "$newvalue" || [[ "$newvalue" =~ [[:space:]] ]]; then
                                                echo "Enter a valid string, shouldn't contain space or special character and shouldn't be empty."
                                                continue
                                            fi
                                        elif [[ "$type" == "int" ]]; then
                                            if ! [[ "$newvalue" =~ ^[0-9]+$ ]]; then
                                                echo "Enter a valid number, shouldn't be empty or containing space or special character."
                                                continue
                                            fi
                                        else 
                                            echo "Invalid input."
                                            continue
                                        fi   
                                        break
                                    done 

                                    awk -v col="$updated_col" -v value="$newvalue" '
                                        BEGIN{ FS=OFS=":" }
                                        { $col=value; print } ' "./$db_name/$updated_tb_name" > "./$db_name/$updated_tb_name.tmp" && mv "./$db_name/$updated_tb_name.tmp" "./$db_name/$updated_tb_name"

                                    echo "All Column Data Updated Successfully!"
                                    break
                                done
                                ;;
                            3)
                                tabel_menu
                                ;;
                            *)
                                echo "Invalid option, please choose 1, 2, or 3."
                                ;;
                        esac
                    done
                    break
                else
                    echo "Metadata or data file is empty for table $updated_tb_name."
                    break
                fi
            else
                echo "Data file does not exist or is not accessible for table $updated_tb_name."
                break
            fi
        else
            echo "Table name is invalid: it can't be a regex, be empty, or contain spaces."
        fi
    done
}

# -------------------------------- Back to Main Menu FN ---------------------------
back_to_menu(){
    ./dbms.sh main_menu
    exit
}

table_menu
