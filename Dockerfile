FROM ruby:3.3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY Gemfile ./
RUN bundle install

COPY . .

ENV PORT=4567
EXPOSE $PORT

CMD ruby app.rb -o 0.0.0.0 -p $PORT
