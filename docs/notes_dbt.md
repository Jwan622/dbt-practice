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
