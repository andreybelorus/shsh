#!/bin/bash

. ./settings.sh

[ -d /tmp/shsh ] || mkdir /tmp/shsh
find /tmp/shsh -mmin +${session_lifetime:-5} -delete                #
[ "$(ls /tmp/shsh | wc -w)" -gt "${max_sessionS:-50}" ] && exit 1   # AntiDDOS

sql="mysql -n -s -u $dbuser -p$dbpass -h $dbhost $dbname -e"

declare -A cookies                                                  # Parse cookies
for cookie in $(echo $HTTP_COOKIE | sed 's/; /\n/'); do
    cookies[$(echo $cookie | awk -F "=" '{print $1}')]=$(echo $cookie | awk -F "=" '{print $2}')
done

declare -A queries                                                  # Parse parameters
for query in $(echo $QUERY_STRING | sed 's/\&/\n/'); do
    queries[$(echo $query | awk -F "=" '{print $1}')]=$(echo $query | awk -F "=" '{print $2}')
done

if [ -n "${cookies["session"]}" -a ! -f /tmp/shsh/"${cookies["session"]}".session ]; then
    printf "Set-Cookie: session=\n"
    printf "Location: /sh/test\n\n"
elif [ -n "${cookies["session"]}" -a "x${queries["start"]}" = "xtrue" ] && 
   [ -f /tmp/shsh/"${cookies["session"]}".session ]; then
    sessionfile=/tmp/shsh/${cookies['session']}.session
    count=0
    for id in $($sql "SELECT id FROM Questions" 2>&-); do 
        ids[$(( count++ ))]=$id
    done
    
    i=1
    echo $(shuf -i 1-$(($count - 1)) -n 1) >> $sessionfile
    while [ $i -lt ${question_count:-10} ]; do
        rand=$(shuf -i 1-$(($count - 1)) -n 1)
        for x in $(cat $sessionfile); do
            [ $x -eq ${ids[$rand]} ] && continue 2
        done
        echo ${ids[$rand]} >> $sessionfile
        (( i++ ))      
    done
    printf "Location: /sh/test?qu=0&answer=0\n\n"
elif [ -n "${cookies["session"]}" -a -f /tmp/shsh/"${cookies["session"]}".session -a -n "${queries["qu"]}" ] && 
     expr ${queries[answer]} + 1 >> /dev/null ; then                 # Make sure that "answer" is integer intead of "DROP TABLE"
    sessionfile=/tmp/shsh/${cookies['session']}.session
   
    if [ "x${queries['qu']}" != "x0" ]; then
        correct=$($sql "SELECT correct FROM Answers WHERE id=${queries['answer']}" 2>&-)
        [ "$correct" = "1" ] && sed -i "s/^${queries[qu]}$/\+/" $sessionfile || sed -i "s/^${queries[qu]}$/-/" $sessionfile 
    fi

    i=0
    lines=$(cat $sessionfile | wc -l)
    for qid in $(cat $sessionfile); do
        if [ "$(( ++i ))" -ge "$lines" ] && [ "x$qid" = 'x+' -o "x$qid" = 'x-' ] ; then
            pluses=0
            for res in $(cat $sessionfile); do
                [ "x$res" = "x+" ] && (( pluses++ ))
            done
            result=$(bc <<< "scale=2; $pluses / $lines * 100")
            [ ${#result} -gt 3 ] && result=${result::-3} || result=0
            rm $sessionfile
            printf "Set-Cookie: session=\n"
            printf "Content-type: text/html\n\n"
            cat view/header.html
            printf "\t\t\t\t<h1>Results</h1> \n\
                    <p>Your score: ${result} %%</p> \n\
                    <p>Correct answers: $pluses<p> \n\
                    <p>Total questions: $lines</p> \n\
                    <form action=/sh/test> \n\
                        <input type=\"submit\" class=\"btn btn-primary\" value=\"Try again\"> \n\
                    </form>"
            cat view/footer.html
            exit 0
        fi
        [ "x$qid" = 'x+' ] || [ "x$qid" = 'x-' ] && continue
        question=$($sql "SELECT quest FROM Questions WHERE id=$qid" 2>&-)
        break
    done

    printf "Content-type: text/html\n\n"
    cat view/header.html
    printf "\t\t\t<h1>Question $i out of $lines </h1> \n\
            <form action=/sh/test> \n"
    echo -ne "\t\t\t"
    echo "<b>${question}</b>"
    printf "\t\t\t<input type=\"hidden\" name=\"qu\" value=\"$qid\"> \n"

    $sql "SELECT id, ans FROM Answers WHERE quest=$qid ORDER BY RAND()" 2>&- | while read line
    do
        aid=$(echo $line | awk '{print $1}')
        answer=$(echo $line | sed "s/$aid//")
        printf "\t\t\t<div class=\"radio\"> \n\
                    <label> \n\
                        <input type=\"radio\" name=\"answer\" value=\"${aid}\" id=\"optionsRadios2\" > \n"
                        echo -ne "\t\t\t\t"
                        echo "${answer}"
        printf "\t\t\t</label>\n\t\t\t</div> \n"
    done
    printf "\t\t\t<input type=\"submit\" class=\"btn btn-primary\" value=\"Send\"> \n\
            </form>"
    cat view/footer.html
else 
    [ -n "x${cookies["session"]}" -a -f /tmp/shsh/"${cookies["session"]}".session ] && rm /tmp/shsh/"${cookies["session"]}".session 
    session=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    sessionfile=/tmp/shsh/${session}.session
    touch $sessionfile
    printf "Set-Cookie: session=$session\n"
    printf "Content-type: text/html\n\n"
    cat view/header.html
    printf "\t\t\t<h1>Find out your Unix shell skills.</h1> \n\
            <br/><b>There will be ${question_count:-10} simple questions.</b>\n\
            <p><form action=/sh/test> \n\
            <input type=\"hidden\" name=\"start\" value=\"true\"> \n\
            <input type=\"submit\" class=\"btn btn-primary\" value=\"Start test\"> \n\
            </form>"
    cat view/footer.html
fi
