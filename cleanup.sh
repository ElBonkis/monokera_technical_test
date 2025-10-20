#!/bin/bash

echo "🧹 Cleaning up Monokera Technical Test..."
echo "=========================================="
echo ""
echo "⚠️  This will:"
echo "  - Stop all containers"
echo "  - Remove all containers"
echo "  - Remove all volumes (databases will be deleted)"
echo "  - Remove all networks"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

docker compose down -v --remove-orphans
docker system prune -f

echo ""
echo "✅ Cleanup complete!"