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

# Questions to answer using the data model
Once you have the docker container for postgres running and the data loaded, write dbt models to create the following presentation tables

1. A redemption is categorized as a free flight given to a customer. Imagine a rebooking due to bad weather, promotions, or vouches. Each airline designates a redemption differently (hint: look at the values in the `total_amount` column in the `bookings` tables. What are some weird values?). Find (hint: count) the number of redemption book by date.


2. Find the number of daily ticket sales, last 7d of ticket sales, and last 28d of ticket sales. For example, for the `sale_date` of Jan 24, 2024, I want to know what the numbe of sales were for Jan 24, 2024 but also the last 7 days and the last 28 days.

3. (hard). Find all valid comfortable routes involving 1 transfer or less. A route cannot start and end in the same city. A comfortable route has to be 24 hours or less. Figure out what I mean by that because I am a BI or data scientist that has given you vague requirements.
