# Usa la imagen oficial de pgAdmin 4 desde Docker Hub
FROM dpage/pgadmin4

# Instala dependencias de Python para pgAdmin
RUN apt-get update && apt-get install -y python3 python3-pip && pip3 install psycopg2

# Configura pgAdmin
ENV PGADMIN_PORT=5050

# Agrega servidor de base de datos en pgAdmin
RUN echo "hostaddr=clmc31ap700kzpmcg8y9b8cxs port=5432 dbname=mydb username=admin password=admin1234" > /etc/pgadmin/servers.json

# Exponer puerto de pgAdmin (ya está configurado en la imagen oficial)
# EXPOSE 5050

# Inicia pgAdmin al ejecutar el contenedor
CMD ["pgadmin4"]