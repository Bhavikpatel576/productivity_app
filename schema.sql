

CREATE TABLE lists (
    id serial PRIMARY KEY,
    name text NOT NULL UNIQUE
);

CREATE TABLE todos (
    id serial PRIMARY KEY,
    name text NOT NULL,
    completed boolean NOT NULL default FALSE,
    list_id integer NOT NULL REFERENCES lists(id)
); 
