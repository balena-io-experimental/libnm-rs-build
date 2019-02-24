#!/usr/bin/env bash

docker build --tag=gir .
docker run -it -p 8000:8000 gir
