# Para Railway: sirve la carpeta public con Caddy
FROM caddy:2-alpine
COPY public /srv
CMD caddy file-server --root /srv --listen :${PORT:-8080}
