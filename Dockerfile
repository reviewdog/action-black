FROM python:3

RUN apt-get install bash

ENV REVIEWDOG_VERSION=v0.11.0-nightly20201213+85edbc6

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/nightly/master/install.sh| sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

RUN pip install black

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
