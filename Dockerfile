FROM postgres:16-bookworm

RUN apt-get update && \
    apt-get install -y \
    postgresql-16-pgaudit \
    postgresql-16-pgtap \
    pgtap && \
    rm -rf /var/lib/apt/lists/*
