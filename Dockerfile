FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . /app

# Collect static files when manage.py is available; do not fail image build if not present.
RUN if [ -f manage.py ]; then python manage.py collectstatic --noinput; fi

EXPOSE 10000

CMD ["sh", "-c", "python manage.py migrate --noinput --run-syncdb && gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-10000}"]
