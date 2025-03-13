FROM ruby:3.1.3-alpine

RUN apk add --no-cache bash curl jq wget
RUN apk update && apk add --no-cache build-base libffi-dev libxml2-dev libxslt-dev
RUN gem install github-linguist
RUN mkdir -p "$HOME/bin" && \
    cd "$HOME/bin" && \
    wget https://github.com/denisidoro/docpars/releases/download/v0.2.0/docpars-v0.2.0-x86_64-unknown-linux-musl.tar.gz && tar xvfz docpars-v0.2.0-x86_64-unknown-linux-musl.tar.gz -C ./ && \
    chmod +x docpars

ADD entrypoint.sh /entrypoint.sh
ADD src /src

ENTRYPOINT ["/entrypoint.sh"]
