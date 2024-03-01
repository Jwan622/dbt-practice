# Dbt practice project

I wrote some docs in the `docs` folder over the course of development. The docs are mainly for me, but feel free to read them.
- [dbt](docs/notes_dbt.md)
- [docker](docs/notes_docker.md)
- [database](docs/notes_on_database.md)
- [dbt_models](docs/notes_while_writing_dbt_models.md)

first unzip the migration folder because that file seeds our database using `unzip database_zipped.zip -d database`. Then create the container using docker (commands in the `docs/notes_docker.md` file). The setup of the database is in the docker file. Once you get that container up and running, you can run dbt.

To run all tests:
```
dbt test
```

All my tests are in the `tests` folder.

To run all models:

```
dbt run
```

Thanks for the pretty interesting interview! The last question was tricky!
