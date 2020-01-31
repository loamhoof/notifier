#!/bin/sh

bin/api eval "Api.Release.migrate" && bin/api start
