FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    wget \
    ruby-full \
    build-essential \
    cmake \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    git

RUN gem install github-linguist

RUN mkdir -p "$HOME/bin" && \
    cd "$HOME/bin" && \
    wget https://github.com/denisidoro/docpars/releases/download/v0.2.0/docpars-v0.2.0-x86_64-unknown-linux-musl.tar.gz && tar xvfz docpars-v0.2.0-x86_64-unknown-linux-musl.tar.gz -C ./ && \
    chmod +x docpars

ADD entrypoint.sh /entrypoint.sh
ADD src /src

ENTRYPOINT ["/entrypoint.sh"]
