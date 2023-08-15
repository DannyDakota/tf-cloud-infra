# Use an official Python runtime as a parent image
FROM python:3.8-slim-buster

WORKDIR /app

# Copy the current directory contents into the container at /app
COPY ./backend/server.py /app/server.py
COPY ./backend/requirements.txt /app/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port on which your Flask app runs
EXPOSE 5000

# Run your Flask app
CMD ["python", "server.py"]
