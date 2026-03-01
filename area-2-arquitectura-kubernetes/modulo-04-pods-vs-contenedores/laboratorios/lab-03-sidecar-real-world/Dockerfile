# Ejercicio 2: Dockerfile - Imagen de la aplicacion Flask
# Descripcion:
#   Imagen minimalista basada en python:3.9-slim que instala Flask
#   y crea el directorio /var/log/app para almacenar los logs
#   que el sidecar Fluent Bit consumira desde el shared volume.
#
# Uso: docker build -t sidecar-webapp:v1 .
# (Opcional) minikube image load sidecar-webapp:v1

FROM python:3.9-slim
WORKDIR /app
COPY web-app.py .
RUN pip install flask && mkdir -p /var/log/app
EXPOSE 5000
CMD ["python", "web-app.py"]
