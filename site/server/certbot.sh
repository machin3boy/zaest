add-apt-repository ppa:certbot/certbot
apt install certbot
apt-get install python3-certbot-nginx
certbot --nginx -d zaestprototype.site -d www.zaestprototype.site
