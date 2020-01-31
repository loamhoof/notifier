#!/bin/sh

MIX_ENV=build mix deps.get --only prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export MIX_ENV=prod
mix release
