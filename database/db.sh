#!/bin/sh

. ../settings.sh

dbhost="127.0.0.1"

drop() {
    mysql -u root -p${dbrootpass} -h ${dbhost} -e "DROP DATABASE ${dbname}"
}

create() {
    mysql -u root -p${dbrootpass} -h ${dbhost} -e "\
        CREATE DATABASE IF NOT EXISTS ${dbname}; \
        GRANT SELECT ON ${dbname}.* TO \"${dbuser}\"@\"%\" IDENTIFIED BY \"${dbpass}\"; \
        FLUSH PRIVILEGES;"
        mysql -u root -p${dbrootpass} -h ${dbhost} ${dbname} < schema.sql
}

setup() {
    while read block; do
        if [ "x$(echo block | cut -c1)" = "x#" ]; then
            continue
        elif [ "x$block" = "x" ]; then
            echo $BLOCK | while read line; do
                TYPE=$(echo $line | cut -c1-3) 
                if [ "x$TYPE" = "xqu:" ]; then
                    QUESTION=$(echo $line | cut -c4-)
                    mysql -u root -p${dbrootpass} -h ${dbhost} ${dbname} -e " \
                        INSERT INTO Questions (quest) VALUES ('${QUESTION}');"
                elif [ "x$(echo $TYPE | cut -c1)" = "xa" ]; then
                    ANSWER=$(echo $line | cut -c4-)  
                    CORRECT=$(echo $line | cut -c2)  
                    mysql -u root -p${dbrootpass} -h ${dbhost} ${dbname} -e " \
                        INSERT INTO Answers (quest, ans, correct) VALUES ((SELECT id FROM Questions WHERE quest='${QUESTION}'), '${ANSWER}', ${CORRECT});"
                fi
            done
            BLOCK=""
        fi
        BLOCK=${BLOCK}"\n"${block}
    done <../questions.txt
}

drop
create
setup
