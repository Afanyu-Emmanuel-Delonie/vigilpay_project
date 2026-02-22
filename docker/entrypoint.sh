#!/bin/sh
set -e

python manage.py migrate --noinput

# If no command is provided by the platform, run gunicorn by default.
if [ "$#" -eq 0 ]; then
  set -- gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000}
fi

exec "$@"
