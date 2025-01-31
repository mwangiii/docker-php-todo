#!/bin/bash

php artisan migrate --force
php artisan db:seed --force
php artisan cache:clear
php artisan config:clear
php artisan route:clear

php artisan serve  --host=0.0.0.0