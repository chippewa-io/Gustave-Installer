import subprocess
import os

progress_file = "/tmp/install_progress_celery.txt"

# Clear out the progress file before starting the installation
if os.path.exists(progress_file):
    os.remove(progress_file)

# Writing initial progress
with open(progress_file, "a") as f:
    f.write("Installation has started. Percent: 0\n")

# Using subprocess to install Celery
result = subprocess.run(["pip3", "install", "celery[redis]"], capture_output=True, text=True)

# Writing end of progress
if result.returncode == 0:
    with open(progress_file, "a") as f:
        f.write("Celery installation was successful. Percent: 100\n")
else:
    with open(progress_file, "a") as f:
        f.write(f"An error occurred during Celery installation: {result.stderr}. Percent: 100\n")
