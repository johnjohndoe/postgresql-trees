

CREATE TABLE tree (
	tree_id serial PRIMARY KEY, 
	location geometry,
	created timestamp with time zone DEFAULT now(),
	CONSTRAINT tree_geom_uniq UNIQUE (location)
);


CREATE TABLE history (
	history_id serial PRIMARY KEY, 
	import_time timestamp with time zone DEFAULT now(),
	tree_id integer NULL, 
	value integer NOT NULL,
	CONSTRAINT history_tree_id_fkey FOREIGN KEY (tree_id) REFERENCES tree (tree_id) MATCH SIMPLE ON UPDATE RESTRICT ON DELETE RESTRICT
); 


# Look up or generate foreign key

CREATE FUNCTION get_tree(new_location geometry) RETURNS integer AS $$
DECLARE
	result_tree_id integer;
BEGIN
	SELECT tree_id FROM tree WHERE tree.location = new_location LIMIT 1 INTO result_tree_id;
	IF NOT FOUND THEN
		INSERT INTO tree (location) VALUES (new_location) RETURNING tree_id INTO result_tree_id;
	END IF;
	RETURN result_tree_id;
END
$$
LANGUAGE plpgsql;


# Create view combining both tables to execute INSERTs on

CREATE VIEW tree_history AS SELECT history.history_id, history.tree_id, tree.location, history.value FROM tree JOIN history ON tree.tree_id = history.tree_id;

# Create INSERT rule for redirect

CREATE RULE tree_history_insert AS ON INSERT TO tree_history DO INSTEAD INSERT INTO history (tree_id, value) VALUES (get_tree(NEW.location), NEW.value);

# TODO: RULES for UPDATE and DELETE


# Testing on each table separately

INSERT INTO history (value) VALUES (1);
INSERT INTO tree (location) VALUES (ST_GeomFromText('POINT(53 11)'));
INSERT INTO history (tree_id, value) VALUES (1,1);

# Testing cross reference between tables

INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 11)'), 2);
INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 11)'), 3);
INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 12)'), 4);
INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 12)'), 5);
INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 13)'), 6);
INSERT INTO tree_history (location, value) VALUES (ST_GeomFromText('POINT(53 13)'), 7);
