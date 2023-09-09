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

# Actualizamos e instalamos las dependencias necesarias
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bash \
    g++ \
    git \
    libc6-compat \
    libjpeg-dev \
    libpng-dev \
    libtool \
    make \
    nasm \
    nodejs \
    yarn \
    zlib1g-dev

# Crear el directorio /pgadmin4 y copiar el código fuente en él.
# Eliminar explícitamente el directorio node_modules, así como varios otros archivos y directorios no deseados.
COPY web /pgadmin4/web
RUN rm -rf /pgadmin4/web/*.log \
           /pgadmin4/web/config_*.py \
           /pgadmin4/web/node_modules \
           /pgadmin4/web/regression \
           $(find /pgadmin4/web -type d -name tests) \
           $(find /pgadmin4/web -type f -name .DS_Store)

WORKDIR /pgadmin4/web

# Compilar el código JS en el app-builder y luego eliminar la fuente del proveedor.
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
# A continuación, creamos el entorno base para Python
#########################################################################

FROM debian:bullseye as env-builder

# Instalar las dependencias
COPY requirements.txt /
RUN apt-get update && apt-get install -y \
        make \
        python3 \
        python3-venv \
        python3-pip \
        postgresql-server-dev-all \
        krb5-config \
        libldap2-dev \
        libffi-dev \
        libssl-dev \
        libjpeg-dev \
        libpng-dev \
        zlib1g-dev \
    && python3 -m venv --system-site-packages /venv && \
    /venv/bin/python3 -m pip install --no-cache-dir -r requirements.txt

#########################################################################
# Ahora, creamos un contenedor de construcción de documentación para los documentos de Sphinx
#########################################################################

FROM env-builder as docs-builder

# Instalar Sphinx
RUN /venv/bin/python3 -m pip install --no-cache-dir sphinx
RUN /venv/bin/python3 -m pip install --no-cache-dir sphinxcontrib-youtube

# Copiar los documentos desde el árbol local.
# Eliminar explícitamente cualquier compilación existente que pueda estar presente.
COPY docs /pgadmin4/docs
COPY web /pgadmin4/web
RUN rm -rf /pgadmin4/docs/en_US/_build

# Compilar los documentos
RUN LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 /venv/bin/sphinx-build /pgadmin4/docs/en_US /pgadmin4/docs/en_US/_build/html

# Limpieza de archivos no deseados
RUN rm -rf /pgadmin4/docs/en_US/_build/html/.doctrees
RUN rm -rf /pgadmin4/docs/en_US/_build/html/_sources
RUN rm -rf /pgadmin4/docs/en_US/_build/html/_static/*.png

#########################################################################
# Creamos constructores adicionales para obtener todas las utilidades de PostgreSQL
#########################################################################

FROM postgres:10 AS pg10-builder
FROM postgres:11 AS pg11-builder
FROM postgres:12 AS pg12-builder
FROM postgres:13 AS pg13-builder
FROM postgres:14 AS pg14-builder
FROM postgres:15 AS pg15-builder

FROM debian:bullseye as tool-builder

# Copiar los binarios de PG
COPY --from=pg10-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-10/

COPY --from=pg11-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-11/

COPY --from=pg12-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-12/

COPY --from=pg13-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-13/

COPY --from=pg14-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-14/

COPY --from=pg15-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-15/

#########################################################################
# Ensamblamos la imagen final
#########################################################################

FROM debian:bullseye as final

# Configurar variables de entorno
ENV DEBUG=False \
    PYTHONPATH=/usr/local/lib/python3.9/dist-packages:/usr/local/lib/python3.9/site-packages \
    SECRET_KEY=SuperSecretKey \
    SECURITY_PASSWORD_SALT=SuperSecretSalt \
    SESSION_TYPE=filesystem \
    MAX_COOKIE_SIZE=4000 \
    SERVER_MODE=False \
    LOG_FILE=/var/log/pgadmin/pgadmin4.log \
    SQLITE_PATH=/var/lib/pgadmin/pgadmin4.db \
    SESSION_DB_PATH=/var/lib/pgadmin/sessions \
    STORAGE_DIR=/var/lib/pgadmin/storage \
    ADMINDATA_DIR=/pgadmin4

# Instalar las dependencias del sistema
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    libjpeg-turbo8 \
    libpng16-16 \
    libpq5 \
    libssl1.1 \
    libxslt1.1 \
    locales \
    rsync \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Instalar utilidades de PostgreSQL
COPY --from=tool-builder /usr/local/pgsql/pgsql-10 /usr/local/pgsql/pgsql-10
COPY --from=tool-builder /usr/local/pgsql/pgsql-11 /usr/local/pgsql/pgsql-11
COPY --from=tool-builder /usr/local/pgsql/pgsql-12 /usr/local/pgsql/pgsql-12
COPY --from=tool-builder /usr/local/pgsql/pgsql-13 /usr/local/pgsql/pgsql-13
COPY --from=tool-builder /usr/local/pgsql/pgsql-14 /usr/local/pgsql/pgsql-14
COPY --from=tool-builder /usr/local/pgsql/pgsql-15 /usr/local/pgsql/pgsql-15

# Crear usuarios y grupos para pgAdmin
RUN groupadd -g 5050 pgadmin && \
    useradd -u 5050 -g 5050 -m -s /bin/bash pgadmin && \
    mkdir -p /var/lib/pgadmin && \
    chown -R pgadmin:pgadmin /var/lib/pgadmin && \
    mkdir -p /var/log/pgadmin && \
    chown -R pgadmin:pgadmin /var/log/pgadmin && \
    mkdir -p /var/lib/pgadmin/sessions && \
    chown -R pgadmin:pgadmin /var/lib/pgadmin/sessions && \
    mkdir -p /var/lib/pgadmin/storage && \
    chown -R pgadmin:pgadmin /var/lib/pgadmin/storage && \
    mkdir -p /pgadmin4 && \
    chown -R pgadmin:pgadmin /pgadmin4

# Instalar Python 3.9
COPY --from=env-builder /venv /venv
ENV PATH="/venv/bin:$PATH"

# Instalar documentos de Sphinx
COPY --from=docs-builder /pgadmin4/docs/en_US/_build/html /usr/share/doc/pgadmin4

# Copiar archivos de configuración y scripts
COPY docker/etc /etc/pgadmin
COPY pgAdmin4 /usr/local/lib/python3.9/dist-packages/pgadmin4
COPY scripts /usr/local/share/pgadmin4/scripts

# Configurar locales para en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

# Agregar entrada de hosts para "pgadmin" para solucionar problemas de resolución de nombres en localhost.
RUN echo "127.0.0.1 pgadmin" >> /etc/hosts

# Crear el directorio de almacenamiento en caso de que no exista
RUN mkdir -p /var/lib/pgadmin/storage && \
    chown -R pgadmin:pgadmin /var/lib/pgadmin/storage

# Exponer el puerto 80 para acceder a la interfaz web de pgAdmin
EXPOSE 80

# Directorio de trabajo inicial
WORKDIR /

# Comando de inicio
CMD ["/usr/local/share/pgadmin4/scripts/run_pgadmin.sh"]
