# Notes on using the docker container

To see the running container and image and ports:
```bash
docker ps
```

To interact and enter the container:
```bash
docker exec -it <docker_container_or_id> bash
```

To connect to the PostgreSQL database:
```bash
psql -U postgres -d bookings
```
