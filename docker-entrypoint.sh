#!/bin/sh
set -e

# if command starts with an option, prepend yagpdb
if [ "${1:0:1}" = '-' ]; then
  set -- yagpdb "$@"
fi

# if command starts with an absolute path to the yagpdb binary, shorten it to yagpdb
if [ "$1" == '/app/yagpdb' ] || [ "$1" == '../app/yagpdb' ] || [ "$1" == './yagpdb' ]; then
  set -- yagpdb "${@#$1}"
fi

# if container is started as root user, restart as dedicated yagpdb user
if [ "$1" = 'yagpdb' -a "$(id -u)" = '0' ]; then
	# this will cause less disk access than `chown -R`
	find "/app/cert" \! -user yagpdb -exec chown yagpdb:yagpdb '{}' +
	find "/app/soundboard" \! -user yagpdb -exec chown yagpdb:yagpdb '{}' +
	exec su-exec yagpdb "$0" "$@"
fi

exec "$@"
