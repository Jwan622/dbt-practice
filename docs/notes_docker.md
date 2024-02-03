# Notes on using the docker container

Various commands to use to interact with the docker container

1. To see the running container and image and ports:
```bash
docker ps
```

2. To interact and enter the container:
```bash
docker exec -it <docker_container_or_id> bash
```

3. To connect to the PostgreSQL database once inside the docker container:
```bash
psql -U postgres -d bookings
```
