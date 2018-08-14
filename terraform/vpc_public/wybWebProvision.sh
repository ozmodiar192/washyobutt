sudo apt-get update
sudo apt install -y docker.io
sudo service docker restart
git clone https://github.com/ozmodiar192/washyobutt.git
docker run --name wybWeb -p 80:80 -p 443:443 -d -v ~/washyobutt/content/html:/usr/share/nginx/html:ro nginx
