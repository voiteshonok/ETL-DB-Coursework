# ETL-DB-Coursework

0) I have run Postgres db within docker and run pgAdmin on my local computer.

1) I generated data with chatGPT and stored it in data/ directory.

2) sport_oltp.sql has tables and scripts to make a db, tables and fill in data

( as I have a db in docker container, I copied data in container and upload it with \COPY function)

3) As we dont want to upload data that is already in db we use temporary tables that we drop after

4) in sport_olap.sql table definition and how to create a server that will help us to make an ETL process

5) Than with the help of this server we upload all the needed data to olap db

6) insight queries are stored in insight_queries/ directory

    olap_db_schema and oltp_db_schema describes databases and tables
