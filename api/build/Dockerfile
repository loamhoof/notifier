FROM elixir:1.10.0-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs yarn python

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./

RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY priv priv
COPY lib lib
COPY rel rel

RUN MIX_ENV=prod mix release

# prepare release image
FROM alpine:3.11 AS app
RUN apk add --update bash openssl

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/api ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app

COPY build/entrypoint.sh entrypoint.sh

ENTRYPOINT ./entrypoint.sh
