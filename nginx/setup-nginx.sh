#!/usr/bin/env bash
# setup-nginx.sh
# Copies nginx configs and enables sites.
# Run on the EC2 instance after deploying.

set -euo pipefail

SITE_NAME="realgoldfang-site"
APT_NAME="realgoldfang-apt"

echo "==> copying nginx configs"
sudo cp realgoldfang-site.conf /etc/nginx/sites-available/${SITE_NAME}.conf
sudo cp realgoldfang-apt.conf /etc/nginx/sites-available/${APT_NAME}.conf

echo "==> enabling sites"
sudo ln -sf /etc/nginx/sites-available/${SITE_NAME}.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/${APT_NAME}.conf /etc/nginx/sites-enabled/

# Remove default site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

echo "==> creating web roots"
sudo mkdir -p /var/www/site
sudo mkdir -p /var/www/apt
sudo chown -R www-data:www-data /var/www/site /var/www/apt

echo "==> testing nginx config"
sudo nginx -t

echo "==> reloading nginx"
sudo systemctl reload nginx

echo "==> done. sites enabled:"
echo "  https://realgoldfang.github.io  -> /var/www/site"
echo "  https://apt.realgoldfang.dev    -> /var/www/apt"
echo ""
echo "next steps:"
echo "  1. deploy the built site to /var/www/site"
echo "  2. run certbot for both domains:"
echo "     sudo certbot --nginx -d realgoldfang.github.io"
echo "     sudo certbot --nginx -d apt.realgoldfang.dev"
