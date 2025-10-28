# Sử dụng Ruby 3.3.4
FROM ruby:3.3.4-slim

# Cài đặt dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    git \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Tạo thư mục app
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Cài gems
RUN bundle install

# Copy toàn bộ code
COPY . .

# Expose port
EXPOSE 3000

# Start server
CMD ["rails", "server", "-b", "0.0.0.0"]
