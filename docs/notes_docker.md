# Notes on using the docker container

Various commands to use to interact with the docker container


1. to build the image:
```bash
docker build -t dbt_practice .
docker run -d dbt_practice
```

2. To see the running container and image and ports:
```bash
docker ps
```

3. To interact and enter the container:
```bash
docker exec -it <containerid> bash
```

4. To connect to the PostgreSQL database once inside the docker container:
```bash
psql -U postgres -d bookings
```

5. to remove an image
```bash
docker image rm 44873cf44e4b
```

6. to stop a container
```bash
docker stop ccfac1f88d1b
```


7. to stop and remove all containers:
```bash
docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
```
