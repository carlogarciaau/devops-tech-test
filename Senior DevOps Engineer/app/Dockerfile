# Use an official Python runtime as a parent image
FROM python:3.9-alpine

# Set the working directory to /app
WORKDIR /app

# Copy the requirements.txt file into the container at /app
COPY requirements.txt /app/

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Copy the rest of the application code into the container at /app
COPY hello.py wsgi.py /app/

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Run gunicorn as an entrypoint
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "wsgi:app"]
