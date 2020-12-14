FROM python:3

ENV REVIEWDOG_VERSION=v0.11.0-nightly20201213+85edbc6

# hadolint ignore=DL3006
RUN pip install black

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
