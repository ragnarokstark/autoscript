#!/bin/bash
######################################################
# Basic settings
######################################################

# server base directory
RAGNAROK_DIR=/rAthena

# mysql database settings
MYSQL_ROOT_PW="leira27"
MYSQL_RAGNAROK_DB="ragnarok"
MYSQL_RAGNAROK_USER="starkro"
MYSQL_RAGNAROK_PW="leira27"

# Official server name
SERVER_NAME="StarkRO"
# Client version used by players
SERVER_CLIENT_VERSION="20180620"
# Servers public (WAN) IP
SERVER_PUBLIC_IP="127.0.0.1"
# Servers MOTD
SERVER_MOTD="Welcome to StarkRO - Ragnarok Online Server. Enjoy! - starkro.com"

# Server game master account
SERVER_GM_USER="admin"
SERVER_GM_PW="leira27"

######################################################
# Update System
######################################################

apt-get update -y && apt-get upgrade -y

# install needed packages
apt-get install -y git make libmysqlclient-dev zlib1g-dev libpcre3-dev
apt-get update -y
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
apt-get install gcc-8 g++-8
gcc-8 --version
sleep 10
apt install build-essential
sleep 10

ln -s /usr/bin/gcc-8 /usr/bin/gcc
ln -s /usr/bin/g++-8 /usr/bin/g++

#######################################################
# download ragnarok packages
#######################################################

mkdir -p /Oboro
git clone https://github.com/rathena/rathena.git $RAGNAROK_DIR

# compile binaries
cd $RAGNAROK_DIR
git pull

./configure
make server
chmod +x ./athena-start
./athena-start restart

########################################################
# install mysql
########################################################

# Install packages
apt-get install -y mysql-server mysql-client

# cleanup default mysql installation
echo "Cleaning up mysql installation..."
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_ROOT_PW') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"
echo "Done!"
echo ""

# Create default ragnarok user and database
echo "Creating Database ${MYSQL_RAGNAROK_DB}..."
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE DATABASE ${MYSQL_RAGNAROK_DB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE DATABASE logging /*\!40100 DEFAULT CHARACTER SET utf8 */;"
echo "Database successfully created!"
echo "Showing existing databases..."
mysql -uroot -p${MYSQL_ROOT_PW} -e "show databases;"
echo ""
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE USER ${MYSQL_RAGNAROK_USER}@localhost IDENTIFIED BY '${MYSQL_RAGNAROK_PW}';"
echo "User successfully created!"
echo ""
echo "Granting ALL privileges on ${MYSQL_RAGNAROK_DB} to ${MYSQL_RAGNAROK_USER}!"
mysql -uroot -p${MYSQL_ROOT_PW} -e "GRANT ALL PRIVILEGES ON ${MYSQL_RAGNAROK_DB}.* TO '${MYSQL_RAGNAROK_USER}'@'localhost';"
mysql -uroot -p${MYSQL_ROOT_PW} -e "GRANT ALL PRIVILEGES ON logging.* TO '${MYSQL_RAGNAROK_USER}'@'localhost';"
mysql -uroot -p${MYSQL_ROOT_PW} -e "FLUSH PRIVILEGES;"
echo "Done!"

# import rathena sql files
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} ${MYSQL_RAGNAROK_DB} < ${RAGNAROK_DIR}/sql-files/main.sql
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} logging < ${RAGNAROK_DIR}/sql-files/logs.sql

# create admin account
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} -D${MYSQL_RAGNAROK_DB} -e "INSERT INTO login (account_id, userid, user_pass, sex, email, group_id, state, unban_time, expiration_time, logincount, lastlogin, last_ip, birthdate, character_slots, pincode, pincode_change, vip_time, old_group) VALUES ('2000001', '${SERVER_GM_USER}', '${SERVER_GM_PW}', 'M', 'a@a', '99', '0', '0', '0', '0', NULL, '', NULL, '0', '', '0', '0', '0');"


########################################################
# configure rathena config files
########################################################

# configure /conf/inter_athena.conf
cat << EOF > ${RAGNAROK_DIR}/conf/inter_athena.conf
// Athena InterServer configuration.
// Contains settings shared/used by more than 1 server.

// Options for both versions

// Log Inter Connections, etc.?
log_inter: 1

// Inter Log Filename
inter_log_filename: log/inter.log

// Level range for sharing within a party
party_share_level: 15

// You can specify the codepage to use in your MySQL tables here.
// (Note that this feature requires MySQL 4.1+)
//default_codepage:

// For IPs, ideally under linux, you want to use localhost instead of 127.0.0.1
// Under windows, you want to use 127.0.0.1.  If you see a message like
// "Can't connect to local MySQL server through socket '/tmp/mysql.sock' (2)"
// and you have localhost, switch it to 127.0.0.1

// Global SQL settings
// overridden by local settings when the hostname is defined there
// (currently only the login-server reads/obeys these settings)

// MySQL Login server
login_server_ip: 127.0.0.1
login_server_port: 3306
login_server_id: ${MYSQL_RAGNAROK_USER}
login_server_pw: ${MYSQL_RAGNAROK_PW}
login_server_db: ${MYSQL_RAGNAROK_DB}
login_codepage:
login_case_sensitive: no

ipban_db_ip: 127.0.0.1
ipban_db_port: 3306
ipban_db_id: ${MYSQL_RAGNAROK_USER}
ipban_db_pw: ${MYSQL_RAGNAROK_PW}
ipban_db_db: ${MYSQL_RAGNAROK_DB}
ipban_codepage:

// MySQL Character server
char_server_ip: 127.0.0.1
char_server_port: 3306
char_server_id: ${MYSQL_RAGNAROK_USER}
char_server_pw: ${MYSQL_RAGNAROK_PW}
char_server_db: ${MYSQL_RAGNAROK_DB}

// MySQL Map Server
map_server_ip: 127.0.0.1
map_server_port: 3306
map_server_id: ${MYSQL_RAGNAROK_USER}
map_server_pw: ${MYSQL_RAGNAROK_PW}
map_server_db: ${MYSQL_RAGNAROK_DB}

// MySQL Log Database
log_db_ip: 127.0.0.1
log_db_port: 3306
log_db_id: ${MYSQL_RAGNAROK_USER}
log_db_pw: ${MYSQL_RAGNAROK_PW}
log_db_db: logging
log_codepage:
log_login_db: loginlog

// MySQL Reconnect Settings
// - mysql_reconnect_type:
//   1: When MySQL disconnects during runtime, the server tries to reconnect
//      mysql_reconnect_count times and shuts down if unsuccessful.
//   2: When mysql disconnects during runtime, it tries to reconnect indefinitely.
mysql_reconnect_type: 2
mysql_reconnect_count: 1

// DO NOT CHANGE ANYTHING BEYOND THIS LINE UNLESS YOU KNOW YOUR DATABASE DAMN WELL
// this is meant for people who KNOW their stuff, and for some reason want to change their
// database layout. [CLOWNISIUS]

// ALL MySQL Database Table names

// Login Database Tables
login_server_account_db: login
ipban_table: ipbanlist

// Shared
global_acc_reg_num_table: global_acc_reg_num
global_acc_reg_str_table: global_acc_reg_str

// Char Database Tables
char_db: char
hotkey_db: hotkey
scdata_db: sc_data
cart_db: cart_inventory
inventory_db: inventory
charlog_db: charlog
skill_db: skill
interlog_db: interlog
memo_db: memo
guild_db: guild
guild_alliance_db: guild_alliance
guild_castle_db: guild_castle
guild_expulsion_db: guild_expulsion
guild_member_db: guild_member
guild_skill_db: guild_skill
guild_position_db: guild_position
guild_storage_db: guild_storage
party_db: party
pet_db: pet
friend_db: friends
mail_db: mail
mail_attachment_db: mail_attachments
auction_db: auction
quest_db: quest
homunculus_db: homunculus
skill_homunculus_db: skill_homunculus
mercenary_db: mercenary
mercenary_owner_db: mercenary_owner
elemental_db: elemental
ragsrvinfo_db: ragsrvinfo
skillcooldown_db: skillcooldown
bonus_script_db: bonus_script
acc_reg_num_table: acc_reg_num
acc_reg_str_table: acc_reg_str
char_reg_str_table: char_reg_str
char_reg_num_table: char_reg_num
clan_table: clan
clan_alliance_table: clan_alliance

// Map Database Tables
buyingstore_table: buyingstores
buyingstore_items_table: buyingstore_items
item_table: item_db
renewal-item_table: item_db_re
item2_table: item_db2
renewal-item2_table: item_db2_re
item_cash_table: item_cash_db
item_cash2_table: item_cash_db2
mob_table: mob_db
renewal-mob_table: mob_db_re
mob2_table: mob_db2
renewal-mob2_table: mob_db2_re
mob_skill_table: mob_skill_db
renewal-mob_skill_table: mob_skill_db_re
mob_skill2_table: mob_skill_db2
renewal-mob_skill2_table: mob_skill_db2_re
mapreg_table: mapreg
sales_table: sales
vending_table: vendings
vending_items_table: vending_items
market_table: market
roulette_table: db_roulette
guild_storage_log: guild_storage_log

// Use SQL item_db, mob_db and mob_skill_db for the map server? (yes/no)
use_sql_db: no

inter_server_conf: inter_server.yml

import: conf/import/inter_conf.txt
EOF

# Configuration for conf/char_athena.conf
# See: https://github.com/rathena/rathena/blob/master/conf/char_athena.conf
cat << EOF > ${RAGNAROK_DIR}/conf/char_athena.conf
// Athena Character configuration file.

// Note: "Comments" are all text on the right side of a double slash "//"
// Whatever text is commented will not be parsed by the servers, and serves
// only as information/reference.

// Server Communication username and password.
userid: s1
passwd: p1

// Server name, use alternative character such as ASCII 160 for spaces.
// NOTE: Do not use spaces or any of these characters which are not allowed in
//       Windows filenames \/:*?"<>|
//       ... or else guild emblems won't work client-side!
server_name: ${SERVER_NAME}

// Wisp name for server: used to send wisp from server to players (between 4 to 23 characters)
wisp_server_name: Server

// Login Server IP
// The character server connects to the login server using this IP address.
// NOTE: This is useful when you are running behind a firewall or are on
// a machine with multiple interfaces.
login_ip: 127.0.0.1

// The character server listens on the interface with this IP address.
// NOTE: This allows you to run multiple servers on multiple interfaces
// while using the same ports for each server.
bind_ip: 0.0.0.0

// Login Server Port
login_port: 6900

// Character Server IP
// The IP address which clients will use to connect.
// Set this to what your server's public IP address is.
char_ip: ${SERVER_PUBLIC_IP}

// Character Server Port
char_port: 6121

//Time-stamp format which will be printed before all messages.
//Can at most be 20 characters long.
//Common formats:
// %I:%M:%S %p (hour:minute:second 12 hour, AM/PM format)
// %H:%M:%S (hour:minute:second, 24 hour format)
// %d/%b/%Y (day/Month/year)
//For full format information, consult the strftime() manual.
//timestamp_format: [%d/%b %H:%M]

//If redirected output contains escape sequences (color codes)
stdout_with_ansisequence: no

//Makes server log selected message types to a file in the /log/ folder
//1: Log Warning Messages
//2: Log Error and SQL Error messages.
//4: Log Debug Messages
//Example: "console_msg_log: 7" logs all 3 kinds
//Messages logged by this overrides console_silent setting
console_msg_log: 0

// File path to store the console messages above
console_log_filepath: ./log/char-msg_log.log

//Makes server output more silent by ommitting certain types of messages:
//1: Hide Information messages
//2: Hide Status messages
//4: Hide Notice Messages
//8: Hide Warning Messages
//16: Hide Error and SQL Error messages.
//32: Hide Debug Messages
//Example: "console_silent: 7" Hides information, status and notice messages (1+2+4)
console_silent: 0

// Console Commands
// Allow for console commands to be used on/off
// This prevents usage of >& log.file
console: off

// Type of server.
// No functional side effects at the moment.
// Displayed next to the server name in the client.
// 0=normal, 1=maintenance, 2=over 18, 3=paying, 4=P2P
char_maintenance: 0

// Enable or disable creation of new characters.
// Now it is actually supported [Kevin]
char_new: yes

// Display (New) in the server list.
char_new_display: 0

// Maximum users able to connect to the server.
// Set to 0 to disable users to log-in. (-1 means unlimited)
max_connect_user: -1

// Group ID that is allowed to bypass the server limit of users.
// Or to connect when the char is in maintenance mode (groupid >= allow)
// Default: -1 = nobody (there are no groups with ID < 0)
// See: conf/groups.conf
gm_allow_group: 99

// How often should the server save guild infos? (In seconds)
// (character save interval is defined on the map config (autosave_time))
autosave_time: 60

// Display information on the console whenever characters/guilds/parties/pets are loaded/saved?
save_log: yes

// Starting point for new characters
// Format: <map_name>,<x>,<y>{:<map_name>,<x>,<y>...}
// Max number of start points is MAX_STARTPOINT in char.h (default 5)
// Location is randomly picked on character creation.
// NOTE: For Doram, this requires client 20151001 or newer.
start_point: prontera,155,182
start_point_pre: new_1-1,53,111:new_2-1,53,111:new_3-1,53,111:new_4-1,53,111:new_5-1,53,111
start_point_doram: lasa_fild01,48,297

// Starting items for new characters
// Max number of items is MAX_STARTITEM in char.c (default 32)
// Format: <id>,<amount>,<position>{:<id>,<amount>,<position>...}
// To auto-equip an item, include the position where it will be equipped; otherwise, use zero.
// NOTE: For Doram, this requires client 20151001 or newer.
start_items: 1201,1,2:2301,1,16
start_items_doram: 1681,1,2:2301,1,16

// Starting zeny for new characters
start_zeny: 0

// Size for the fame-lists
fame_list_alchemist: 10
fame_list_blacksmith: 10
fame_list_taekwon: 10

// Guild earned exp modifier.
// Adjusts taxed exp before adding it to the guild's exp. For example, if set
// to 200, the guild receives double the player's taxed exp.
guild_exp_rate: 100

// Name used for unknown characters
unknown_char_name: Unknown

// To log the character server?
log_char: yes

// Allow or not identical name for characters but with a different case (upper/lower):
// example: Test-test-TEST-TesT; Value: 0 not allowed (default), 1 allowed
name_ignoring_case: no

// Manage possible letters/symbol in the name of charater. Control character (0x00-0x1f) are never accepted. Possible values are:
// NOTE: Applies to character, party and guild names.
// 0: no restriction (default)
// 1: only letters/symbols in 'char_name_letters' option.
// 2: Letters/symbols in 'char_name_letters' option are forbidden. All others are possibles.
char_name_option: 1

// Set the letters/symbols that you want use with the 'char_name_option' option.
// Note: Don't add spaces unless you mean to add 'space' to the list.
char_name_letters: abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890

// Restrict character deletion by BaseLevel
// 0: no restriction (players can delete characters of any level)
// -X: you can't delete chars with BaseLevel <= X
// Y: you can't delete chars with BaseLevel >= Y
// e.g. char_del_level: 80 (players can't delete characters with 80+ BaseLevel)
char_del_level: 0

// Amount of time in seconds by which the character deletion is delayed.
// Default: 86400 (24 hours)
// NOTE: Requires client 2010-08-03aragexeRE or newer.
char_del_delay: 86400

// Restrict character deletion by email address or birthdate.
// This restricts players from changing the langtype and deleting characters.
// Defaults based on client date.
// 1: Email address
// 2: Birthdate
// 3: Email address or Birthdate
// IMPORTANT!
// - This config only works for clients that send 0x0068 or 0x01fb for delete request.
// - Use langtype 1 for newer clients (2013+), to use 0x01fb.
// - Clients that are not using 0x0068 or 0x01fb, only use birthdate (YYMMDD) as default.
char_del_option: 2

// Restrict character deletion as long as he is still in a party or guild
// 0: No restriction is applied
// 1: Character cannot be deleted as long as he remains in a party
// 2: Character cannot be deleted as long as he remains in a guild
// 3: Character cannot be deleted as long as he remains in a party or guild(default)
char_del_restriction: 3

// Restrict certain class from being created. (Only functional on 20151001aRagexe or later)
// 0: No character creation is allowed
// 1: Only novice is allowed to be created    (pre-renewal default)
// 2: Only summoner is allowed to be created
// 3: Both novice and summoner can be created (renewal default)
// Uncomment to customize the restriction
//allowed_job_flag: 3

// What folder the DB files are in (item_db.txt, etc.)
db_path: db

//===================================
// Pincode system
//===================================
// NOTE: Requires client 2011-03-09aragexeRE or newer.
// A window is opened before you can select your character and you will have to enter a pincode by using only your mouse.
// Default: yes
pincode_enabled: no

// How often does a user have to change his pincode?
// 0: never (default)
// X: every X days
pincode_changetime: 0

// How often can a user enter the wrong pincode?
// Default: 3 (client maximum)
pincode_maxtry: 3

// Are users forced to use a pincode when the system is enabled?
// Default: yes
pincode_force: no

// Are repeated numbers allowed?
// Default: no
pincode_allow_repeated: no

// Are sequential numbers allowed?
// Default: no
pincode_allow_sequential: no

//===================================
// Addon system
//===================================
// Character moving
// NOTE: Requires client 2011-09-28aragexeRE or newer.
// Allows users to move their characters between slots.
// Default: yes
char_move_enabled: yes

// Allow users to move a character to a used slot?
// If enabled the characters are exchanged.
// Default: yes
char_movetoused: yes

// Allow users to move characters as often as they like?
char_moves_unlimited: no

// Character renaming
// Allow users to rename a character while being in a party?
// Default: no
char_rename_party: no

// Allow users to rename a character while being in a guild?
// Default: no
char_rename_guild: no

// Should we check if sql-tables are correct on server startup ?
char_checkdb: yes

// Default map if character is in not-existing map when loaded.
default_map: prontera
default_map_x: 156
default_map_y: 191

// After how many days should inactive clan members be removed from their clan?
// 0: never remove them
// X: remove clan members if they did not log in for X days
// Default: 14
clan_remove_inactive_days: 14

//===================================
// RODEX
//===================================
// After how many days should mails be returned to their sender?
// 0: never return them
// X: return them after X days
// Default: 15
mail_return_days: 15

// How many days after a mail was returned to it's sender should it be deleted completely?
// 0: never delete them
// X: delete them X days after they were returned
// Default: 15
mail_delete_days: 15

import: conf/import/char_conf.txt

EOF

# Configuration for conf/map_athena.conf
# See: https://github.com/rathena/rathena/blob/master/conf/map_athena.conf
cat << EOF > ${RAGNAROK_DIR}/conf/map_athena.conf
//--------------------------------------------------------------
//rAthena Map-Server Configuration File
//--------------------------------------------------------------

// Note: "Comments" are all text on the right side of a double slash "//"
// Whatever text is commented will not be parsed by the servers, and serves
// only as information/reference.

//--------------------------------------------------------------
//                     Configuration Info
//--------------------------------------------------------------
// Interserver communication passwords, set in account.txt (or equiv.)
userid: s1
passwd: p1

// Character Server IP
// The map server connects to the character server using this IP address.
// NOTE: This is useful when you are running behind a firewall or are on
// a machine with multiple interfaces.
char_ip: 127.0.0.1

// The map server listens on the interface with this IP address.
// NOTE: This allows you to run multiple servers on multiple interfaces
// while using the same ports for each server.
bind_ip: 0.0.0.0

// Character Server Port
char_port: 6121

// Map Server IP
// The IP address which clients will use to connect.
// Set this to what your server's public IP address is.
map_ip: ${SERVER_PUBLIC_IP}

// Map Server Port
map_port: 5121

//Time-stamp format which will be printed before all messages.
//Can at most be 20 characters long.
//Common formats:
// %I:%M:%S %p (hour:minute:second 12 hour, AM/PM format)
// %H:%M:%S (hour:minute:second, 24 hour format)
// %d/%b/%Y (day/Month/year)
//For full format information, consult the strftime() manual.
//timestamp_format: [%d/%b %H:%M]

//If redirected output contains escape sequences (color codes)
stdout_with_ansisequence: no

//Makes server log selected message types to a file in the /log/ folder
//1: Log Warning Messages
//2: Log Error and SQL Error messages.
//4: Log Debug Messages
//Example: "console_msg_log: 7" logs all 3 kinds
//Messages logged by this overrides console_silent setting
console_msg_log: 0

// File path to store the console messages above
console_log_filepath: ./log/map-msg_log.log

//Makes server output more silent by omitting certain types of messages:
//1: Hide Information messages
//2: Hide Status messages
//4: Hide Notice Messages
//8: Hide Warning Messages
//16: Hide Error and SQL Error messages.
//32: Hide Debug Messages
//Example: "console_silent: 7" Hides information, status and notice messages (1+2+4)
console_silent: 0

//Where should all database data be read from?
db_path: db

// Enable the @guildspy and @partyspy at commands?
// Note that enabling them decreases packet sending performance.
enable_spy: no

// Read map data from GATs and RSWs in GRF files or a data directory
// as referenced by grf-files.txt rather than from the mapcache?
use_grf: no

// Console Commands
// Allow for console commands to be used on/off
// This prevents usage of >& log.file
console: off

// Database autosave time
// All characters are saved on this time in seconds (example:
// autosave of 60 secs with 60 characters online -> one char is saved every
// second)
autosave_time: 300

// Min database save intervals (in ms)
// Prevent saving characters faster than at this rate (prevents char-server
// save-load getting too high as character-count increases)
minsave_time: 100

// Apart from the autosave_time, players will also get saved when involved
// in the following (add as needed):
// 1: after every successful trade
// 2: after opening vending/every vending transaction
// 4: after closing storage/guild storage.
// 8: After hatching/returning to egg a pet.
// 16: After successfully sending a mail with attachment
// 32: After successfully submitting an item for auction
// 64: After successfully get/delete/complete a quest
// 128: After every bank transaction (deposit/withdraw)
// 256: After every attendance reward
// 4095: Always
// NOTE: These settings decrease the chance of dupes/lost items when there's a
// server crash at the expense of increasing the map/char server lag. If your
// server rarely crashes, but experiences interserver lag, you may want to set
// these off.
save_settings: 4095

// Message of the day file, when a character logs on, this message is displayed.
motd_txt: conf/motd.txt

// When @help or @h is typed when you are a gm, this is displayed for helping new gms understand gm commands.
help_txt: conf/help.txt
help2_txt: conf/help2.txt
charhelp_txt: conf/charhelp.txt

// Load channel config from
channel_conf: conf/channels.conf

// Maps:
import: conf/maps_athena.conf

import: conf/import/map_conf.txt
EOF


# Configuration for conf/login_athena.conf
# See: https://github.com/rathena/rathena/blob/master/conf/login_athena.conf
cat << EOF > ${RAGNAROK_DIR}/conf/login_athena.conf
// Athena Login Server configuration file.
// Translated by Peter Kieser <pfak@telus.net>

// Note: "Comments" are all text on the right side of a double slash "//"
// Whatever text is commented will not be parsed by the servers, and serves
// only as information/reference.

// The login server listens on the interface with this IP address.
// NOTE: This allows you to run multiple servers on multiple interfaces
// while using the same ports for each server.
bind_ip: 0.0.0.0

// Login Server Port
login_port: 6900

//Time-stamp format which will be printed before all messages.
//Can at most be 20 characters long.
//Common formats:
// %I:%M:%S %p (hour:minute:second 12 hour, AM/PM format)
// %H:%M:%S (hour:minute:second, 24 hour format)
// %d/%b/%Y (day/Month/year)
//For full format information, consult the strftime() manual.
//timestamp_format: [%d/%b %H:%M]

//If redirected output contains escape sequences (color codes)
stdout_with_ansisequence: no

//Makes server log selected message types to a file in the /log/ folder
//1: Log Warning Messages
//2: Log Error and SQL Error messages.
//4: Log Debug Messages
//Example: "console_msg_log: 7" logs all 3 kinds
//Messages logged by this overrides console_silent setting
console_msg_log: 0

// File path to store the console messages above
console_log_filepath: ./log/login-msg_log.log

//Makes server output more silent by omitting certain types of messages:
//1: Hide Information messages
//2: Hide Status messages
//4: Hide Notice Messages
//8: Hide Warning Messages
//16: Hide Error and SQL Error messages.
//32: Hide Debug Messages
//Example: "console_silent: 7" Hides information, status and notice messages (1+2+4)
console_silent: 0

// Console Commands
// Allow for console commands to be used on/off
// This prevents usage of >& log.file
console: off

// Can you use _M/_F to make new accounts on the server?
new_account: yes

//If new_account is enabled, minimum length to userid and passwords should be 4?
//Must be 'Yes' unless your client uses both 'Disable 4 LetterUserID/Password' Diffs
new_acc_length_limit: yes

// Account registration flood protection system
// allowed_regs is the number of registrations allowed in time_allowed (in seconds)
allowed_regs: 1
time_allowed: 10

// Log Filename. All operations received by the server are logged in this file.
login_log_filename: log/login.log

// To log the login server?
// NOTE: The login server needs the login logs to enable dynamic pass failure bans.
log_login: yes

// Indicate how to display date in logs, to players, etc.
date_format: %Y-%m-%d %H:%M:%S

// Required account group id to connect to server.
// -1: disabled
// 0 or more: group id
group_id_to_connect: -1

// Minimum account group id required to connect to server.
// Will not function if group_id_to_connect config is enabled.
// -1: disabled
// 0 or more: group id
min_group_id_to_connect: -1

// Which group (ID) will be denoted as the VIP group?
// Default: 5
vip_group: 5

// How many characters are allowed per account?
// You cannot exceed the limit of MAX_CHARS slots, defined in mmo.h, or chars_per_account
// will default to MAX_CHARS.
// 0 will default to the value of MIN_CHARS. (default)
chars_per_account: 0

// Max character limit increase for VIP accounts (0 to disable)
// Increase the value of MAX_CHARS if you want to increase vip_char_increase.
// Note: The amount of VIP characters = MAX_CHARS - chars_per_account.
// Note 2: This setting must be set after chars_per_account.
// -1 will default to MAX_CHAR_VIP (src/config/core.hpp)
vip_char_increase: -1

// Create accounts with limited time?
// -1: new accounts are created with unlimited time (default)
// 0 or more: new accounts automatically expire after the given value, in seconds
start_limited_time: -1

// Store passwords as MD5 hashes instead of plain text?
// NOTE: Will not work with clients that use <passwordencrypt>
use_MD5_passwords: no

// User count colorization on login window (requires PACKETVER >= 20170726)
// Disable colorization and description in general?
usercount_disable: no
// Amount of users that will display in green
usercount_low: 200
// Amount of users that will display in yellow
usercount_medium: 500
// Amount of users that will display in red
usercount_high: 1000

// Ipban features
ipban_enable: yes
// Dynamic password failure ipban system
// Ban user after a number of failed attempts?
ipban_dynamic_pass_failure_ban: yes
// Interval (in minutes) to calculate how many failed attempts.
ipban_dynamic_pass_failure_ban_interval: 5
// Maximum amount of failed attempts before banning.
ipban_dynamic_pass_failure_ban_limit: 7
// Time (in minutes) for ban duration.
ipban_dynamic_pass_failure_ban_duration: 5
// Interval (in seconds) to clean up expired IP bans. 0 = disabled. default = 60.
// NOTE: Even if this is disabled, expired IP bans will be cleaned up on login server start/stop.
// Players will still be able to login if an ipban entry exists but the expiration time has already passed.
ipban_cleanup_interval: 60

// Interval (in minutes) to execute a DNS/IP update. Disabled by default.
// Enable it if your server uses a dynamic IP which changes with time.
//ip_sync_interval: 10

// DNS Blacklist Blocking
// If enabled, each incoming connection will be tested against the blacklists
// on the specified dnsbl_servers (comma-separated list)
use_dnsbl: no
dnsbl_servers: bl.blocklist.de, socks.dnsbl.sorbs.net
// Here are some free DNS Blacklist Services: http://en.wikipedia.org/wiki/Comparison_of_DNS_blacklists
//==============================================================================
//   dnsbl_servers                 Description
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// bl.blocklist.de                 IP-Addresses who attack other servers/honeypots over SSH, FTP, IMAP, etc.
// ircbl.ahbl.org                  AHBL (open proxies, compromised machines, comment spammers)
// safe.dnsbl.sorbs.net            All zones in dnsbl.sorbs.net except "recent" and "escalations"
// sbl-xbl.spamhaus.org            Spamhaus blacklist (spammers, open proxies)
// socks.dnsbl.sorbs.net           Open SOCKS proxy servers
// tor.ahbl.org                    Current tor relay and exit nodes

// Client MD5 hash check
// If turned on, the login server will check if the client's hash matches
// the value below, and will not connect tampered clients.
// Note: see 'doc/md5_hashcheck.txt' for more details.
client_hash_check: off

// Client MD5 hashes
// The client with the specified hash can be used to log in by players with
// a group_id equal to or greater than the given value.
// If you specify 'disabled' as hash, players with a group_id greater than or
// equal to the given value will be able to log in regardless of hash (and even
// if their client does not send a hash at all.)
// Format: group_id, hash
// Note: see 'doc/md5_hashcheck.txt' for more details.
//client_hash: 0, 113e195e6c051bb1cfb12a644bb084c5
//client_hash: 10, cb1ea78023d337c38e8ba5124e2338ae
//client_hash: 99, disabled

import: conf/inter_athena.conf
import: conf/import/login_conf.txt
EOF

# Configuration for /src/config/packets.hpp
# See: https://github.com/rathena/rathena/blob/master/src/config/packets.hpp
cat << EOF > ${RAGNAROK_DIR}/src/config/packets.hpp
// Copyright (c) rAthena Dev Teams - Licensed under GNU GPL
// For more information, see LICENCE in the main folder

#ifndef CONFIG_PACKETS_HPP
#define CONFIG_PACKETS_HPP

/**
 * rAthena configuration file (http://rathena.org)
 * For detailed guidance on these check http://rathena.org/wiki/SRC/config/
 **/

#ifndef PACKETVER
	/// Do NOT edit this line! To set your client version, please do this instead:
	/// In Windows: Add this line in your src\custom\defines_pre.hpp file: #define PACKETVER YYYYMMDD
	/// In Linux: The same as above or run the following command: ./configure --enable-packetver=YYYYMMDD
	#define PACKETVER 20180620
#endif

#ifndef PACKETVER_RE
	/// From November 2015 only RagexeRE are supported.
	/// After July 2018 only Ragexe are supported.
	#if PACKETVER > 20151104 && PACKETVER < 20180704
		#define PACKETVER_RE
	#endif
#endif

#if PACKETVER >= 20110817
	/// Comment to disable the official packet obfuscation support.
	/// This requires PACKETVER 2011-08-17 or newer.
	/// #ifndef PACKET_OBFUSCATION
		/// #define PACKET_OBFUSCATION

		// Define these inside src/custom/defines_pre.hpp or src/custom/defines_post.hpp
		//#define PACKET_OBFUSCATION_KEY1 <key1>
		//#define PACKET_OBFUSCATION_KEY2 <key2>
		//#define PACKET_OBFUSCATION_KEY3 <key3>

		/// Comment this to disable warnings for missing client side encryption
		/// #define PACKET_OBFUSCATION_WARN
	/// #endif
#else
	#if defined(PACKET_OBFUSCATION)
		#error You enabled packet obfuscation for a version which is too old. Minimum supported client is 2011-08-17.
	#endif
#endif

/// Comment to disable the official Guild Storage skill.
/// When enabled, this will set the guild storage size to the level of the skill * 100.
#if PACKETVER >= 20131223
	#define OFFICIAL_GUILD_STORAGE
#endif

#ifndef DUMP_UNKNOWN_PACKET
	//#define DUMP_UNKNOWN_PACKET
#endif

#ifndef DUMP_INVALID_PACKET
	//#define DUMP_INVALID_PACKET
#endif

/**
 * No settings past this point
 **/

/// Check if the specified packetversion supports the pincode system
#define PACKETVER_SUPPORTS_PINCODE PACKETVER >= 20110309

/// Check if the client needs delete_date as remaining time and not the actual delete_date (actually it was tested for clients since 2013)
#define PACKETVER_CHAR_DELETEDATE (PACKETVER > 20130000 && PACKETVER <= 20141022) || PACKETVER >= 20150513

/// Check if the specified packetvresion supports the cashshop sale system
#define PACKETVER_SUPPORTS_SALES PACKETVER >= 20131223

#endif /* CONFIG_PACKETS_HPP */
EOF

# Configure motd
cat << EOF > ${RAGNAROK_DIR}/conf/motd.text
${SERVER_MOTD}
EOF

# recompile the server binaries
./configure --enable-packetver=${SERVER_CLIENT_VERSION}
make clean
make server

########################################################
# install apache2
########################################################q

apt-get install -y apache2
apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-gd php7.0-opcache
apt-get install -y phpmyadmin

echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
service apache2 restart

rm -rf ./install-starkro.sh