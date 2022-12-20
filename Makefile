
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')

EXTERNAL_JSON=external/cJSON/
EXTERNAL_LUA=external/lua-5.2.3/
EXTERNAL_ZLIB=external/zlib-1.2.11/
EXTERNAL_PCRE2=external/pcre2-10.32/
ZLIB_SYSTEM?=no
PCRE2_SYSTEM?=no
LUA_PLAT=posix
LUA_ENABLE?=no
MAXAGENTS?=2048
REUSE_ID?=no
# XXX Becareful NO EXTRA Spaces here
PREFIX?=/var/ossec
PG_CONFIG?=pg_config
MY_CONFIG?=mysql_config
PRELUDE_CONFIG?=libprelude-config
OSSEC_GROUP?=ossec
OSSEC_USER?=ossec
OSSEC_USER_MAIL?=ossecm
OSSEC_USER_REM?=ossecr

INSTALL_CMD?=install -m $(1) -o $(2) -g $(3)
INSTALL_LOCALTIME?=yes
INSTALL_RESOLVCONF?=yes

USE_PRELUDE?=no
USE_ZEROMQ?=no
USE_GEOIP?=no
USE_INOTIFY=no
USE_PCRE2_JIT=yes
USE_SYSTEMD?=yes

ifneq (${TARGET},winagent)
	USE_OPENSSL?=auto
else
	USE_OPENSSL?=no
endif

ONEWAY?=no
CLEANFULL?=no

export MYLDFLAGS= "${LDFLAGS}"
export MYCFLAGS= "${CFLAGS}"

DEFINES=-DMAX_AGENTS=${MAXAGENTS} -DOSSECHIDS
DEFINES+=-DDEFAULTDIR=\"${PREFIX}\"
DEFINES+=-DUSER=\"${OSSEC_USER}\"
DEFINES+=-DREMUSER=\"${OSSEC_USER_REM}\"
DEFINES+=-DGROUPGLOBAL=\"${OSSEC_GROUP}\"
DEFINES+=-DMAILUSER=\"${OSSEC_USER_MAIL}\"
DEFINES+=-D${uname_S}

# Uncomment the DEFINES statement below if you are
# running Linux and want to use AF_UNSPEC instead of
# AF_INET6 to fully support IPv4 addresses.
#DEFINES+=-DNOV4MAP

ifneq (,$(filter ${REUSE_ID},yes y Y 1))
	DEFINES+=-DREUSE_ID
endif

OSSEC_LDFLAGS=${LDFLAGS} -lm

ifneq (${TARGET},winagent)
ifeq (${uname_S},Linux)
		DEFINES+=-DINOTIFY_ENABLED
		OSSEC_LDFLAGS+=-lpthread
ifeq (${USE_SYSTEMD},yes)
		DEFINES+=-DHAVE_SYSTEMD
		OSSEC_LDFLAGS+=-lsystemd
endif
#		DEFINES+=-DUSE_MAGIC
#		OSSEC_LDFLAGS+=-lmagic
else
ifeq (${uname_S},AIX)
		DEFINES+=-DAIX
		DEFINES+=-DHIGHFIRST
		PATH:=${PATH}:/usr/vac/bin
else
ifeq (${uname_S},SunOS)
		DEFINES+=-DSOLARIS
		DEFINES+=-DHIGHFIRST
		OSSEC_LDFLAGS+=-lsocket -lnsl -lresolv
		LUA_PLAT=solaris
		PATH:=${PATH}:/usr/ccs/bin:/usr/xpg4/bin:/opt/csw/gcc3/bin:/opt/csw/bin:/usr/sfw/bin

else
ifeq (${uname_S},Darwin)
		DEFINES+=-DDarwin
		DEFINES+=-DHIGHFIRST
		LUA_PLAT=macosx

else
ifeq (${uname_S},FreeBSD)
		DEFINES+=-DFreeBSD
		OSSEC_LDFLAGS+=-pthread
		LUA_PLAT=freebsd
		CFLAGS+=-I/usr/local/include
		OSSEC_LDFLAGS+=-L/usr/local/lib
else
ifeq (${uname_S},NetBSD)
		DEFINES+=-DNetBSD
		OSSEC_LDFLAGS+=-pthread
		LUA_PLAT=posix
		CFLAGS+=-I/usr/local/include
		OSSEC_LDFLAGS+=-L/usr/local/lib
		USE_PCRE2_JIT=n
else
ifeq (${uname_S},OpenBSD)
#		DEFINES+=-DOpenBSD
		DEFINES+=-pthread
		DNS_CFLAGS+=-lutil
		LUA_PLAT=posix
		CFLAGS+=-I/usr/local/include
		OSSEC_LDFLAGS+=-L/usr/local/lib
		USE_PCRE2_JIT=n
else
ifeq (${uname_S},HP-UX)
		DEFINES+=-DHPUX
		DEFINES+=-D_XOPEN_SOURCE_EXTENDED
		DEFINES+=-DHIGHFIRST
		DEFINES+=-D_REENTRANT
else
	    $(warning Unknown platform)
endif # HPUX
endif # OpenBSD
endif # NetBSD
endif # FreeBSD
endif # Darwin
endif # SunOS
endif # AIX
endif # Linux
endif # winagent

## OpenBSD doesn't need the imsg stuff.
ifneq (${uname_S},OpenBSD)
        CFLAGS+=-I./external/compat
        COMPAT_FILES+=./external/compat/imsg.c ./external/compat/imsg-buffer.c
endif

ifdef DEBUGAD
	DEFINES+=-DDEBUGAD
endif

OSSEC_CFLAGS=${CFLAGS}
#ANALYSISD_FLAGS="-lsqlite3"

ifdef DEBUG
	OSSEC_CFLAGS+=-g
endif #DEBUG

ifneq (,$(filter ${CLEANFULL},yes y Y 1))
	DEFINES+=-DCLEANFULL
endif

ifneq (,$(filter ${ONEWAY},yes y Y 1))
	DEFINES+=-DONEWAY_ENABLED
endif

ifneq (${ZLIB_SYSTEM},no)
	DEFINES+=-DZLIB_SYSTEM
endif

ifeq (${TARGET}, winagent)
	PCRE2_SYSTEM=no
endif

ifeq (${PCRE2_SYSTEM},no)
	PCRE2_INCLUDE=-I./${EXTERNAL_PCRE2}/install/include/
	DEFINES+=${PCRE2_INCLUDE}
	DEFINES+=-DPCRE2_STATIC
else
	PCRE2_LOCATION?=$(shell pcre2-config --prefix)/lib
	OSSEC_LDFLAGS+=-lpcre2-8
endif


OSSEC_CFLAGS+=${DEFINES}
OSSEC_CFLAGS+=-Wall -Wextra
OSSEC_CFLAGS+=-I./ -I./headers/

CCCOLOR="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR="\033[33m"
BINCOLOR="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR="\033[0m"

MING_BASE:=
ifeq (${TARGET}, winagent)
CC=gcc
ZLIB_SYSTEM=no
PCRE2_SYSTEM=no
ifneq (,$(shell which amd64-mingw32msvc-gcc))
	MING_BASE:=amd64-mingw32msvc-
else
ifneq (,$(shell which i686-pc-mingw32-gcc))
	MING_BASE:=i686-pc-mingw32-
else
ifneq (,$(shell which i686-w64-mingw32-gcc))
	MING_BASE:=i686-w64-mingw32-
else
$(error No windows cross-compiler found!) #MING_BASE:=unknown-
endif
endif
endif
endif #winagent


OSSEC_CC      =${QUIET_CC}${MING_BASE}${CC}
OSSEC_CCBIN   =${QUIET_CCBIN}${MING_BASE}${CC}
OSSEC_LINK    =${QUIET_LINK}${MING_BASE}ar -crs
OSSEC_RANLIB  =${QUIET_RANLIB}${MING_BASE}ranlib
OSSEC_WINDRES =${QUIET_CCBIN}${MING_BASE}windres


ifneq (,$(filter ${USE_PCRE2_JIT},yes y Y 1))
	DEFINES+=-DUSE_PCRE2_JIT
	PCRE2_CONFIGURE_JIT=--enable-jit
else
	PCRE2_CONFIGURE_JIT=--disable-jit
endif

ifneq (,$(filter ${USE_INOTIFY},auto yes y Y 1))
	DEFINES+=-DINOTIFY_ENABLED
	ifeq (${uname_S},FreeBSD)
		OSSEC_LDFLAGS+=-linotify -L/usr/local/lib -I/usr/local/include
		OSSEC_CFLAGS+=-I/usr/local/include
	endif
endif

ifneq (,$(filter ${USE_PRELUDE},auto yes y Y 1))
	DEFINES+=-DPRELUDE_OUTPUT_ENABLED
	OSSEC_LDFLAGS+=-lprelude
	OSSEC_LDFLAGS+=$(shell sh -c '${PRELUDE_CONFIG} --pthread-cflags')
	OSSEC_LDFLAGS+=$(shell sh -c '${PRELUDE_CONFIG} --libs')
endif # USE_PRELUDE

ifneq (,$(filter ${USE_ZEROMQ},auto yes y Y 1))
	DEFINES+=-DZEROMQ_OUTPUT_ENABLED
	#LDFLAGS+=-L/usr/local/lib -I/usr/local/include -lzmq -lczmq
	OSSEC_LDFLAGS+=-lzmq -lczmq -lm
endif # USE_ZEROMQ

ifneq (,$(filter ${USE_GEOIP},auto yes y Y 1))
	DEFINES+=-DLIBGEOIP_ENABLED
	OSSEC_LDFLAGS+=-lGeoIP
endif # USE_GEOIP

ifneq (,$(filter ${USE_SQLITE},auto yes y Y 1))
	DEFINES+=-DSQLITE_ENABLED
	ANALYSISD_FLAGS="-lsqlite3"
endif # USE_SQLITE

MI :=
PI :=
ifdef DATABASE

	ifeq (${DATABASE},mysql)
		DEFINES+=-DMYSQL_DATABASE_ENABLED

		ifdef MYSQL_CFLAGS
			MI = ${MYSQL_CFLAGS}
		else
			MI := $(shell sh -c '${MY_CONFIG} --include 2>/dev/null || echo ')

			ifeq (${MI},) # BEGIN MI manual detection
				ifneq (,$(wildcard /usr/include/mysql/mysql.h))
					MI="-I/usr/include/mysql/"
				else
					ifneq (,$(wildcard /usr/local/include/mysql/mysql.h))
						MI="-I/usr/local/include/mysql/"
					endif  #
				endif  #MI

			endif
		endif # MYSQL_CFLAGS

		ifdef MYSQL_LIBS
			ML = ${MYSQL_LIBS}
		else
			ML := $(shell sh -c '${MY_CONFIG} --libs 2>/dev/null || echo ')

			ifeq (${ML},)
				ifneq (,$(wildcard /usr/lib/mysql/*))
					ML="-L/usr/lib/mysql -lmysqlclient"
				else
					ifneq (,$(wildcard /usr/lib64/mysql/*))
						ML="-L/usr/lib64/mysql -lmysqlclient"
					else
						ifneq (,$(wildcard /usr/local/lib/mysql/*))
							ML="-L/usr/local/lib/mysql -lmysqlclient"
						else
							ifneq (,$(wildcard /usr/local/lib64/mysql/*))
								ML="-L/usr/local/lib64/mysql -lmysqlclient"
							endif # local/lib64
						endif # local/lib
					endif # lib54
				endif # lib
			endif
		endif # MYSQL_LIBS

		OSSEC_LDFLAGS+=${ML}

	else # DATABASE

		ifeq (${DATABASE}, pgsql)
			DEFINES+=-DPGSQL_DATABASE_ENABLED

			ifneq (${PGSQL_LIBS},)
				PL:=${PGSQL_LIBS}
			else
				PL:=$(shell sh -c '(${PG_CONFIG} --libdir --pkglibdir 2>/dev/null | sed "s/^/-L/g" | xargs ) || echo ')
			endif

			ifneq (${PGSQL_CFLAGS},)
				PI:=${PGSQL_CFLAGS}
			else
				PI:=$(shell sh -c '(${PG_CONFIG} --includedir --pkgincludedir 2>/dev/null | sed "s/^/-I/g" | xargs ) || echo ')
			endif

			# XXX need some basic autodetech stuff here.

			OSSEC_LDFLAGS+=${PL}
			OSSEC_LDFLAGS+=-lpq

		endif # pgsql
	endif # mysql
endif # DATABASE


# openssl ###########
ifeq (${USE_OPENSSL},auto)
	ifneq (,$(wildcard /usr/include/openssl/ssl.h))
		DEFINES+=-DLIBOPENSSL_ENABLED
		OSSEC_LDFLAGS+=-lssl -lcrypto
	else
		ifneq (,$(wildcard /usr/local/include/openssl/ssl.h))
			DEFINES+=-DLIBOPENSSL_ENABLED
			OSSEC_LDFLAGS+=-lssl -lcrypto
		endif
	endif
endif # USE_OPENSSL

ifneq (,$(filter ${USE_OPENSSL},yes y Y 1))
	DEFINES+=-DLIBOPENSSL_ENABLED
	ifeq (${OPENSSL_LIBS},)
		OSSEC_LDFLAGS+=-lssl -lcrypto
	else
		OSSEC_LDFLAGS+=${OPENSSL_LIBS}
	endif

	ifneq (${OPENSSL_CFLAGS},)
		OSSEC_CFLAGS+=${OPENSSL_CFLAGS}
	endif
endif

####################
#### Target ########
####################

OSSEC_CONTROL_SRC=./init/ossec-server.sh
OSSEC_CONF_SRC=../etc/ossec-server.conf

ifndef TARGET
	TARGET=failtarget
endif # TARGET

ifeq (${TARGET},agent)
	DEFINES+=-DCLIENT
	OSSEC_CONTROL_SRC=./init/ossec-client.sh
	OSSEC_CONF_SRC=../etc/ossec-agent.conf
endif

ifeq (${TARGET},local)
	DEFINES+=-DLOCAL
	OSSEC_CONTROL_SRC=./init/ossec-local.sh
	OSSEC_CONF_SRC=../etc/ossec-local.conf
endif


.PHONY: build
build: ${TARGET}
ifneq (${TARGET},failtarget)
	${MAKE} settings
	@echo
	${QUIET_NOTICE}
	@echo "Done building ${TARGET}"
	${QUIET_ENDCOLOR}
endif
	@echo


.PHONY: install install-agent install-server install-local install-hybrid
install: install-${TARGET}

install-agent: install-common
	$(call INSTALL_CMD,0550,root,0) ossec-agentd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) agent-auth ${PREFIX}/bin

	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/rids

install-local: install-server-generic

install-hybrid: install-server-generic

install-server: install-server-generic

install-common: build
	./init/adduser.sh ${OSSEC_USER} ${OSSEC_USER_MAIL} ${OSSEC_USER_REM} ${OSSEC_GROUP} ${PREFIX}
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/logs
	$(call INSTALL_CMD,0660,${OSSEC_USER},${OSSEC_GROUP}) /dev/null ${PREFIX}/logs/ossec.log

	$(call INSTALL_CMD,0550,root,0) -d ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-logcollector ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-syscheckd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-execd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) manage_agents ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ../contrib/util.sh ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) ${OSSEC_CONTROL_SRC} ${PREFIX}/bin/ossec-control

ifeq (${LUA_ENABLE},yes)
	$(call INSTALL_CMD,0550,root,0) -d ${PREFIX}/lua
	$(call INSTALL_CMD,0550,root,0) -d ${PREFIX}/lua/native
	$(call INSTALL_CMD,0550,root,0) -d ${PREFIX}/lua/compiled
	$(call INSTALL_CMD,0550,root,0) ${EXTERNAL_LUA}src/ossec-lua ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) ${EXTERNAL_LUA}src/ossec-luac ${PREFIX}/bin/
endif

	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/queue
	$(call INSTALL_CMD,0770,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/alerts
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/ossec
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/syscheck
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/diff

	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/etc
ifeq (${INSTALL_LOCALTIME},yes)
	$(call INSTALL_CMD,0440,root,${OSSEC_GROUP}) /etc/localtime ${PREFIX}/etc
endif
ifeq (${INSTALL_RESOLVCONF},yes)
	$(call INSTALL_CMD,0440,root,${OSSEC_GROUP}) /etc/resolv.conf ${PREFIX}/etc
endif

	$(call INSTALL_CMD,1550,root,${OSSEC_GROUP}) -d ${PREFIX}/tmp

ifneq (,$(wildcard /etc/TIMEZONE))
	$(call INSTALL_CMD,440,root,${OSSEC_GROUP}) /etc/TIMEZONE ${PREFIX}/etc/
endif
# Solaris Needs some extra files
ifeq (${uname_S},SunOS)
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/usr/share/lib/zoneinfo/
	cp -r /usr/share/lib/zoneinfo/* ${PREFIX}/usr/share/lib/zoneinfo/
endif
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) -b ../etc/internal_options.conf ${PREFIX}/etc/
ifeq (,$(wildcard ${PREFIX}/etc/local_internal_options.conf))
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) ../etc/local_internal_options.conf ${PREFIX}/etc/local_internal_options.conf
endif
ifeq (,$(wildcard ${PREFIX}/etc/client.keys))
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) /dev/null ${PREFIX}/etc/client.keys
endif
ifeq (,$(wildcard ${PREFIX}/etc/ossec.conf))
ifneq (,$(wildcard ../etc/ossec.mc))
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) ../etc/ossec.mc ${PREFIX}/etc/ossec.conf
else
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) ${OSSEC_CONF_SRC} ${PREFIX}/etc/ossec.conf
endif
endif

	$(call INSTALL_CMD,0770,root,${OSSEC_GROUP}) -d ${PREFIX}/etc/shared
	$(call INSTALL_CMD,0640,${OSSEC_USER},${OSSEC_GROUP}) rootcheck/db/*.txt ${PREFIX}/etc/shared/

	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/active-response
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/active-response/bin
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/agentless
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) agentlessd/scripts/* ${PREFIX}/agentless/

	$(call INSTALL_CMD,0700,root,${OSSEC_GROUP}) -d ${PREFIX}/.ssh

	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) ../active-response/*.sh ${PREFIX}/active-response/bin/
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) ../active-response/firewalls/*.sh ${PREFIX}/active-response/bin/

	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/var
	$(call INSTALL_CMD,0770,root,${OSSEC_GROUP}) -d ${PREFIX}/var/run

	./init/fw-check.sh execute



install-server-generic: install-common
	$(call INSTALL_CMD,0660,${OSSEC_USER},${OSSEC_GROUP}) /dev/null ${PREFIX}/logs/active-responses.log
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/logs/archives
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/logs/alerts
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/logs/firewall

	$(call INSTALL_CMD,0550,root,0) ossec-agentlessd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-analysisd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-monitord ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-reportd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-maild ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-remoted ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-logtest ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-csyslogd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-authd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-dbd ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) ossec-makelists ${PREFIX}/bin
	$(call INSTALL_CMD,0550,root,0) verify-agent-conf ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) clear_stats ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) list_agents ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) ossec-regex ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) syscheck_update ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) agent_control ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) syscheck_control ${PREFIX}/bin/
	$(call INSTALL_CMD,0550,root,0) rootcheck_control ${PREFIX}/bin/

	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/stats
	$(call INSTALL_CMD,0550,root,${OSSEC_GROUP}) -d ${PREFIX}/rules
ifneq (,$(wildcard ${PREFIX}/rules/local_rules.xml))
	cp ${PREFIX}/rules/local_rules.xml ${PREFIX}/rules/local_rules.xml.installbackup
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) -b ../etc/rules/*.xml ${PREFIX}/rules
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) ${PREFIX}/rules/local_rules.xml.installbackup ${PREFIX}/rules/local_rules.xml
	rm ${PREFIX}/rules/local_rules.xml.installbackup
else
	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) -b ../etc/rules/*.xml ${PREFIX}/rules
endif

	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/fts

	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/rootcheck

	$(call INSTALL_CMD,0750,${OSSEC_USER_REM},${OSSEC_GROUP}) -d ${PREFIX}/queue/agent-info
	$(call INSTALL_CMD,0750,${OSSEC_USER},${OSSEC_GROUP}) -d ${PREFIX}/queue/agentless

	$(call INSTALL_CMD,0750,${OSSEC_USER_REM},${OSSEC_GROUP}) -d ${PREFIX}/queue/rids

	$(call INSTALL_CMD,0640,root,${OSSEC_GROUP}) ../etc/decoder.xml ${PREFIX}/etc/

	rm -f ${PREFIX}/etc/shared/merged.mg


.PHONY: failtarget
failtarget:
	@echo "TARGET is required: "
	@echo "   make TARGET=server   to build the server"
	@echo "   make TARGET=local      - local version of server"
	@echo "   make TARGET=hybrid     - hybrid version of server"
	@echo "   make TARGET=agent    to build the unix agent"
	@echo "   make TARGET=winagent to build the windows agent"

.PHONY: help
help: failtarget
	@echo
	@echo "General options: "
	@echo "   make V=1              Display full compiler messages"
	@echo "   make DEBUG=1          Build with symbols and without optimization"
	@echo "   make PREFIX=/path     Install OSSEC to '/path'. Defaults to /var/ossec"
	@echo "   make MAXAGENTS=NUMBER Set the number of maximum agents to NUMBER. Defaults to 2048"
	@echo "   make REUSE_ID=yes     Enables agent ID re-use"
	@echo
	@echo "Database options: "
	@echo "   make DATABASE=mysql   Build with MYSQL Support"
	@echo "                         Use MYSQL_CFLAGS and MYSQL_LIBS to override defaults"
	@echo "   make DATABASE=pgsql   Build with PostgreSQL Support "
	@echo "                         Use PGSQL_CFLAGS and PGSQL_LIBS to override defaults"
	@echo
	@echo "Geoip support: "
	@echo "   make USE_GEOIP=1      Build with GeoIP support"
	@echo
	@echo "External source options: "
	@echo "   make LUA_ENABLE=no    Disable LUA build"
	@echo "   make ZLIB_SYSTEM=yes  Use zlib sources from system"
	@echo "   make PCRE2_SYSTEM=yes Use pcre2 sources from system"
	@echo
	@echo "Examples: Client with debugging enabled"
	@echo "   make TARGET=agent DEBUG=1"

.PHONY: settings
settings:
	@echo
	@echo "General settings:"
	@echo "    TARGET:           ${TARGET}"
	@echo "    V:                ${V}"
	@echo "    DEBUG:            ${DEBUG}"
	@echo "    DEBUGAD:          ${DEBUGAD}"
	@echo "    PREFIX:           ${PREFIX}"
	@echo "    MAXAGENTS:        ${MAXAGENTS}"
	@echo "    REUSE_ID:         ${REUSE_ID}"
	@echo "    DATABASE:         ${DATABASE}"
	@echo "    ONEWAY:           ${ONEWAY}"
	@echo "    CLEANFULL:        ${CLEANFULL}"
	@echo "User settings:"
	@echo "    OSSEC_GROUP:      ${OSSEC_GROUP}"
	@echo "    OSSEC_USER:       ${OSSEC_USER}"
	@echo "    OSSEC_USER_MAIL:  ${OSSEC_USER_MAIL}"
	@echo "    OSSEC_USER_REM:   ${OSSEC_USER_REM}"
	@echo "ZLIB settings:"
	@echo "    ZLIB_SYSTEM:      ${ZLIB_SYSTEM}"
	@echo "    ZLIB_INCLUDE:     ${ZLIB_INCLUDE}"
	@echo "    ZLIB_LIB:         ${ZLIB_LIB}"
	@echo "PCRE2 settings:"
	@echo "    PCRE2_SYSTEM:     ${PCRE2_SYSTEM}"
	@echo "    PCRE2_INCLUDE:    ${PCRE2_INCLUDE}"
	@echo "Lua settings:"
	@echo "    LUA_PLAT:         ${LUA_PLAT}"
	@echo "    LUA_ENABLE:       ${LUA_ENABLE}"
	@echo "USE settings:"
	@echo "    USE_ZEROMQ:       ${USE_ZEROMQ}"
	@echo "    USE_GEOIP:        ${USE_GEOIP}"
	@echo "    USE_PRELUDE:      ${USE_PRELUDE}"
	@echo "    USE_OPENSSL:      ${USE_OPENSSL}"
	@echo "    USE_INOTIFY:      ${USE_INOTIFY}"
	@echo "    USE_SQLITE:       ${USE_SQLITE}"
	@echo "    USE_PCRE2_JIT:    ${USE_PCRE2_JIT}"
	@echo "    USE_SYSTEMD:      ${USE_SYSTEMD}"
	@echo "Mysql settings:"
	@echo "    includes:         ${MI}"
	@echo "    libs:             ${ML}"
	@echo "Pgsql settings:"
	@echo "    includes:         ${PI}"
	@echo "    libs:             ${PL}"
	@echo "Defines:"
	@echo "    ${DEFINES}"
	@echo "Compiler:"
	@echo "    CFLAGS          ${OSSEC_CFLAGS}"
	@echo "    LDFLAGS         ${OSSEC_LDFLAGS}"
	@echo "    CC              ${CC}"
	@echo "    MAKE            ${MAKE}"


BUILD_SERVER+=external
BUILD_SERVER+=ossec-maild
BUILD_SERVER+=ossec-csyslogd
BUILD_SERVER+=ossec-agentlessd
BUILD_SERVER+=ossec-execd
BUILD_SERVER+=ossec-logcollector
BUILD_SERVER+=ossec-remoted
BUILD_SERVER+=ossec-agentd
BUILD_SERVER+=manage_agents
BUILD_SERVER+=utils
BUILD_SERVER+=ossec-syscheckd
BUILD_SERVER+=ossec-monitord
BUILD_SERVER+=ossec-reportd
ifneq (,$(filter ${USE_OPENSSL},auto yes))
BUILD_SERVER+=ossec-authd
endif
BUILD_SERVER+=ossec-analysisd
BUILD_SERVER+=ossec-logtest
BUILD_SERVER+=ossec-makelists
BUILD_SERVER+=ossec-dbd

BUILD_AGENT+=external
BUILD_AGENT+=ossec-agentd
ifneq (,$(filter ${USE_OPENSSL},auto yes))
BUILD_AGENT+=agent-auth
endif
BUILD_AGENT+=ossec-logcollector
BUILD_AGENT+=ossec-syscheckd
BUILD_AGENT+=ossec-execd
BUILD_AGENT+=manage_agents

.PHONY: server local hybrid agent
ifeq (${MAKECMDGOALS},server)
$(error Do not use 'server' directly, use 'TARGET=server')
endif
server: ${BUILD_SERVER}

ifeq (${MAKECMDGOALS},local)
$(error Do not use 'local' directly, use 'TARGET=local')
endif
local: ${BUILD_SERVER}

ifeq (${MAKECMDGOALS},hybrid)
$(error Do not use 'hybrid' directly, use 'TARGET=hybrid')
endif
hybrid: ${BUILD_SERVER}

ifeq (${MAKECMDGOALS},agent)
$(error Do not use 'agent' directly, use 'TARGET=agent')
endif
agent: ${BUILD_AGENT}


WINDOWS_BINS:=win32/ossec-agent.exe win32/ossec-agent-eventchannel.exe win32/ossec-rootcheck.exe win32/manage_agents.exe win32/setup-windows.exe win32/setup-syscheck.exe win32/setup-iis.exe win32/add-localfile.exe win32/os_win32ui.exe win32/agent-auth.exe

ifeq (${MAKECMDGOALS},winagent)
$(error Do not use 'winagent' directly, use 'TARGET=winagent')
endif
.PHONY: winagent
winagent:
	${MAKE} ${WINDOWS_BINS} CFLAGS="-DCLIENT -DWIN32 -I./${EXTERNAL_ZLIB} -I./${EXTERNAL_PCRE2}/install/include" LDFLAGS="-lwsock32 -lwevtapi -lshlwapi -lcomctl32 -lws2_32"
	#cd ${EXTERNAL_LUA}src/ && ${MAKE} CC=${MING_BASE}${CC} -f Makefile.mingw mingw
	#cp ${EXTERNAL_LUA}src/ossec-lua.exe win32/
	#cp ${EXTERNAL_LUA}src/ossec-luac.exe win32/
	cd win32/ && ./unix2dos.pl ossec.conf > default-ossec.conf
	cd win32/ && ./unix2dos.pl help.txt > help_win.txt
	cd win32/ && ./unix2dos.pl ../../etc/internal_options.conf > internal_options.conf
	cd win32/ && ./unix2dos.pl ../../etc/local_internal_options-win.conf > default-local_internal_options.conf
	cd win32/ && ./unix2dos.pl ../../LICENSE > LICENSE.txt
	cd win32/ && ./unix2dos.pl ../../active-response/win/route-null.cmd > route-null.cmd
	cd win32/ && ./unix2dos.pl ../../active-response/win/restart-ossec.cmd > restart-ossec.cmd
	cd win32/ && makensis ossec-installer.nsi


####################
#### External ######
####################

.PHONY: external lua
ifeq (${PCRE2_SYSTEM},no)
external: libcJSON.a ${EXTERNAL_ZLIB}libz.a lua libpcre2-8.a
else
external: libcJSON.a ${EXTERNAL_ZLIB}libz.a lua
endif

lua:
ifeq (${LUA_ENABLE},yes)
	cd ${EXTERNAL_LUA} && ${MAKE} ${LUA_PLAT}
endif

${EXTERNAL_ZLIB}libz.a:
ifeq (${TARGET},winagent)
	cd ${EXTERNAL_ZLIB} && cp zconf.h.in zconf.h && ${MAKE} -f win32/Makefile.gcc PREFIX=${MING_BASE} libz.a
else
ifeq (${ZLIB_SYSTEM},no)
	cd ${EXTERNAL_ZLIB} && ./configure && ${MAKE} libz.a
endif
endif

#### zlib ##########

ifeq (${ZLIB_SYSTEM},no)
ZLIB_LIB=os_zlib.a ${EXTERNAL_ZLIB}libz.a
ZLIB_INCLUDE=-I./${EXTERNAL_ZLIB}
else
ZLIB_LIB=os_zlib.a
ZLIB_INCLUDE=
OSSEC_LDFLAGS+=-lz
endif

os_zlib_c := os_zlib/os_zlib.c
os_zlib_o := $(os_zlib_c:.c=.o)

os_zlib/%.o: os_zlib/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $< -o $@

os_zlib.a: ${os_zlib_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@



#### cJSON #########

JSON_LIB=libcJSON.a
JSON_INCLUDE=-I./${EXTERNAL_JSON}

cjson_c := ${EXTERNAL_JSON}cJSON.c
cjson_o := $(cjson_c:.c=.o)

${EXTERNAL_JSON}%.o: ${EXTERNAL_JSON}%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

libcJSON.a: ${cjson_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@



#### pcre2 ##########

ifeq (${PCRE2_SYSTEM},no)
libpcre2-8.a: ${EXTERNAL_PCRE2}/install/lib/libpcre2-8.a
	cp $< $@
	${OSSEC_RANLIB} $@

${EXTERNAL_PCRE2}/install/lib/libpcre2-8.a:
ifeq (${TARGET}, winagent)
	cd ${EXTERNAL_PCRE2} && \
	CC= ./configure \
		--prefix=$(shell pwd)/${EXTERNAL_PCRE2}/install \
		${PCRE2_CONFIGURE_JIT} \
		--disable-shared \
		--enable-static \
		--host=${MING_BASE:%-=%} && \
	make install-libLTLIBRARIES install-nodist_includeHEADERS
else
	cd ${EXTERNAL_PCRE2} && \
	./configure \
		--prefix=$(shell pwd)/${EXTERNAL_PCRE2}/install \
		${PCRE2_CONFIGURE_JIT} \
		--disable-shared \
		--enable-static && \
	make install-libLTLIBRARIES install-nodist_includeHEADERS
endif
endif


####################
#### OSSEC Libs ####
####################

ossec_libs = os_crypto.a config.a shared.a os_net.a os_regex.a os_xml.a

#### os_xml ########

os_xml_c := $(wildcard os_xml/*.c)
os_xml_o := $(os_xml_c:.c=.o)

os_xml/%.o: os_xml/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

os_xml.a: ${os_xml_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@


#### os_regex ######

os_regex_c := $(wildcard os_regex/*.c)
os_regex_o := $(os_regex_c:.c=.o)

os_regex/%.o: os_regex/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

ifeq (${PCRE2_SYSTEM},no)
os_regex.a: ${os_regex_o} libpcre2-8.a
	(mkdir -p libpcre2_objs && cd libpcre2_objs && ${QUIET_LINK}${MING_BASE}ar -x ../libpcre2-8.a)
	${OSSEC_LINK} $@ ${os_regex_o} $(addprefix libpcre2_objs/,$(shell ${MING_BASE}ar -t libpcre2-8.a))
	${OSSEC_RANLIB} $@
	rm -rf libpcre2_objs
else
os_regex.a: ${os_regex_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@
endif

#### os_net ##########

os_net_c := $(wildcard os_net/*.c)
os_net_o := $(os_net_c:.c=.o)

os_net/%.o: os_net/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS}  -c $^ -o $@

os_net.a: ${os_net_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@

#### Shared ##########

shared_c := $(wildcard shared/*.c)
shared_o := $(shared_c:.c=.o)

shared/%.o: shared/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS}  -c $^ -o $@

shared.a: ${shared_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@

#### Config ##########

config_c := $(wildcard config/*.c)
config_o := $(config_c:.c=.o)

config/%.o: config/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS}  -c $^ -o $@

config.a: ${config_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@

#### crypto ##########

crypto_blowfish_c := os_crypto/blowfish/bf_op.c \
										os_crypto/blowfish/bf_skey.c \
										os_crypto/blowfish/bf_enc.c
crypto_blowfish_o := $(crypto_blowfish_c:.c=.o)

os_crypto/blowfish/%.o: os_crypto/blowfish/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -Wno-implicit-fallthrough -c $^ -o $@

crypto_md5_c := os_crypto/md5/md5.c \
							 os_crypto/md5/md5_op.c
crypto_md5_o := $(crypto_md5_c:.c=.o)

os_crypto/md5/%.o: os_crypto/md5/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

crypto_sha1_c := os_crypto/sha1/sha1_op.c
crypto_sha1_o := $(crypto_sha1_c:.c=.o)

os_crypto/sha1/%.o: os_crypto/sha1/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -Wno-implicit-fallthrough -c $^ -o $@

crypto_md5_sha1_c := os_crypto/md5_sha1/md5_sha1_op.c
crypto_md5_sha1_o := $(crypto_md5_sha1_c:.c=.o)

os_crypto/md5_sha1/%.o: os_crypto/md5_sha1/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

crypto_shared_c := $(wildcard os_crypto/shared/*.c)
crypto_shared_o := $(crypto_shared_c:.c=.o)

os_crypto/shared/%.o: os_crypto/shared/%.c ${ZLIB_LIB}
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $< -o $@


crypto_o := ${crypto_blowfish_o} \
					 ${crypto_md5_o} \
					 ${crypto_sha1_o} \
					 ${crypto_shared_o} \
					 ${crypto_md5_sha1_o}

os_crypto.a: ${crypto_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@

#### os_mail #########

os_maild_c := $(wildcard os_maild/*.c) addagent/b64.c
os_maild_o := $(os_maild_c:.c=.o)

os_maild/%.o: os_maild/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-maild\" -c $^ -o $@

ossec-maild: ${os_maild_o} ${ossec_libs}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} ${DNS_CFLAGS} ${COMPAT_FILES} -o $@

#### os_dbd ##########

os_dbd_c := $(wildcard os_dbd/*.c)
os_dbd_o := $(os_dbd_c:.c=.o)

os_dbd/%.o: os_dbd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} ${MI} ${PI} -DARGV0=\"ossec-dbd\" -c $^ -o $@

ossec-dbd: ${os_dbd_o} ${ossec_libs}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${MI} ${PI} ${JSON_INCLUDE} $^ -lm ${OSSEC_LDFLAGS} -o $@


#### os_csyslogd #####

os_csyslogd_c := $(wildcard os_csyslogd/*.c)
os_csyslogd_o := $(os_csyslogd_c:.c=.o)

os_csyslogd/%.o: os_csyslogd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} ${JSON_INCLUDE} -DARGV0=\"ossec-csyslogd\" -c $^ -o $@

ossec-csyslogd: ${os_csyslogd_o} ${ossec_libs} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${JSON_INCLUDE} $^ -lm ${OSSEC_LDFLAGS} -o $@


#### agentlessd ####

os_agentlessd_c := $(wildcard agentlessd/*.c)
os_agentlessd_o := $(os_agentlessd_c:.c=.o)

agentlessd/%.o: agentlessd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-agentlessd\" -c $^ -o $@

ossec-agentlessd: ${os_agentlessd_o} ${ossec_libs}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

#### os_execd #####

os_execd_c := $(wildcard os_execd/*.c)
os_execd_o := $(os_execd_c:.c=.o)

os_execd/%.o: os_execd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS}  -DARGV0=\"ossec-execd\" -c $^ -o $@

ossec-execd: ${os_execd_o} ${ossec_libs} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${JSON_INCLUDE} $^ -lm ${OSSEC_LDFLAGS} -o $@


#### logcollectord ####

os_logcollector_c := $(wildcard logcollector/*.c)
os_logcollector_o := $(os_logcollector_c:.c=.o)
os_logcollector_eventchannel_o := $(os_logcollector_c:.c=-event.o)

logcollector/%.o: logcollector/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-logcollector\" -c $^ -o $@

logcollector/%-event.o: logcollector/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DEVENTCHANNEL_SUPPORT -DARGV0=\"ossec-logcollector\" -c $^ -o $@

ossec-logcollector: ${os_logcollector_o} ${ossec_libs}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

#### remoted #########

remoted_c := $(wildcard remoted/*.c)
remoted_o := $(remoted_c:.c=.o)

remoted/%.o: remoted/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -I./remoted ${ZLIB_INCLUDE} -DARGV0=\"ossec-remoted\" -c $^ -o $@

ossec-remoted: ${remoted_o} ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

#### ossec-agentd ####

ifneq (${TARGET},winagent)
client_agent_c := $(wildcard client-agent/*.c)
else
client_agent_c := $(wildcard client-agent/*.c)
endif
client_agent_o := $(client_agent_c:.c=.o)

client-agent/%.o: client-agent/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -I./client-agent  ${ZLIB_INCLUDE} -DARGV0=\"ossec-agentd\" -c $^ -o $@

ossec-agentd: ${client_agent_o} ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} ${DNS_CFLAGS} ${COMPAT_FILES} -o $@

#### addagent ######

addagent_c := $(wildcard addagent/*.c)
addagent_o := $(addagent_c:.c=.o)

addagent/%.o: addagent/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -I./addagent ${ZLIB_INCLUDE} -DARGV0=\"manage_agents\" -c $^ -o $@


manage_agents: ${addagent_o} ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} ${JSON_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

#### Util ##########

util_programs = syscheck_update clear_stats list_agents agent_control syscheck_control rootcheck_control verify-agent-conf ossec-regex ossec-regex-convert

.PHONY: utils
utils: ${util_programs}

util_c := $(wildcard util/*.c)
util_o := $(util_c:.c=.o)

util/%.o: util/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -I./util ${ZLIB_INCLUDE} -DARGV0=\"utils\" -c $^ -o $@

syscheck_update: util/syscheck_update.o addagent/validate.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} ${JSON_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

clear_stats: util/clear_stats.o ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

list_agents: util/list_agents.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

verify-agent-conf: util/verify-agent-conf.o ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

agent_control: util/agent_control.o addagent/validate.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} ${JSON_INCLUDE} $^ -lm ${OSSEC_LDFLAGS} -o $@

syscheck_control: util/syscheck_control.o addagent/validate.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} ${JSON_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

rootcheck_control: util/rootcheck_control.o addagent/validate.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} ${JSON_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

ossec-regex: util/ossec-regex.o ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

ossec-regex-convert: util/ossec-regex-convert.o ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

#### rootcheck #####

rootcheck_c := $(wildcard rootcheck/*.c)
rootcheck_o := $(rootcheck_c:.c=.o)
rootcheck_rk_o := $(rootcheck_c:.c=_rk.o)
rootcheck_o_lib := $(filter-out rootcheck/rootcheck-config.o, ${rootcheck_o})
rootcheck_o_cmd := $(filter-out rootcheck/config.o, ${rootcheck_o})


rootcheck/%.o: rootcheck/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"rootcheck\" -c $^ -o $@

rootcheck/%_rk.o: rootcheck/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"rootcheck\" -UOSSECHIDS -c $^ -o $@


rootcheck.a: ${rootcheck_o_lib}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@

#ossec-rootcheck: rootcheck/rootcheck-config.o rootcheck.a ${ossec_libs}
#	@echo ${rootcheck_o_cmd}
#	@echo ${rootcheck_o_lib}
#	@echo ${rootcheck_o}
#	${OSSEC_CC} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} rootcheck/rootcheck-config.o rootcheck.a rootcheck/rootcheck.c ${ZLIB_LIB} ${ossec_libs}  -o $@

#### syscheck ######


syscheck_c := $(wildcard syscheckd/*.c)
syscheck_o := $(syscheck_c:.c=.o)

syscheckd/%.o: syscheckd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-syscheckd\" -c $^ -o $@

ossec-syscheckd: ${syscheck_o} rootcheck.a ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@

#### Monitor #######

monitor_c := $(wildcard monitord/*.c)
monitor_o := $(monitor_c:.c=.o)

monitord/%.o: monitord/%.c ${ZLIB_LIB}
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-monitord\" -c $< -o $@

ossec-monitord: ${monitor_o} ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${ZLIB_INCLUDE} $^ ${OSSEC_LDFLAGS} -o $@


#### reportd #######

report_c := reportd/report.c
report_o := $(report_c:.c=.o)

reportd/%.o: reportd/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-reportd\" -c $^ -o $@

ossec-reportd: ${report_o} ${ossec_libs}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@


#### os_auth #######

os_auth_c := ${wildcard os_auth/*.c}
os_auth_o := $(os_auth_c:.c=.o)

os_auth/%.o: os_auth/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS}  -I./os_auth -DARGV0=\"ossec-authd\" -c $^ -o $@

agent-auth: addagent/validate.o os_auth/main-client.o os_auth/ssl.o os_auth/check_cert.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${JSON_INCLUDE} -I./os_auth $^ ${OSSEC_LDFLAGS} -o $@

ossec-authd: addagent/validate.o os_auth/main-server.o os_auth/ssl.o os_auth/check_cert.o ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} ${JSON_INCLUDE} -I./os_auth $^ ${OSSEC_LDFLAGS} -o $@

#### analysisd #####

cdb_c := ${wildcard analysisd/cdb/*.c}
cdb_o := $(cdb_c:.c=.o)
all_analysisd_o += ${cdb_o}
all_analysisd_libs += cdb.a

analysisd/cdb/%.o: analysisd/cdb/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/cdb -c $^ -o $@

cdb.a: ${cdb_o}
	${OSSEC_LINK} $@ $^
	${OSSEC_RANLIB} $@


alerts_c := ${wildcard analysisd/alerts/*.c}
alerts_o := $(alerts_c:.c=.o)
all_analysisd_o += ${alerts_o}
all_analysisd_libs += alerts.a

analysisd/alerts/%.o: analysisd/alerts/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/alerts -c $^ -o $@

alerts.a: ${alerts_o}
	${OSSEC_LINK} $@ $^

decoders_c := ${wildcard analysisd/decoders/*.c} ${wildcard analysisd/decoders/plugins/*.c} ${wildcard analysisd/compiled_rules/*.c}
decoders_o := $(decoders_c:.c=.o)
## XXX Nasty hack
decoders_test_o := $(decoders_c:.c=-test.o)
decoders_live_o := $(decoders_c:.c=-live.o)

all_analysisd_o += ${decoders_o} ${decoders_test_o} ${decoders_live_o}
all_analysisd_libs += decoders.a decoders-test.a decoders-live.a


analysisd/decoders/%-test.o: analysisd/decoders/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DTESTRULE -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@


analysisd/decoders/%-live.o: analysisd/decoders/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@

analysisd/decoders/plugins/%-test.o: analysisd/decoders/plugins/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DTESTRULE -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@


analysisd/decoders/plugins/%-live.o: analysisd/decoders/plugins/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@

analysisd/compiled_rules/compiled_rules.h: analysisd/compiled_rules/.function_list analysisd/compiled_rules/register_rule.sh
	./analysisd/compiled_rules/register_rule.sh build

analysisd/compiled_rules/%-test.o: analysisd/compiled_rules/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DTESTRULE -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@

analysisd/compiled_rules/%-live.o: analysisd/compiled_rules/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@

decoders-live.a: ${decoders_live_o}
	${OSSEC_LINK} $@ $^

decoders-test.a: ${decoders_test_o}
	${OSSEC_LINK} $@ $^

format_c := ${wildcard analysisd/format/*.c}
format_o := ${format_c:.c=.o}
all_analysisd_o += ${format_o}

analysisd/format/%.o: analysisd/format/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} ${JSON_INCLUDE} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@

output_c := ${wildcard analysisd/output/*c}
output_o := ${output_c:.c=.o}
all_analysisd_o += ${output_o}

analysisd/output/%.o: analysisd/output/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -I./analysisd/decoders -c $^ -o $@



analysisd_c := ${filter-out analysisd/analysisd.c, ${filter-out analysisd/testrule.c, ${filter-out analysisd/makelists.c, ${wildcard analysisd/*.c}}}}
analysisd_o := ${analysisd_c:.c=.o}
all_analysisd_o += ${analysisd_o}

analysisd_test_o := $(analysisd_o:.o=-test.o)
analysisd_live_o := $(analysisd_o:.o=-live.o)
all_analysisd_o += ${analysisd_test_o} ${analysisd_live_o} analysisd/testrule-test.o analysisd/analysisd-live.o analysisd/analysisd-test.o analysisd/makelists-live.o

analysisd/%-live.o: analysisd/%.c analysisd/compiled_rules/compiled_rules.h
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-analysisd\" -I./analysisd -c $< -o $@

analysisd/%-test.o: analysisd/%.c analysisd/compiled_rules/compiled_rules.h
	${OSSEC_CC} ${OSSEC_CFLAGS} -DTESTRULE -DARGV0=\"ossec-analysisd\" -I./analysisd -c $< -o $@


ossec-logtest: ${analysisd_test_o} ${output_o} ${format_o} analysisd/testrule-test.o analysisd/analysisd-test.o alerts.a cdb.a decoders-test.a ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} -DTESTRULE $^ ${OSSEC_LDFLAGS} ${ANALYSISD_FLAGS} -o $@

ossec-analysisd: ${analysisd_live_o} analysisd/analysisd-live.o ${output_o} ${format_o} alerts.a cdb.a decoders-live.a ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS}  $^ ${OSSEC_LDFLAGS} ${ANALYSISD_FLAGS} -o $@

ossec-makelists: analysisd/makelists-live.o ${analysisd_live_o} ${format_o} alerts.a cdb.a decoders-live.a ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS}  $^ ${OSSEC_LDFLAGS} -o $@


####################
#### test ##########
####################

CFLAGS_TEST = -g -O0 --coverage

LDFLAGS_TEST = -lcheck -lm -pthread -lrt -lsubunit

ifdef TEST
	OSSEC_CFLAGS+=${CFLAGS_TEST}
	OSSEC_LDFLAGS+=${LDFLAGS_TEST}
endif #TEST

test_programs = test_os_zlib test_os_xml test_os_regex test_os_crypto test_shared

.PHONY: test run_tests build_tests test_valgrind test_coverage

test: build_tests
	${MAKE} run_tests

run_tests:
	@$(foreach bin,${test_programs},./${bin} || exit 1;)

build_tests: external
	${MAKE} DEBUG=1 TEST=1 ${test_programs}

test_c := $(wildcard tests/*.c)
test_o := $(test_c:.c=.o)

tests/%.o: tests/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -c $^ -o $@

test_os_zlib: tests/test_os_zlib.o ${ZLIB_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

test_os_xml: tests/test_os_xml.o os_xml.a
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

test_os_regex: tests/test_os_regex.c os_regex.a
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

test_os_crypto: tests/test_os_crypto.c os_crypto.a shared.a os_xml.a os_net.a os_regex.a ${ZLIB_LIB}  ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

#test_os_net: tests/test_os_net.c os_net.a shared.a os_regex.a os_xml.a
#	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

test_shared: tests/test_shared.c shared.a os_xml.a os_net.a os_regex.a ${JSON_LIB}
	${OSSEC_CCBIN} ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

test_valgrind: build_tests
	valgrind --leak-check=full --track-origins=yes --trace-children=yes --vgdb=no --error-exitcode=0 --gen-suppressions=all --suppressions=tests/valgrind.supp ${MAKE} run_tests


test_coverage: build_tests
	lcov --base-directory . --directory . --zerocounters --rc lcov_branch_coverage=1 --quiet
	@echo "Running tests\n"

	${MAKE} run_tests

	@echo "\nTests finished."

	lcov --base-directory . --directory . --capture --quiet --rc lcov_branch_coverage=1 --output-file ossec.test

	rm -rf coverage-report/
	genhtml --branch-coverage --output-directory coverage-report/ --title "ossec test coverage" --show-details --legend --num-spaces 4 --quiet ossec.test

####################
#### RUule Tests ###
####################

test-rules:
	( cd ../contrib/ossec-testing && sudo python runtests.py)


####################
#### windows #######
####################

win32/icon.o: win32/icofile.rc
	${OSSEC_WINDRES} -i $< -o $@

win32_c := $(wildcard win32/*.c)
win32_o := $(win32_c:.c=.o)

win32/%.o: win32/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -DARGV0=\"ossec-agent\" -c $^ -o $@

win32/%_rk.o: win32/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -UOSSECHIDS -DARGV0=\"ossec-agent\" -c $^ -o $@

win32_ui_c := $(wildcard win32/ui/*.c)
win32_ui_o := $(win32_ui_c:.c=.o)

win32/ui/%.o: win32/ui/%.c
	${OSSEC_CC} ${OSSEC_CFLAGS} -UOSSECHIDS -DARGV0=\"ossec-win32ui\" -c $^ -o $@

win32/ossec-agent.exe: win32/icon.o win32/win_agent.o win32/win_service.o $(filter-out syscheckd/seechanges.o, ${syscheck_o}) ${rootcheck_o} $(filter-out client-agent/main.o, $(filter-out client-agent/agentd.o, $(filter-out client-agent/event-forward.o, ${client_agent_o}))) $(filter-out logcollector/main.o, ${os_logcollector_o}) ${os_execd_o} ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} -DARGV0=\"ossec-agent\" -DOSSECHIDS ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/ossec-agent-eventchannel.exe: win32/icon.o win32/win_agent.o win32/win_service.o $(filter-out syscheckd/seechanges.o, ${syscheck_o}) ${rootcheck_o} $(filter-out client-agent/main.o, $(filter-out client-agent/agentd.o, $(filter-out client-agent/event-forward.o, ${client_agent_o}))) $(filter-out logcollector/main-event.o, ${os_logcollector_eventchannel_o}) ${os_execd_o} ${ossec_libs} ${ZLIB_LIB}
	${OSSEC_CCBIN} -DARGV0=\"ossec-agent\" -DOSSECHIDS -DEVENTCHANNEL_SUPPORT ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/ossec-rootcheck.exe: win32/icon.o win32/win_service_rk.o ${rootcheck_rk_o} ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"ossec-rootcheck\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/manage_agents.exe: win32/win_service_rk.o ${addagent_o} ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} -DARGV0=\"manage-agents\" -DMA ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/setup-windows.exe: win32/win_service_rk.o win32/setup-win.o win32/setup-shared.o ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"setup-windows\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/setup-syscheck.exe: win32/setup-syscheck.o win32/setup-shared.o ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"setup-syscheck\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/setup-iis.exe: win32/setup-iis.o ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"setup-iis\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/add-localfile.exe: win32/add-localfile.o ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"add-localfile\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -o $@

win32/resource.o: win32/ui/win32ui.rc
	${OSSEC_WINDRES} -i $< -o $@

win32/os_win32ui.exe: win32/resource.o win32/win_service_rk.o ${win32_ui_o} addagent/b64.o ${ossec_libs}
	${OSSEC_CCBIN} -DARGV0=\"ossec-win32ui\" ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -mwindows -o $@

win32/agent-auth.exe: win32/win_service_rk.o addagent/validate.c win32/agent_auth.c ${ossec_libs} ${ZLIB_LIB} ${JSON_LIB}
	${OSSEC_CCBIN} -DARGV0=\"agent-auth\" -DOSSECHIDS ${OSSEC_CFLAGS} $^ ${OSSEC_LDFLAGS} -lshlwapi -lwsock32 -lsecur32 -flto -o $@




####################
#### Clean #########
####################

clean: clean-test clean-internals clean-external clean-windows

clean-test:
	rm -f ${test_o} ${test_programs} ossec.test
	rm -Rf coverage-report/
	find . -name "*.gcno" -exec rm {} \;
	find . -name "*.gcda" -exec rm {} \;

clean-external:
	rm -f ${cjson_o} libcJSON.a libpcre2-8.a
	cd ${EXTERNAL_ZLIB} && ${MAKE} -f Makefile.in distclean
	cd ${EXTERNAL_LUA} && ${MAKE} clean
	#cd ${EXTERNAL_PCRE2} && ${MAKE} distclean


clean-internals:
	rm -f ${os_zlib_o} os_zlib.a
	rm -f ${os_xml_o} os_xml.a
	rm -f ${os_regex_o} os_regex.a
	rm -f ${os_net_o} os_net.a
	rm -f ${shared_o} shared.a
	rm -f ${config_o} config.a
	rm -f ${os_maild_o} ossec-maild
	rm -f ${crypto_o} os_crypto.a
	rm -f ${os_csyslogd_o} ossec-csyslogd
	rm -f ${os_dbd_o} ossec-dbd
	rm -f ${os_agentlessd_o} ossec-agentlessd
	rm -f ${os_execd_o} ossec-execd
	rm -f ${os_logcollector_o} ${os_logcollector_eventchannel_o} ossec-logcollector
	rm -f ${remoted_o} ossec-remoted
	rm -f ${report_o} ossec-reportd
	rm -f ${client_agent_o} ossec-agentd
	rm -f ${addagent_o} manage_agents
	rm -f ${util_o} ${util_programs}
	rm -f ${rootcheck_o} ${rootcheck_rk_o} rootcheck.a
	rm -f ${syscheck_o} ossec-syscheckd
	rm -f ${monitor_o} ossec-monitord
	rm -f ${os_auth_o} ossec-authd agent-auth
	rm -f ${all_analysisd_o} ${all_analysisd_libs} analysisd/compiled_rules/compiled_rules.h
	rm -f ossec-logtest ossec-analysisd ossec-makelists

clean-windows:
	rm -f win32/LICENSE.txt
	rm -f win32/help_win.txt
	rm -f win32/internal_options.conf
	rm -f win32/default-local_internal_options.conf
	rm -f win32/default-ossec.conf
	rm -f win32/restart-ossec.cmd
	rm -f win32/route-null.cmd
	rm -f ${win32_o} ${win32_ui_o} win32/win_service_rk.o
	rm -f win32/icon.o win32/resource.o
	rm -f ${WINDOWS_BINS}
	#rm -f ${EXTERNAL_LUA}src/lua52.dll
	#rm -f ${EXTERNAL_LUA}src/ossec-lua.exe
	#rm -f ${EXTERNAL_LUA}src/ossec-luac.exe
	#rm -f win32/ossec-lua.exe
	#rm -f win32/ossec-luac.exe
	rm -f win32/ossec-win32-agent.exe
