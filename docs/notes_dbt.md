# Notes on dbt during development

When I first ran `dbt run`, I got:

```bash
11:30 $ dbt run
-bash: dbt: command not found
```

Wonderful. Let's install `dbt` for our new mac (I got myself a new mac a few days ago).

```bash
brew update
brew install git
brew tap dbt-labs/dbt
brew install dbt-postgres
brew update
brew upgrade dbt-postgres
```

Then I still needed to update `dbt`:

```bash
dbt --version
Core:
  - installed: 1.5.4
  - latest:    1.7.7 - Update available!

  Your version of dbt-core is out of date!
  You can find instructions for upgrading here:
  https://docs.getdbt.com/docs/installation

Plugins:
  - postgres: 1.5.4 - Update available!

  At least one plugin is out of date or incompatible with dbt-core.
  You can find instructions for upgrading here:
  https://docs.getdbt.com/docs/installation
```

I just ran:

```bash
brew install dbt
```


## How to query dbt output tables

Note that the profiles.yml has the schema listed as `dbt`. You can see the tables listed in this schema using:

So, once you're in the container and connected to postgres (notes on how to do this in [notes_docker](./notes_dbt.md)), you can run:

```postgresql
SELECT * FROM information_schema.tables WHERE table_schema = 'dbt'
```

and then something like:
```postgresql
select * from dbt.ticket_sales_counts limit 5;
```
