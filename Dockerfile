# Use Ruby 3.1.0 as the parent image
FROM ruby:3.1.0

# Install system dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-13

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the main application into the container
COPY . .

# Add a script to be executed every time the container starts
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Expose the port the app runs on
EXPOSE 3000

# The main command to run when the container starts
CMD ["rails", "server", "-b", "0.0.0.0"]
