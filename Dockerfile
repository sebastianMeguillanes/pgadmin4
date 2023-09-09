# Utiliza la imagen base de pgAdmin 4
FROM docker.io/dpage/pgadmin4@sha256:2e3747c48b19a98124fa8c8f0e78857bbf494c2f6ee5d271c72917c37d1b3502

# Instala las dependencias necesarias
RUN apk update && apk add --no-cache python3 py3-pip && pip3 install psycopg2-binary

# Crea el directorio /etc/pgadmin si no existe
RUN mkdir -p /etc/pgadmin

# Crea el archivo servers.json con la configuración de PostgreSQL
RUN echo "hostaddr=clmc31ap700kzpmcg8y9b8cxs port=5432 dbname=mydb username=admin password=admin1234" > /etc/pgadmin/servers.json

# Configura la variable de entorno PGADMIN_SERVER_JSON_FILE para apuntar al archivo servers.json recién creado
ENV PGADMIN_SERVER_JSON_FILE=/etc/pgadmin/servers.json

# Ejecuta el servidor pgAdmin 4
CMD [ "python3", "/usr/local/lib/python3.9/site-packages/pgadmin4/pgAdmin4.py" ]