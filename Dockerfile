########################################################################
#
# pgAdmin 4 - PostgreSQL Tools
#
# Copyright (C) 2013 - 2023, The pgAdmin Development Team
# This software is released under the PostgreSQL Licence
#
#########################################################################

#########################################################################
# Create a Node container which will be used to build the JS components
# and clean up the web/ source code
#########################################################################
FROM debian:bullseye AS app-builder

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bash \
    g++ \
    git \
    libc6-compat \
    libjpeg-turbo-dev \
    libpng-dev \
    libtool \
    make \
    nasm \
    nodejs \
    yarn \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Create the /pgadmin4 directory and copy the source into it. Explicitly
# remove the node_modules directory as we'll recreate a clean version, as well
# as various other files we don't want
COPY web /pgadmin4/web
RUN rm -rf /pgadmin4/web/*.log \
           /pgadmin4/web/config_*.py \
           /pgadmin4/web/node_modules \
           /pgadmin4/web/regression \
           `find /pgadmin4/web -type d -name tests` \
           `find /pgadmin4/web -type f -name .DS_Store`

WORKDIR /pgadmin4/web

# Build the JS vendor code in the app-builder, and then remove the vendor source.
RUN export CPPFLAGS="-DPNG_ARM_NEON_OPT=0" && \
    yarn install && \
    yarn run bundle && \
    rm -rf node_modules \
           yarn.lock \
           package.json \
           .[^.]* \
           babel.cfg \
           webpack.* \
           karma.conf.js \
           ./pgadmin/static/js/generated/.cache

#########################################################################
# Next, create the base environment for Python
#########################################################################

FROM debian:bullseye as env-builder

# Install dependencies
COPY requirements.txt /
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-venv \
    python3.10-dev \
    python3-pip \
    postgresql-server-dev-all \
    krb5-config \
    libldap2-dev \
    libffi-dev \
    libssl-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* && \
    python3.10 -m venv --system-site-packages /venv && \
    /venv/bin/python3.10 -m pip install --no-cache-dir -r requirements.txt

USER pgadmin

# Finish up
VOLUME /var/lib/pgadmin
EXPOSE 9911 443

ENTRYPOINT ["/entrypoint.sh"]
