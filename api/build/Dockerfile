FROM elixir:1.10.2-alpine AS build

# install build dependencies
RUN apk add --update build-base npm git python

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# build project
COPY lib lib
COPY priv priv
RUN mix compile

# build release
COPY rel rel
RUN mix release

# prepare release image
FROM alpine:3.11.6 AS app
RUN apk add --update bash

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/api ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app

COPY build/entrypoint.sh entrypoint.sh

ENTRYPOINT ./entrypoint.sh
