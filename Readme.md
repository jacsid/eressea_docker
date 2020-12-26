# Eressea Docker
This Docker image will provide a full [Eressea](https://wiki.eressea.de/index.php/Hauptseite) installation to host an own game. 
More details about Eressea find on
- their [homepage](https://www.eressea.de/)
- in [wiki](https://wiki.eressea.de/index.php/Hauptseite) you find the game rules and a lot of other information
- and finally the source code, which is hosted on [GitHub](https://github.com/eressea)

The Dockerfile is available on
* [GitHub](https://github.com/jacsid/eressea_docker)
* [Private Repository](https://git.jacs-home.eu/juergen/eressea-docker)

## Volumes
By default, the image expects a single volume, located at `/data`. It will hold
* configuration files
* log files
* e-mail
* game data
* game data backups

## General 
This image provides a command line interface. To see all possible commands, run the `help` command:

```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea help
```

## Initial setup

### Initiailze volume
The empty `/data` volume needs to be initialzed. Without this step, none of the provided commands will work.

First, it is necessary to create the ini files:
```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea generate -i \
    --game_name=MyOwnEressea \
    --rules=e3 \
    --from=gameserver@myhoster.com \
    --realname="MyOwnEressea\ Game\ Server" \
    --imap_server=imap.myhoster.com \
    --imap_user=imapuser \
    --imap_pass=imappwd \
    --imap_port=993 \
    --smtp_server=smtp.myhoster.com \
    --smtp_user=smtpuser \
    --smtp_pass=smtppwd \
    --smtp_port=587
```
To get further details, call `generate` command with option `-h`

Afterwards, create the relevant game folders:
```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea generate -g
```

It is possible to combine both steps into one call by combining options `-i` and `-g`.

### Initialize game
Now in `/data/game-1` a file called `newfactions` is available. Enter all players who will join the game. Each player goes into a seperate line:
```
test.player@hotmail.com elf de
seppl@gmx.at orc en
[...]
```
The entries, separated by one white space character, are email, race, and language. The language is either "de" for German or "en" for English. This file is read automatically when the game editor starts (see also [GM-Guide](https://github.com/eressea/server/wiki/GM-Guide#adding-players) on Eressea [GitHub](https://github.com/eressea/server) wiki).

Now create the game map and seed the new players.
```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea map -n -w 50 -e 50 -s
```
This command will create a new 50x50 map (option `-n`, `-w`, `-e`). In general, the `map` command opens the game map editor. With the option `-s` it will automatically be saved, when you exit the editor with key `Q`.
On the game map, seed all new players via key `s`. To see where other players are located, press `h` followed by `p`.

### Send first game reports
After players were seeded to the map, run the first game turn which sends the intial reports to the players.

```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea run
```

## Day by day use
The players send their turn commands via email (see [initialize](#initiailze-volume) chapter above). Use the command `mail` to process incoming e-mails.

Please note, that only Eressea mails are processed, **all other e-mails are deleted from server**!

You maybe want to fetch e-mails (option `-f`) during the day and once a night you check the new game orders (option `-c`). But it is also possible to combine the options in one call. Use e.g. `cron` to automatize the calls.

```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea mail -f -c
```

And somewhen the next game turn is processed with command `run`:

```
docker run -it --rm \
    -v /path/to/my/local/eressea/folder:/data \
    jacsid/eressea run
```
