# Usa la imagen oficial de pgAdmin 4 desde Docker Hub
FROM dpage/pgadmin4

# Cambia al usuario root
USER root

# Instala dependencias de Python para pgAdmin
RUN apk update && apk add --no-cache python3 py3-pip && pip3 install psycopg2-binary

# Configura pgAdmin
ENV PGADMIN_PORT=5050

# Agrega servidor de base de datos en pgAdmin
RUN echo "hostaddr=clmc31ap700kzpmcg8y9b8cxs port=5432 dbname=mydb username=admin password=admin1234" > /etc/pgadmin/servers.json

# No es necesario exponer el puerto 5050, ya está configurado en la imagen oficial

# Cambia de nuevo al usuario pgadmin
USER pgadmin

# Inicia pgAdmin al ejecutar el contenedor
CMD ["pgadmin4"]