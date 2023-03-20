docker run --rm -d --name haproxy \
	-v $(pwd):/usr/local/etc/haproxy:ro \
	--sysctl net.ipv4.ip_unprivileged_port_start=0 \
	-p 80:80 \
	-p 443:443 \
	-p 8404:8404 \
	haproxy:2.3
