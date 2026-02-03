#!/usr/bin/env bash
set -e

# Website Checker Script
# Usage: ./check-website.sh <URL>
# Example: ./check-website.sh https://www.sportwetten-kanzlei.de

URL="${1:-https://www.sportwetten-kanzlei.de}"

echo "=========================================="
echo "Checking website: $URL"
echo "=========================================="
echo ""

# Extract hostname from URL
HOSTNAME=$(echo "$URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

echo "1. DNS Resolution Check"
echo "------------------------"
if host "$HOSTNAME" >/dev/null 2>&1; then
    echo "✓ DNS resolution successful"
    host "$HOSTNAME"
else
    echo "✗ DNS resolution failed - hostname cannot be resolved"
    echo "Error: The domain '$HOSTNAME' does not exist or cannot be reached"
    exit 1
fi
echo ""

echo "2. HTTP/HTTPS Connection Check"
echo "-------------------------------"
HTTP_CODE=$(curl -I -L -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$URL" 2>&1 || echo "FAILED")

if [ "$HTTP_CODE" = "FAILED" ]; then
    echo "✗ Connection failed - could not reach the server"
    exit 1
elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "✓ HTTP Status: $HTTP_CODE (Success)"
elif [ "$HTTP_CODE" -ge 300 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "⚠ HTTP Status: $HTTP_CODE (Redirect)"
elif [ "$HTTP_CODE" -ge 400 ] && [ "$HTTP_CODE" -lt 500 ]; then
    echo "✗ HTTP Status: $HTTP_CODE (Client Error)"
    exit 1
elif [ "$HTTP_CODE" -ge 500 ]; then
    echo "✗ HTTP Status: $HTTP_CODE (Server Error)"
    exit 1
else
    echo "? HTTP Status: $HTTP_CODE (Unknown)"
fi
echo ""

echo "3. Response Headers"
echo "-------------------"
curl -I -L -s "$URL" --connect-timeout 10 | head -15
echo ""

echo "4. SSL Certificate Check (if HTTPS)"
echo "------------------------------------"
if [[ "$URL" == https://* ]]; then
    if command -v openssl >/dev/null 2>&1; then
        echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Could not retrieve SSL certificate information"
    else
        echo "openssl not available, skipping SSL check"
    fi
else
    echo "Not an HTTPS URL, skipping SSL check"
fi
echo ""

echo "=========================================="
echo "Website check completed successfully!"
echo "=========================================="
