# Dbt practice project

Dbt is a fantastic framework for creating tables using sql. It's used in industry and great practice for creating tables without having to write the create table commands yourself. It's also a great way to write tests for your tables and for fully refreshing tables when needed. Let's explore.

You'll need to setup dbt. First look in the `docs/notes_dbt.md` file for some dbt setup.

# Setup (high level)

1. install dbt.
2. unzip the `database_zipped.zip` file using `unzip database_zipped.zip -d database`.
3. setup postgres container via the Dockerfile. Look in the `docs/notes_docker.md` for setup help.
4. enter the docker container and inspect the data
5. start writing dbt models.


# Extra docs to help you get started

I wrote some docs in the `docs` folder over the course of development of this project. Various commands are in there. Embrace the struggle of getting up and running!

- [dbt](docs/notes_dbt.md)
- [docker](docs/notes_docker.md)
- [database](docs/notes_on_database.md)
- [dbt_models](docs/notes_while_writing_dbt_models.md)

First unzip the migration folder because that file seeds our database using `unzip database_zipped.zip -d database`. Then create the container using docker (commands in the `docs/notes_docker.md` file). The setup of the database is in the docker file. Once you get that container up and running, you can run dbt with `dbt run`. Play around! That will get you acquanted with dbt, postgres, sql, and writing models.

# Using DBT

If you can run these commands, you're up and running!

To run all tests:
```
dbt test
```

All my tests are in the `tests` folder.

To run all models:

```
dbt run
```

# Assignment
Once you have the docker container for postgres running and the data loaded, write dbt models to create the following presentation tables. You can create them with `dbt run`. Write the sql, run dbt models, and inspect the data inside the postgres container that you have running.

1. A redemption is categorized as a free flight given to a customer. Imagine a rebooking due to bad weather, promotions, or vouches. Each airline designates a redemption differently (hint: look at the values in the `total_amount` column in the `bookings` tables. What are some weird values?). Find (hint: count) the number of redemption book by date.

2. Find the number of daily ticket sales, last 7d of ticket sales, and last 28d of ticket sales. For example, for the `sale_date` of Jan 24, 2024, I want to know what the number of sales were for Jan 24, 2024 but also the last 7 days and the last 28 days.

3. (hard). Find all valid comfortable routes involving 1 transfer or less. A route cannot start and end in the same city. A comfortable route has to be 24 hours or less. Figure out what I mean by that because I am a BI or data scientist that has given you vague requirements.
