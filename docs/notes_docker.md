# Notes on using the docker container

Various commands to use to interact with the docker container

1. to build the image:
```bash
docker build -t pursuit_dbt .
docker run -d -p 5438:5432 --name pursuit_dbt pursuit_dbt
```

the above `-p` flag forwards messages from port 5438 locally to port 5432 inside the docker container which is by default where postgres listens to incoming messages. 
Read more about docker port forwarding.

To verify everything worked, ensure you only see no errors and just the database creation logs here:
```bash
docker logs <docker container id from docker run>
```

If no errors are in the container:

You now should be able to run `dbt run`.


2. To see the running container and image and ports:
```bash
docker ps
```

3. To interact and enter the container:
```bash
docker exec -it <containerid> bash
```

The above is useful if you want to inspect  the database. Once inside you can run `psql -U postgres -d bookings` since we created a database called `bookings`. Look at your postgres dump file in the `database` folder to verify.

4. To connect to the PostgreSQL database once inside the docker container:
```bash
psql -U postgres -d bookings
```

5. To remove an image
```bash
docker image rm 44873cf44e4b
```

you might need a -f flag if there's a dead container referencing your image.

6. To stop a container
```bash
docker stop ccfac1f88d1b
```

7. To stop and remove all containers:
```bash
docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
```

You can also run `docker container prune` to remove all dead containers. Might free up space on your laptop.
