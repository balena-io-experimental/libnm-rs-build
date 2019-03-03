#!/usr/bin/env bash

set -e

docker build --tag=gir .

docker run -it -p 8000:8000 gir /bin/bash
