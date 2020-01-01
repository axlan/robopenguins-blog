---
title: SQL Murder Mystery
author: jon
layout: post
categories:
  - Software
image: https://mystery.knightlab.com/174092-clue-illustration.png
---

Had some fun playing the SQL murder mystery game at <https://mystery.knightlab.com/>. Pretty fun way to refresh myself on SQL syntax. I figured I'd record my thought process playing through it.

The site gives you the following info to start the puzzle:

```A crime has taken place and the detective needs your help. The detective gave you the crime scene report, but you somehow lost it. You vaguely remember that the crime was a ​murder​ that occurred sometime on ​Jan.15, 2018​ and that it took place in ​SQL City​. Start by retrieving the corresponding crime scene report from the police department’s database.```

You have access to the following tables:

| name                   |
|------------------------|
| crime_scene_report     |
| drivers_license        |
| person                 |
| facebook_event_checkin |
| interview              |
| get_fit_now_member     |
| get_fit_now_check_in   |
| income                 |
| solution               |
{:.mbtablestyle}

The place to start would be to look through the crime_scene_report table to find a report matching the info. First I looked at the table schema:

`CREATE TABLE crime_scene_report ( date integer, type text, description text, city text )`

Then I queried a single result from the table to get an idea of how the strings were being formatted:

```SELECT * FROM crime_scene_report LIMIT 1```

| date     | type    | description                                       | city |
|----------|---------|---------------------------------------------------|------|
| 20180115 | robbery | A Man Dressed as Spider-Man Is on a Robbery Spree | NYC  |
{:.mbtablestyle}

and out of curiosity checked the size of the table:

`SELECT COUNT(*) FROM crime_scene_report`

| COUNT(*) |
|----------|
| 1228     |
{:.mbtablestyle}

This sort of investigative query was pretty common as I went through the rest of the puzzle, but won't be included here.

From that I made the query:

`SELECT * FROM crime_scene_report WHERE date=20180115 AND city="SQL City"`

| date     | type    | description                                                                                                                                                                               | city     |
|----------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| 20180115 | assault | Hamilton: Lee, do you yield? Burr: You shot him in the side! Yes he yields!                                                                                                               | SQL City |
| 20180115 | assault | Report Not Found                                                                                                                                                                          | SQL City |
| 20180115 | murder  | Security footage shows that there were 2 witnesses. The first witness lives at the last house on "Northwestern Dr". The second witness, named Annabel, lives somewhere on "Franklin Ave". | SQL City |
{:.mbtablestyle}

So the relevant report was the murder.

This gave me two witnesses to lookup. After doing a similar basic check of the person table which had the structure:

`CREATE TABLE person ( id integer PRIMARY KEY, name text, license_id integer, address_number integer, address_street_name text, ssn integer, FOREIGN KEY (license_id) REFERENCES drivers_license(id) )`

I assumed the end of the street was at the highest number wrote the queries:

`SELECT MAX(address_number) FROM person WHERE address_street_name="Northwestern Dr"`

| MAX(address_number) |
|---------------------|
| 4919                |
{:.mbtablestyle}

`SELECT * FROM person WHERE address_street_name="Northwestern Dr" AND address_number=4919`

| id    | name           | license_id | address_number | address_street_name | ssn       |
|-------|----------------|------------|----------------|---------------------|-----------|
| 14887 | Morty Schapiro | 118009     | 4919           | Northwestern Dr     | 111564949 |
{:.mbtablestyle}

and

`SELECT * FROM person WHERE name LIKE "Annabel %" AND address_street_name="Franklin Ave"`

| id    | name           | license_id | address_number | address_street_name | ssn       |
|-------|----------------|------------|----------------|---------------------|-----------|
| 16371 | Annabel Miller | 490173     | 103            | Franklin Ave        | 318771143 |
{:.mbtablestyle}

This gave me the info I needed to look up their interviews. The interview table structure is `CREATE TABLE interview ( person_id integer, transcript text, FOREIGN KEY (person_id) REFERENCES person(id)`

`SELECT interview.* FROM interview WHERE person_id IN (14887,16371)`

|person_id | transcript |
|----------|------------|
| 14887    |I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. The membership number on the bag started with "48Z". Only gold members have those bags. The man got into a car with a plate that included "H42W".|
| 16371    |I saw the murder happen, and I recognized the killer from my gym when I was working out last week on January the 9th.|
{:.mbtablestyle}

This opened up the search a bit. I knew I'd need to look at the get_fit_now_member, get_fit_now_check_in, and drivers_license tables:

`CREATE TABLE get_fit_now_member ( id text PRIMARY KEY, person_id integer, name text, membership_start_date integer, membership_status text, FOREIGN KEY (person_id) REFERENCES person(id) )`

`CREATE TABLE get_fit_now_check_in ( membership_id text, check_in_date integer, check_in_time integer, check_out_time integer, FOREIGN KEY (membership_id) REFERENCES get_fit_now_member(id) )`

`CREATE TABLE drivers_license ( id integer PRIMARY KEY, age integer, height integer, eye_color text, hair_color text, gender text, plate_number text, car_make text, car_model text )`

It took a little bit for me to realize that the way to reference drivers license was that the license_id is a field in the person table. To resolve the foreign key, I decided to use inner joins.

```
SELECT *
FROM get_fit_now_member as gfnm
INNER JOIN get_fit_now_check_in as gfnci ON gfnci.membership_id=gfnm.id
INNER JOIN person ON gfnm.person_id=person.id
INNER JOIN drivers_license ON drivers_license.id=person.license_id
WHERE gfnci.check_in_date=20180109 AND gfnm.id LIKE "48Z%" AND drivers_license.plate_number LIKE "%H42W%"
```

| id    | person_id | name          | membership_start_date | membership_status | membership_id | check_in_date | check_in_time | check_out_time | id    | name          | license_id | address_number | address_street_name   | ssn       | id     | age | height | eye_color | hair_color | gender | plate_number | car_make  | car_model |
|-------|-----------|---------------|-----------------------|-------------------|---------------|---------------|---------------|----------------|-------|---------------|------------|----------------|-----------------------|-----------|--------|-----|--------|-----------|------------|--------|--------------|-----------|-----------|
| 48Z55 | 67318     | Jeremy Bowers | 20160101              | gold              | 48Z55         | 20180109      | 1530          | 1700           | 67318 | Jeremy Bowers | 423327     | 530            | Washington Pl, Apt 3A | 871539279 | 423327 | 30  | 70     | brown     | brown      | male   | 0H42W2       | Chevrolet | Spark LS  |
{:.mbtablestyle}

This gave me the main culprit, but checking the answer gives the message 

```Congrats, you found the murderer! But wait, there's more... If you think you're up for a challenge, try querying the interview transcript of the murderer to find the real villian behind this crime. If you feel especially confident in your SQL skills, try to complete this final step with no more than 2 queries. Use this same INSERT statement to check your answer.```

To solve the second puzzle I got looked up the interview:

`SELECT interview.* FROM interview WHERE person_id = 67318`

| person_id | transcript                                                                                                                                                                                                                                       |
|-----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 67318     | I was hired by a woman with a lot of money. I don't know her name but I know she's around 5'5" (65") or 5'7" (67"). She has red hair and she drives a Tesla Model S. I know that she attended the SQL Symphony Concert 3 times in December 2017. |
{:.mbtablestyle}

I started by looking at the facebook_event_checkin table:

`CREATE TABLE facebook_event_checkin ( person_id integer, event_id integer, event_name text, date integer, FOREIGN KEY (person_id) REFERENCES person(id) )`

```
SELECT * FROM drivers_license
JOIN person ON drivers_license.id=person.license_id
JOIN facebook_event_checkin as fec ON person.id=fec.person_id
WHERE drivers_license.car_model="Model S" AND drivers_license.hair_color="red" AND drivers_license.height BETWEEN 65 AND 67 AND fec.event_name="SQL Symphony Concert"
```

| id     | age | height | eye_color | hair_color | gender | plate_number | car_make | car_model | id    | name             | license_id | address_number | address_street_name | ssn       | person_id | event_id | event_name           | date     |
|--------|-----|--------|-----------|------------|--------|--------------|----------|-----------|-------|------------------|------------|----------------|---------------------|-----------|-----------|----------|----------------------|----------|
| 202298 | 68  | 66     | green     | red        | female | 500123       | Tesla    | Model S   | 99716 | Miranda Priestly | 202298     | 1883           | Golden Ave          | 987756388 | 99716     | 1143     | SQL Symphony Concert | 20171206 |
| 202298 | 68  | 66     | green     | red        | female | 500123       | Tesla    | Model S   | 99716 | Miranda Priestly | 202298     | 1883           | Golden Ave          | 987756388 | 99716     | 1143     | SQL Symphony Concert | 20171212 |
| 202298 | 68  | 66     | green     | red        | female | 500123       | Tesla    | Model S   | 99716 | Miranda Priestly | 202298     | 1883           | Golden Ave          | 987756388 | 99716     | 1143     | SQL Symphony Concert | 20171229 |
{:.mbtablestyle}


Turns out this was enough to solve this new mystery. However, just for fun, I decided to do a more complicated query to solve it a bit more directly.

```
SELECT groups.name
FROM (
	SELECT person.name, COUNT(fec.event_id) as num_concert
	FROM facebook_event_checkin as fec
	JOIN person ON person.id=fec.person_id
	JOIN drivers_license ON drivers_license.id=person.license_id
	WHERE drivers_license.car_model="Model S" AND drivers_license.hair_color="red" AND drivers_license.height BETWEEN 65 AND 67 AND fec.event_name="SQL Symphony Concert"
	GROUP BY person.name
) as groups
WHERE num_concert = 3
```

| name             |
|------------------|
| Miranda Priestly |
{:.mbtablestyle}

This last query hits most of the features I'm familiar with with SQL that aren't performance optimizations, so it was pretty satisfying.
