#use the official Python image from Docker Hub
FROM python:3.7-slim

# Set the working directory in the container
WORKDIR /app

# install pipenv
RUN pip install --no-cache-dir pipenv

# Copy pipfile and pipfile.lock into first (for better caching)
COPY Pipfile* ./

# Install the dependencies via pipenv (without using requirements.txt)
RUN pipenv install --deploy --ignore-pipfile

# Copy the rest of the application code into the container
COPY . .
# Expose the port the app runs on
EXPOSE 5000

# set environment variables for Flask
ENV FLASK_ENV=production

ENV FLASK_APP=app.py


# Set the command to run the application
CMD ["pipenv","run", "python", "app.py"]

