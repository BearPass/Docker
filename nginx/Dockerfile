FROM nginx:alpine

COPY ./conf/nginx.conf /etc/nginx/
COPY ./conf/conf.d/app.conf /etc/nginx/conf.d/app.conf

RUN rm /etc/nginx/conf.d/default.conf