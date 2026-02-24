@echo off
REM Batch script to install and run VigilPay for mobile access on Windows

python -m venv .venv
call .venv\Scripts\activate

pip install --upgrade pip
pip install -r requirements.txt

if exist .env.example (
    copy .env.example .env
    echo .env file created from .env.example, please edit as needed.
)

python manage.py migrate
python manage.py createsuperuser

python manage.py runserver 0.0.0.0:8000
