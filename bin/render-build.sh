#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Create additional databases (main already exists from Render)
# Use || true to not fail if databases already exist
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d study_pet_production -c "CREATE DATABASE study_pet_production_cache;" || true
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d study_pet_production -c "CREATE DATABASE study_pet_production_queue;" || true
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d study_pet_production -c "CREATE DATABASE study_pet_production_cable;" || true

# Run migrations for all databases
bundle exec rails db:migrate
bundle exec rails db:migrate:cache
bundle exec rails db:migrate:queue
bundle exec rails db:migrate:cable
