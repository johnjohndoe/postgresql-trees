

CREATE TABLE production.tree (
	tree_id serial PRIMARY KEY,
	location geometry,
	created timestamp with time zone DEFAULT now(),
	CONSTRAINT tree_geom_uniq UNIQUE (location)
);


CREATE TABLE production.history (
	history_id serial PRIMARY KEY,
	import_time timestamp with time zone DEFAULT now(),
	tree_id integer NULL,
	value integer NOT NULL,
	CONSTRAINT history_tree_id_fkey FOREIGN KEY (tree_id)
	REFERENCES production.tree (tree_id) MATCH SIMPLE
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
);


# Look up or generate foreign key

CREATE FUNCTION production.get_tree(new_location geometry) RETURNS integer AS $$
DECLARE
	result_tree_id integer;
BEGIN
	SELECT tree_id
	FROM production.tree
	WHERE tree.location = new_location
	LIMIT 1
	INTO result_tree_id;
	IF NOT FOUND THEN
		INSERT INTO production.tree (location)
		VALUES (new_location)
		RETURNING tree_id
		INTO result_tree_id;
	END IF;
	RETURN result_tree_id;
END
$$
LANGUAGE plpgsql;


# Create view combining both tables to execute INSERTs on

CREATE VIEW production.tree_history AS
	SELECT
		history.history_id,
		history.tree_id,
		tree.location,
		history.value
	FROM production.tree
	JOIN production.history
	ON tree.tree_id = history.tree_id;

# Create INSERT rule for redirect

CREATE RULE tree_history_insert AS
	ON INSERT TO production.tree_history
	DO INSTEAD
		INSERT INTO production.history (
			tree_id,
			value
		)
		VALUES (
			production.get_tree(NEW.location),
			NEW.value
		);

# TODO: RULES for UPDATE and DELETE


# Testing on each table separately

INSERT INTO production.history (value) VALUES (1);
INSERT INTO production.tree (location) VALUES (ST_GeomFromText('POINT(53 11)'));
INSERT INTO production.history (tree_id, value) VALUES (1,1);

# Testing cross reference between tables

INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 11)'), 2);
INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 11)'), 3);
INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 12)'), 4);
INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 12)'), 5);
INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 13)'), 6);
INSERT INTO production.tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 13)'), 7);
