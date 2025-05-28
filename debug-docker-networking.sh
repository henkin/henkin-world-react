#!/bin/bash

echo "=== Docker Networking Diagnostic Script ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Checking Docker networks..."
docker network ls
echo ""

echo "2. Inspecting 'proxy' network..."
if docker network inspect proxy >/dev/null 2>&1; then
    echo "✓ 'proxy' network exists"
    docker network inspect proxy --format '{{range .Containers}}Container: {{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}'
else
    echo "✗ 'proxy' network does NOT exist"
fi
echo ""

echo "3. Checking running containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "4. Looking for henkin-world containers..."
HENKIN_CONTAINERS=$(docker ps -q --filter "name=henkin")
if [ -n "$HENKIN_CONTAINERS" ]; then
    for container in $HENKIN_CONTAINERS; do
        echo "--- Container: $(docker ps --format '{{.Names}}' --filter id=$container) ---"
        echo "Status: $(docker inspect $container --format '{{.State.Status}}')"
        echo "Health: $(docker inspect $container --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}No healthcheck{{end}}')"
        echo "Networks:"
        docker inspect $container --format '{{range $net, $conf := .NetworkSettings.Networks}}  - {{$net}}: {{$conf.IPAddress}}{{"\n"}}{{end}}'
        echo ""
    done
else
    echo "✗ No henkin-world containers found"
fi
echo ""

echo "5. Looking for Traefik containers..."
TRAEFIK_CONTAINERS=$(docker ps -q --filter "name=traefik")
if [ -n "$TRAEFIK_CONTAINERS" ]; then
    for container in $TRAEFIK_CONTAINERS; do
        echo "--- Traefik Container: $(docker ps --format '{{.Names}}' --filter id=$container) ---"
        echo "Status: $(docker inspect $container --format '{{.State.Status}}')"
        echo "Networks:"
        docker inspect $container --format '{{range $net, $conf := .NetworkSettings.Networks}}  - {{$net}}: {{$conf.IPAddress}}{{"\n"}}{{end}}'
        echo ""
    done
else
    echo "✗ No Traefik containers found"
fi
echo ""

echo "6. Checking recent Traefik logs for networking errors..."
TRAEFIK_CONTAINERS=$(docker ps -q --filter "name=traefik")
if [ -n "$TRAEFIK_CONTAINERS" ]; then
    for container in $TRAEFIK_CONTAINERS; do
        echo "--- Recent Traefik logs (last 20 lines) ---"
        docker logs --tail 20 $container 2>&1 | grep -E "(error|ERR|unable to find|IP address)"
        echo ""
    done
fi

echo "7. Checking henkin-world container logs..."
HENKIN_CONTAINERS=$(docker ps -q --filter "name=henkin")
if [ -n "$HENKIN_CONTAINERS" ]; then
    for container in $HENKIN_CONTAINERS; do
        echo "--- Recent henkin-world logs (last 10 lines) ---"
        docker logs --tail 10 $container 2>&1
        echo ""
    done
fi

echo "8. Testing connectivity from Traefik to henkin-world..."
TRAEFIK_CONTAINERS=$(docker ps -q --filter "name=traefik")
HENKIN_CONTAINERS=$(docker ps -q --filter "name=henkin")
if [ -n "$TRAEFIK_CONTAINERS" ] && [ -n "$HENKIN_CONTAINERS" ]; then
    TRAEFIK_CONTAINER=$(echo $TRAEFIK_CONTAINERS | head -n1)
    HENKIN_CONTAINER=$(echo $HENKIN_CONTAINERS | head -n1)
    HENKIN_IP=$(docker inspect $HENKIN_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{if eq $net "proxy"}}{{$conf.IPAddress}}{{end}}{{end}}')
    
    if [ -n "$HENKIN_IP" ]; then
        echo "Testing connection from Traefik to henkin-world at $HENKIN_IP:4002..."
        docker exec $TRAEFIK_CONTAINER sh -c "wget -q --timeout=5 --tries=1 -O- http://$HENKIN_IP:4002 >/dev/null 2>&1 && echo '✓ Connection successful' || echo '✗ Connection failed'"
    else
        echo "✗ Could not find henkin-world IP on proxy network"
    fi
else
    echo "✗ Cannot test connectivity - missing Traefik or henkin-world containers"
fi

echo ""
echo "=== Diagnostic Complete ===" 