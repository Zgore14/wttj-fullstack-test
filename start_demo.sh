#!/bin/bash

# Start PostgreSQL in Docker
echo "Starting PostgreSQL Docker container..."
docker run -d \
  --name wttj-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=wttj_db \
  -p 5432:5432 \
  -v postgres_wttj_db_data:/var/lib/postgresql/data \
  postgres:17-alpine

echo "Waiting for PostgreSQL to start..."
# Wait for PostgreSQL to be ready
until docker exec wttj-postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "PostgreSQL is not ready yet. Waiting..."
  sleep 1
done
echo "PostgreSQL is ready."

# Set environment variables
export MIX_ENV=dev

# Set up a trap to stop all child processes on exit
trap 'kill 0' EXIT

# Start the frontend
echo "Starting the frontend..."
cd assets
yarn
yarn dev &
cd ..

# Start the backend
echo "Starting the backend..."
mix deps.get
mix ecto.reset
iex -S mix phx.server
