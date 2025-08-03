# NGINX PROXY MANAGER configuration for selfhosting.
**Table of Contents:**
 + [Nextcloud Configuration](#nextcloud-configuration)
 + [OnlyOffice Document Server Configuration](#onlyoffice-document-server-configuration)
## Nextcloud Configuration

Create the proxy host like this:
[NPM1]
Make sure your domain is correct, set the LXC container IP with http protocol and port 80.
Enable "Websockets Support" and "Block Common Exploits".

Select your SSL certificate, if you don't have any then select "Request a new SSL certificate" and use the certbot plugin according to your domain dns provider.
[Wildcard Certificates](https://www.ssl.com/article/what-is-a-wildcard-ssl-certificate/) are recommended for security measures and flexibility.

[NPM2]
Enable "Force SSL", "HTTP/2 Support", "HSTS Enabled", "HSTS Subdomains".

Go to the advanced tab and set the following configuration:
[NPM3]

Nginx server configuration:
Go to your LXC container command line and edit `/etc/nginx/conf.d/nextcloud-http.conf` or `/etc/nginx/conf.d/nextcloud-https.conf`

Uncomment these lines and set your Nginx Proxy Manager IP instead of `0.0.0.0`:

    # Reverse proxy settings, uncomment the following lines if you want to use a proxy.
    real_ip_header X-Forwarded-For;
    set_real_ip_from 0.0.0.0/24;  # Restrict to your proxy IP

Nextcloud Server Configuration:
Add the following configuration to `/var/www/nextcloud/config/config.php`

    'trusted_domains' =>
    array (
      0 => '127.0.0.1',
      1 => 'localhost',
      2 => '192.168.1.9', // Edit according to your Nextcloud LXC external IP.
      3 => '::1',
      4 => 'yourdomain.example', // Edit according to your domain.
    ),
    'trusted_proxies' =>
    array (
      0 => '127.0.0.1',
      1 => '::1',
      2 => '192.168.1.6', // Edit according to your Nginx Proxy Manager IP.
    ),
    'overwrite.cli.url' => 'https://yourdomain.example', // Edit according to your domain.

Restart Nginx and PHP:

    sudo systemctl restart nginx phpX.Y-fpm # Where X.Y is your PHP version.


## OnlyOffice Document Server Configuration

You will need a second subdomain to handle connections for OnlyOffice docs, subfolder configuration is not supported at this moment.

Create a Proxy Host with the following configuration:
[IMG1-Host]
Change the IP to the one of your LXC Container, protocol http and the port 8081.

*NOTE: If you want to use Onlyoffice in Nextcloud with the public domain and locally, you need to disable the "Block Common Exploits" option, otherwise the connection will fail, the downside to this is that you will be more vulnerable to file and sql injection attacks, so it's up to you decide. I recommend to disable this option for debugging purposes only.*

[IMG-SSL]
Select your SSL certificate, if you don't have any then select "Request a new SSL certificate" and use the certbot plugin according to your domain dns provider.
Enable "Force SSL", "HTTP/2 Support", "HSTS Enabled", "HSTS Subdomains".

Now go to the Onlyoffice connector settings in Nextcloud and set the URL of your subdomain:
https//office.yourdomain.example

Leave your JWT token and authorization header without changes.

Now save the configuration and see if Nextcloud can connect to the server.
[IMG-TEST]
