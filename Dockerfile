FROM httpd
COPY app/SampleWebApp/ /usr/local/apache2/htdocs/

EXPOSE 80
