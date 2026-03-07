FROM ruby:3.3-slim

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY . .

ENV PORT=4567
EXPOSE $PORT

CMD ruby app.rb -o 0.0.0.0 -p $PORT
