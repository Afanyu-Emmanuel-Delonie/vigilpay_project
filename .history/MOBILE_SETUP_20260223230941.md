# Mobile Environment Setup for VigilPay Project

This document outlines the steps and commands required to install and configure the Django backend so that it can be accessed from a mobile device (Android/iOS) on the same network. It also includes a simple shell script with the necessary commands.

## Prerequisites

1. **Python 3.11+** installed on your system.
2. **pip** package manager.
3. (Optional but recommended) **virtualenv** or **venv** to isolate dependencies.
4. A mobile device connected to the same Wi‑Fi network as your development machine.

## Steps

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone https://github.com/Afanyu-Emmanuel-Delonie/vigilpay_project.git
   cd vigilpay_project
   ```
2. **Create and activate a virtual environment**:
   ```bash
   python -m venv .venv
   # Windows
   .venv\Scripts\activate
   # macOS/Linux
   # source .venv/bin/activate
   ```
3. **Install Python dependencies**:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. **Set up environment variables** (create a `.env` file or export them):
   ```env
   DEBUG=True
   SECRET_KEY=your-secret-key
   ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
   DATABASE_URL=sqlite:///db.sqlite3
   ```
   Adjust values for production if needed.

5. **Apply migrations and create a superuser**:
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   ```

6. **Run the development server binding to all interfaces**:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
   > This makes the backend reachable from other devices on the network. Determine your machine's local IP (e.g. `192.168.1.42`) and enter that in the mobile browser or mobile app as `http://192.168.1.42:8000/`.

7. **(Optional) Use `ngrok` or similar** to expose the local server to the internet for remote testing.

## Mobile Setup Script

You can also run the following commands in sequence by saving them to a script (`mobile_setup.sh` on macOS/Linux or `mobile_setup.bat` on Windows).

```bash
#!/bin/bash
# mobile_setup.sh - run from project root
python -m venv .venv
.venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env   # or manually create .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

> On Windows, change activation command to `.venv\Scripts\activate`.

## Notes

- The existing `requirements.txt` already lists all Python packages the project needs.
- If you need to install mobile‑specific libraries (e.g. REST API support for a mobile front end), make sure they are added to `requirements.txt` and re‑run `pip install -r requirements.txt`.

---

Keep this file as a reference when onboarding new developers or preparing the backend for mobile testing.