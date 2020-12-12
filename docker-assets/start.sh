#!/bin/bash
base_dir="$(dirname "$0")"

# -------------------
# -- Helper functions

function ini_sec() {
  /eressea/server/bin/inifile /data/game-1/eressea.ini add $1
}

function ini_add() {
  /eressea/server/bin/inifile /data/game-1/eressea.ini add $1:$2 $3
}

function ini_get() {
  /eressea/server/bin/inifile /data/game-1/eressea.ini get $1:$2
}

function get_turn() {
    turn=0
    [ -e /data/game-1/turn ] && turn=$(cat /data/game-1/turn)
    [ -z $turn ] && turn=0
}

# -----------------
# -- Main-commands

cmd_help() {
    usage() {
        echo ""
        echo "Usage: $0 COMMAND [-h] [arguments]"
        echo ""
        echo "supported COMMANDs:"
        echo " addpwd             adds password in newfactions"
        echo " bash               start a bash shell"
        echo " generate           generate eressea.ini and all relevant files"
        echo " help               show this help"
        echo " mail               process incoming e-mail"
        echo " map                generate/edit game map"
        echo " run                execute Eressea game turn"
        echo " shutdown           remove temporaray Eressea environment"
        echo " startup            create temporaray Eressea environment which is necessary for scripts"
        echo ""
        echo "arguments:"
        echo "-h ... show more details of command"
        exit 2
    }
    usage
}

cmd_bash() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Starts an interactive bash shell."
        echo "Usage: $0 bash [-h] [-n]"
        echo "-h ... show this help"
        echo "-n ... start a 'naked' bash, which means eressea is not setup"
        echo "       can be done later by invoking '/eressea/start.sh startup'"
        echo "       before you exit the shell, call '/eressea/start.sh shutdown'"
        exit 2
    }

    args=$(getopt --name shutdown -o hn -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    naked=0
    while :; do
        case "$1" in
            -h) usage  ; shift ;;
            -n) naked=1; shift ;;
            --) shift  ; break ;;
        esac
    done

    [ ${naked} == 0 ] && cmd_startup || echo "started bash without any Eressea environment setup"
    /bin/bash
    [ ${naked} == 0 ] && cmd_shutdown
}

cmd_startup() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Setup an environment which enables Eressea to find a runtime environment where all scripts are functional."
        echo "Usage: $0 startup [-h]"
        echo "-h ... show this help"
        exit 2
    }

    args=$(getopt --name shutdown -o h -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    while :; do
        case "$1" in
            -h) usage ; shift ;;
            --) shift ; break ;;
        esac
    done

    mkdir -p /data/config
    mkdir -p /data/log

    ln -sf /data/config/muttrc ~/.muttrc
    ln -sf /data/config/fetchmailrc ~/.fetchmailrc
    ln -sf /data/config/procmailrc ~/.procmailrc

    ln -sf /eressea/server /data/server
    ln -sf /eressea/orders-php /data/orders-php

    mkdir -p /data/game-1
    mkdir -p /data/game-1/backup
    ln -sf /eressea/server/scripts/config.lua /data/game-1/config.lua
    ln -sf /eressea/server/bin/eressea /data/game-1/eressea
    ln -sf /eressea/server/scripts/reports.lua /data/game-1/reports.lua
    ln -sf /eressea/server/scripts/run-turn.lua /data/game-1/run-turn.lua

    mkdir -p /eressea/server/etc
    [ -e /eressea/server/etc/report-mail.de.txt ] && rm -f /eressea/server/etc/report-mail.de.txt
    [ -e /eressea/server/etc/report-mail.en.txt ] && rm -f /eressea/server/etc/report-mail.en.txt
    [ -e /eressea/server/etc/report-mail.txt ] && rm -f /eressea/server/etc/report-mail.txt
    ln -sf /data/config/report-mail.de.txt /eressea/server/etc/report-mail.de.txt
    ln -sf /data/config/report-mail.en.txt /eressea/server/etc/report-mail.en.txt
    ln -sf /data/config/report-mail.de.txt /eressea/server/etc/report-mail.txt

    cd /data/game-1
    echo "Eressea environment setup complete"
}

cmd_shutdown() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Removes temporary Eressea environment from mapped /data folder."
        echo "Usage: $0 shutdown [-h]"
        echo "-h ... show this help"
        exit 2
    }

    args=$(getopt --name shutdown -o h -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    while :; do
        case "$1" in
            -h) usage ; shift ;;
            --) shift ; break ;;
        esac
    done

    [ -e /data/game-1/config.lua ] && rm /data/game-1/config.lua
    [ -e /data/game-1/eressea ] && rm /data/game-1/eressea
    [ -e /data/game-1/reports.lua ] && rm /data/game-1/reports.lua
    [ -e /data/game-1/run-turn.lua ] && rm /data/game-1/run-turn.lua

    [ -e /data/server ] && rm /data/server
    [ -e /data/orders-php ] && rm /data/orders-php

    [ -e ~/.muttrc ] && rm -f ~/.muttrc
    [ -e ~/.fetchmailrc ] && rm -f ~/.fetchmailrc
    [ -e ~/.procmailrc ] && rm -f ~/.procmailrc

    [ -e /data/config/logrotate ] && logrotate /data/config/logrotate

    echo "Eressea environment successfully removed"
}

cmd_generate() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Generates eressea.ini file and all other necessary files/folders needed by this Docker container."
        echo "Usage: $0 generate [options]"
        echo ""
        echo "General option:"
        echo "-f   force generating of files - delete will be done without prompt!"
        echo "-g   generate all other necessary files and folders (values are defined by eressea.ini and mail.ini)"
        echo "-h   show this help"
        echo "-i   generate eressea.ini and mail.ini file"
        echo ""
        echo "If eressea.ini is not available, option -i is mandatory. All of the following options are also necessray:"
        echo "  --from <email>           e-mail address Eressea postbox"
        echo "  --imap_server <addr>     IMAP server address. If not provided, value of smtp_server is used."
        echo "  --imap_user <user>       user for IMAP server. If not provided, value of smtp_user is used."
        echo "  --imap_pass <password>   password of IMAP user. If not provided, value of smtp_pass is used."
        echo "  --smtp_server <addr>     SMTP server address. If not provided, value of imap_server is used."
        echo "  --smtp_user <user>       user for SMTP server. If not provided, value of imap_user is used."
        echo "  --smtp_pass <password>   password of SMTP user. If not provided, value of imap_pass is used."
        echo ""
        echo "  Optional:"
        echo "  --game_name <name>   name of self hosted Eressea game. Default=MyEressea"
        echo "  --realname name>     real name used for e-Mails. Default=Game Server <game_name>"
        echo "  --smtp_port <port>   port of SMTP server, Default=587"
        echo "  --imap_port <port>   port of IMAP server, Default=993"
        echo "  --rules <ruleset>    ruleset, Defaule=e3"
        exit 2
    }

    args=$(getopt --name generate -o fghi --long game_name:,from:,realname:,smtp_server:,smtp_port:,smtp_user:,smtp_pass:,imap_server:,imap_port:,imap_user:,imap_pass:,rules: -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    force=0
    do_gen=0
    do_ini=0
    game_name="MyEressea"
    imap_port=993
    smtp_port=587
    rules="e3"

    while :; do
        case "$1" in
            -f)            force=1          ; shift   ;;
            -g)            do_gen=1         ; shift   ;;
            -h)            usage            ; shift   ;;
            -i)            do_ini=1         ; shift   ;;
            --game_name)   game_name="$2"   ; shift 2 ;;
            --from)        from="$2"        ; shift 2 ;;
            --realname)    realname="$2"    ; shift 2 ;;
            --smtp_server) smtp_server="$2" ; shift 2 ;;
            --smtp_port)   smtp_port="$2"   ; shift 2 ;;
            --smtp_user)   smtp_user="$2"   ; shift 2 ;;
            --smtp_pass)   smtp_pass="$2"   ; shift 2 ;;
            --imap_server) imap_server="$2" ; shift 2 ;;
            --imap_port)   imap_port="$2"   ; shift 2 ;;
            --imap_user)   imap_user="$2"   ; shift 2 ;;
            --imap_pass)   imap_pass="$2"   ; shift 2 ;;
            --rules)       rules="$2"       ; shift 2 ;;
            --)            shift            ; break   ;;
        esac
    done

    if [ $do_ini == 1 ]; then
        mkdir -p /data/game-1
        [ -e /data/game-1/eressea.ini ] && [ $force == 0 ] && usage "eressea.ini already exists. Add option -f"

        [ -z "$imap_server" ] && [ -n "$smtp_server" ] && imap_server=$smtp_server
        [ -z "$imap_user" ] && [ -n "$smtp_user" ] && imap_user=$smtp_user
        [ -z "$imap_pass" ] && [ -n "$smtp_pass" ] && imap_pass=$smtp_pass

        [ -z "$smtp_server" ] && [ -n "$imap_server" ] && smtp_server=$imap_server
        [ -z "$smtp_user" ] && [ -n "$imap_user" ] && smtp_user=$imap_user
        [ -z "$smtp_pass" ] && [ -n "$imap_pass" ] && smtp_pass=$imap_pass

        [ -z "$realname" ] && realname="Game Server ${game_name}"

        [ -z "$game_name" ] || [ -z "$from" ] || [ -z "$realname" ] || [ -z "$rules" ] || \
        [ -z "$smtp_server" ] || [ -z "$smtp_port" ] || [ -z "$smtp_user" ] || [ -z "$smtp_pass" ] || \
        [ -z "$imap_server" ] || [ -z "$imap_port" ] || [ -z "$imap_user" ] || [ -z "$imap_pass" ] && \
          usage "not all options relevant for eressea.ini were provided"

        [ -e /data/game-1/eressea.ini ] && rm -f /data/game-1/eressea.ini
        touch /data/game-1/eressea.ini

        ini_sec game
        ini_add game locales de,en
        ini_add game id 1
        ini_add game start 0
        ini_add game email $from
        ini_add game name $game_name
        ini_add game seed `shuf -i 0-9999 -n1`
        ini_add game dbname eressea.db
        ini_add game dbswap :memory:
        ini_add game mailcmd `echo "print '$game_name'.upper()" | python`
        ini_sec lua
        ini_add lua install /data/server
        ini_add lua paths /data/server/scripts:/data/server/lunit
        ini_add lua rules $rules 
        echo "eressea.ini generated"

        [ -e /data/config/mail.ini ] && rm -f /data/config/mail.ini
        mkdir -p /data/config
        echo "[smtp]" > /data/config/mail.ini
        echo "server = $smtp_server" >> /data/config/mail.ini
        echo "port = $smtp_port" >> /data/config/mail.ini
        echo "user = $smtp_user" >> /data/config/mail.ini
        echo "pass = $smtp_pass" >> /data/config/mail.ini
        echo "[imap]" >> /data/config/mail.ini
        echo "server = $imap_server" >> /data/config/mail.ini
        echo "port = $imap_port" >> /data/config/mail.ini
        echo "user = $imap_user" >> /data/config/mail.ini
        echo "pass = $imap_pass" >> /data/config/mail.ini
        echo "[general]" >> /data/config/mail.ini
        echo "realname = $realname" >> /data/config/mail.ini
        echo "mail.ini generated"
    fi

    if [ $do_gen == 1 ]; then
        [ ! -e /data/game-1/eressea.ini ] && usage "eressea.ini missing. Use option -i"

        if [ $force == 1 ]; then
            echo "existing game data deleted"
            for node in /data/game-1/*
            do
                [ $node == "/data/game-1/eressea.ini" ] && continue
                [ -d $node ] && rm -rf $node || rm -f $node 
            done;
        else 
            echo "existing game data is not touched. Missing files are recreated"
        fi

        mkdir -p /data/config
        tmpfile=$(mktemp ini.XXX)
        cat /data/game-1/eressea.ini > $tmpfile
        cat /data/config/mail.ini >> $tmpfile

        [ -e /data/config/fetchmailrc ] && [ $force == 1 ] && rm -f /data/config/fetchmailrc
        [ ! -e /data/config/fetchmailrc ] && j2 -f ini /eressea/template-config/fetchmailrc $tmpfile > /data/config/fetchmailrc
        chmod 700 /data/config/fetchmailrc

        [ -e /data/config/procmailrc ] && [ $force == 1 ] && rm -f /data/config/procmailrc
        [ ! -e /data/config/procmailrc ] && j2 -f ini /eressea/template-config/procmailrc $tmpfile > /data/config/procmailrc

        [ -e /data/config/muttrc ] && [ $force == 1 ] && rm -f /data/config/muttrc
        [ ! -e /data/config/muttrc ] && j2 -f ini /eressea/template-config/muttrc $tmpfile > /data/config/muttrc

        [ -e /data/config/logrotate ] && [ $force == 1 ] && rm -f /data/config/logrotate
        [ ! -e /data/config/logrotate ] && cp /eressea/template-config/logrotate /data/config/logrotate

        [ -e /data/config/report-mail.de.txt ] && [ $force == 1 ] && rm -f /data/config/report-mail.de.txt
        [ ! -e /data/config/report-mail.de.txt ] && cp /eressea/template-mail/report-mail.de.txt /data/config/report-mail.de.txt

        [ -e /data/config/report-mail.en.txt ] && [ $force == 1 ] && rm -f /data/config/report-mail.en.txt
        [ ! -e /data/config/report-mail.en.txt ] && cp /eressea/template-mail/report-mail.en.txt /data/config/report-mail.en.txt

        rm -f $tmpfile

        mkdir -p /data/mail/cache
        mkdir -p /data/mail/postbox/inbox/{cur,new,tmp}
        mkdir -p /data/mail/postbox/sent/{cur,new,tmp}
        mkdir -p /data/mail/postbox/draft/{cur,new,tmp}
        mkdir -p /data/mail/certificates

        mkdir -p /data/game-1/data
        mkdir -p /data/game-1/reports
        mkdir -p /data/game-1/backup
        [ ! -e /data/game-1/newfactions ] && touch /data/game-1/newfactions
        [ ! -e /data/game-1/turn ] && echo 0 > /data/game-1/turn

        echo "all basic game files generated"
        echo "next step would be to create a new game file / map; therefore use '$0 map -h'"
    fi

    [ $do_gen == 0 ] && [ $do_ini == 0 ] && usage "nothing to generate. Use option -i or -g"
}

cmd_map() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Generate or edit Eressea map."
        echo "Usage: $0 map [options]"
        echo "-h ... show this help"
        echo "-n ... generate new map. If map already exists, it will be overwritten!"
        echo "-w ... width of new map - only relevant together with -n"
        echo "-e ... height of new map - only relevant together with -n"
        echo "-t ... turn"
        echo "-s ... save map when editor is closed"
        exit 2
    }

    args=$(getopt --name shutdown -o hnw:e:t:s -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    create_new=0
    export ERESSEA_MAP_WIDTH=60
    export ERESSEA_MAP_HEIGHT=40
    get_turn
    save=0

    while :; do
        case "$1" in
            -h) usage                ; shift   ;;
            -n) create_new=1         ; shift   ;;
            -w) ERESSEA_MAP_WIDTH=$2 ; shift 2 ;;
            -e) ERESSEA_MAP_HEIGHT=$2; shift 2 ;;
            -t) turn=$2              ; shift 2 ;;
            -s) save=1               ; shift   ;;
            --) shift                ; break   ;;
        esac
    done

    cmd_startup

    if [ $create_new == 1 ]; then
        ini_sec game
        ini_add game seed `shuf -i 0-9999 -n1`

        ./eressea -v 0 -t $turn /eressea/lua-scripts/newgame.lua
        echo "created new game map with size ${ERESSEA_MAP_WIDTH}x${ERESSEA_MAP_HEIGHT}"
    fi

    if [ $save == 1 ]; then 
        ./eressea -v 0 -t $turn /eressea/lua-scripts/modifymap.lua 
    else
        ./eressea -v 0 -t $turn /data/server/scripts/map.lua
    fi

    cmd_shutdown
}

cmd_addpwd() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "In file 'newfactions' on lines without password a secure one is generated and inserted."
        echo "Usage: $0 addpwd [options]"
        echo "-f ... force usage of new password"
        echo "-h ... show this help"
        exit 2
    }

    args=$(getopt --name shutdown -o hf -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    force=0
    while :; do
        case "$1" in
            -h) usage  ; shift ;;
            -f) force=1; shift ;;
            --) shift  ; break ;;
        esac
    done

    [ ! -e "/data/game-1/newfactions" ] && echo "file newfactions does not exist" && exit

    tmpfile=$(mktemp newfactions.XXX) 
    touch $tmpfile

    while IFS=" " read -r email race language pass alliance
    do
        [ -z "$email" ] && continue
        echo "found player $email ($race), language $language`[ -n "$alliance" ] && echo " in alliance with $alliance"`"
        if [ -z "$pass" ] || [ $force == 1 ]; then
            new_pass="`pwgen -c -n -y 8 1`"
            echo "  new password $new_pass`[ -n "$pass" ] && echo " replaces former password $pass"`"
        else
            new_pass=$pass
            echo "  uses password $pass"
        fi
        echo "$email $race $language $new_pass`[ -n "$alliance" ] && echo " $alliance"`" >> $tmpfile
    done < /data/game-1/newfactions

    rm -f /data/game-1/newfactions
    mv $tmpfile /data/game-1/newfactions
}

cmd_mail() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Process incoming e-mails"
        echo "Usage: $0 mail [options]"
        echo "-c ... check orders and send email to player"
        echo "-f ... fetch mail from server and pre-process them"
        echo "-h ... show this help"
        exit 2
    }

    args=$(getopt --name shutdown -o hcf -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    fetch=0
    check=0
    while :; do
        case "$1" in
            -f) fetch=1; shift ;;
            -c) check=1; shift ;;
            -h) usage  ; shift ;;
            --) shift  ; break ;;
        esac
    done

    [ $(expr $fetch + $check) == 0 ] && usage "either option -f or -c is necessary"

    cmd_startup

    if [ $fetch == 1 ]; then
        touch /data/log/fetchmail.log
        fetchmail >> /data/log/fetchmail.log 2>&1
    fi

    if [ $check == 1 ]; then
        mkdir -p /data/game-1/orders.dir
        rules="$(ini_get lua rules)"
        /data/orders-php/check-orders.sh 1 $rules
    fi

    cmd_shutdown
}

cmd_run() {
    usage() {
        [ -n "$1" ] && echo -e "\n$1"
        echo ""
        echo "Execute next game turn"
        echo "Usage: $0 rung [options]"
        echo "-h ... show this help"
        exit 2
    }

    args=$(getopt --name shutdown -o h -- "$@")

    if [ $? != 0 ]; then
        usage 
        exit
    fi
    eval set -- "$args"

    while :; do
        case "$1" in
            -h) usage  ; shift  ;;
            --) shift  ; break  ;;
        esac
    done

    cmd_startup
    mkdir -p $HOME/log
    mkdir -p /data/game-1/orders.dir        
    touch /data/log/eressea.cron.log
    ln -sf /data/log/eressea.cron.log $HOME/log/eressea.cron.log

    get_turn
    enable_empty_orders="no"
    [ "$turn" == "0" ] && enable_empty_orders="yes"
    /eressea/run-eressea.sh 1     

    cmd_shutdown
}

# ----------------
# -- Main function

COMMAND="$1"
shift

case $COMMAND in
    "help" | "startup" | "shutdown" | "bash" | "generate" | "map" | "addpwd" | "mail" | "run") eval cmd_$COMMAND "$@" ;;
    *) cmd_help ;;
esac
