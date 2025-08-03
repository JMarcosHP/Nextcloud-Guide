# NGINX PROXY MANAGER configuration for selfhosting.
**Table of Contents:**
 + [Nextcloud Configuration](#nextcloud-configuration)
 + [OnlyOffice Document Server Configuration](#onlyoffice-document-server-configuration)
## Nextcloud Configuration

Create the proxy host like this:

<img width="497" height="546" alt="Captura desde 2025-07-31 15-29-23" src="https://github.com/user-attachments/assets/84da5192-f0b7-410b-8d3f-fdbc5694fc0f" />

Make sure your domain is correct, set the LXC container IP with http protocol and port 80.
Enable "Websockets Support" and "Block Common Exploits".

Select your SSL certificate, if you don't have any then select "Request a new SSL certificate" and use the certbot plugin according to your domain dns provider.
[Wildcard Certificates](https://www.ssl.com/article/what-is-a-wildcard-ssl-certificate/) are recommended for security measures and flexibility.

<img width="497" height="386" alt="Captura desde 2025-07-31 15-29-47" src="https://github.com/user-attachments/assets/d415c1d8-f8b3-4d59-9dcc-3911b7f3c15b" />

Enable "Force SSL", "HTTP/2 Support", "HSTS Enabled", "HSTS Subdomains".


Go to the advanced tab and set the following configuration:

<img width="495" height="607" alt="Captura desde 2025-07-31 15-38-05" src="https://github.com/user-attachments/assets/5029f627-2fb9-4d9b-b0cc-5c01308fa257" />

Nginx server configuration:

Go to your LXC container command line and edit `/etc/nginx/conf.d/nextcloud-http.conf` or `/etc/nginx/conf.d/nextcloud-https.conf`

Uncomment these lines and set your Nginx Proxy Manager IP instead of `0.0.0.0`:

    # Reverse proxy settings, uncomment the following lines if you want to use a proxy.
    real_ip_header X-Forwarded-For;
    set_real_ip_from 0.0.0.0;  # Restrict to your proxy IP

Nextcloud Server Configuration:
Add the following configuration to `/var/www/nextcloud/config/config.php`

    'trusted_domains' =>
    array (
      0 => '127.0.0.1',
      1 => 'localhost',
      2 => '192.168.1.9', // Adjust according to your Nextcloud LXC external IP.
      3 => '::1',
      4 => 'yourdomain.example', // Adjust according to your domain.
    ),
    'trusted_proxies' =>
    array (
      0 => '127.0.0.1',
      1 => '::1',
      2 => '192.168.1.6', // Adjust according to your Nginx Proxy Manager IP.
    ),
    'overwrite.cli.url' => 'https://yourdomain.example', // Ajust according to your domain.

Restart Nginx and PHP:

    sudo systemctl restart nginx phpX.Y-fpm # Where X.Y is your PHP version.


## OnlyOffice Document Server Configuration

You will need a second subdomain to handle connections for OnlyOffice docs, subfolder configuration is not supported at this moment.

Create a Proxy Host with the following configuration:

<img width="500" height="549" alt="Captura desde 2025-07-31 20-22-33" src="https://github.com/user-attachments/assets/44678ce5-4a8e-41ef-b8d9-6333770c2238" />


Change the IP to the one of your LXC Container, protocol http and the port 8081.

*NOTE: If you want to use Onlyoffice in Nextcloud with the public domain and locally, you need to disable the "Block Common Exploits" option, otherwise the connection will fail, the downside to this is that you will be more vulnerable to file and sql injection attacks, so it's up to you decide. I recommend to disable this option for testing purposes only.*


Select your SSL certificate, if you don't have any then select "Request a new SSL certificate" and use the certbot plugin according to your domain dns provider.
Enable "Force SSL", "HTTP/2 Support", "HSTS Enabled", "HSTS Subdomains".

<img width="500" height="387" alt="Captura desde 2025-07-31 20-22-43" src="https://github.com/user-attachments/assets/0efa4a4f-0f17-4d44-9798-097a3708d760" />


Now go to the Onlyoffice connector settings in Nextcloud and set the URL of your subdomain:
<img width="1004" height="782" alt="Captura desde 2025-07-31 20-27-39" src="https://github.com/user-attachments/assets/89e1ed2c-25dd-4b3c-b1a1-20755e0e01d0" />

Leave your JWT token and authorization header without changes.

Now save the configuration and see if Nextcloud can connect to the server.
<img width="1873" height="995" alt="Captura desde 2025-07-31 22-59-10" src="https://github.com/user-attachments/assets/575ee4aa-5fe9-4043-976e-b2ea8061278e" />
Final Result.
