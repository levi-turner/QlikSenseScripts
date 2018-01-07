/* ##############################################################################################################################
   Script Name: Recurse cleanup
   Description: the script is intended to delete all entities marked as soft deleted in QRS database
   Caution: PLEASE BACKUP the whole QRS database before execute the script, in case error occurs, restore the backup, find out
            the data descrepancy, fix then execute again
   Revision history:
   Version     Date         Author    Change Notes
   # 0.0.1     2016-08-22   Quan Sun  Initial version
   # 0.0.1     2016-08-23   Vijay Vekariya  Changed owned objects of deleted user to sa_repository
   # 1.6.0     2016-10-10   Vijay Vekariya  Changed to remove everything older than 3 days
   ##############################################################################################################################
 */

/* Step 1. Update records according to QRS special logics
   ##############################################################################################################################
 */
  -- Step 1.1 Update Owner to sa_repository if Owner is deleted
  
	-- Step 1.1.1 Get all Qlik Sense Tables	
	CREATE OR REPLACE FUNCTION get_all_sense_tables() RETURNS SETOF information_schema.tables AS
	$BODY$
	BEGIN
	    RETURN QUERY SELECT *
		  FROM information_schema.tables
		 WHERE table_schema='public'
		   AND table_type='BASE TABLE'
		   AND table_catalog='QSR'
		   AND table_name <> '__MigrationHistory';
	    RETURN;
	END
	$BODY$
	LANGUAGE plpgsql;
	
	-- Step 1.1.2 Filter Qlik Sense Tables with name of column
	CREATE OR REPLACE FUNCTION get_tables(columnname varchar) 
	RETURNS SETOF information_schema.columns AS $$
	BEGIN
	    RETURN QUERY SELECT DISTINCT * FROM information_schema.columns as isc WHERE isc.column_name = columnname And isc.table_name IN (SELECT ts.table_name FROM get_all_sense_tables() as ts);
	    RETURN;
	END
	$$
	LANGUAGE plpgsql;

	-- Step 1.1.3 Change ownership of soft deleted users to sa_repository
	CREATE OR REPLACE FUNCTION fix_orphan_owners() RETURNS void AS
	$BODY$
	DECLARE username character varying;
	DECLARE
	    tables CURSOR FOR
		SELECT * FROM get_tables('Owner_ID');
	
	BEGIN
	    SELECT E'\'sa_repository\'' INTO username;
	    FOR table_record IN tables LOOP
		EXECUTE 'UPDATE "' || table_record.table_name || '" SET "Owner_ID" = (SELECT "ID" FROM "Users" WHERE "UserId" = ' || username || ') WHERE "Owner_ID" IN (SELECT "ID" FROM "Users" WHERE "Deleted" = true)';
	    END LOOP;
	END
	$BODY$
	LANGUAGE 'plpgsql';

	SELECT * FROM fix_orphan_owners();

	-- Step 1.1.4 Remove created DB functions for fixing ownership relations
	DROP FUNCTION fix_orphan_owners();
	DROP FUNCTION get_tables(columnname varchar);
	DROP FUNCTION get_all_sense_tables();

  -- Step 1.2 Unpublish App if Steam is deleted  
  UPDATE "Apps"
     SET "Stream_ID" = null, "Published" = false
   WHERE "Stream_ID" IN (SELECT "ID" FROM "Streams" where "Deleted" = true);
   
   UPDATE "AppObjects"
     SET "Approved" = false, "Published" = false
   WHERE "App_ID" IN (SELECT "ID" FROM "Apps" where "Published" = false);

/* Step 2. Prepare for deletion: Alter foreign keys to Casacade Delete
   ##############################################################################################################################
 */

 CREATE TABLE temp_foreign_key (
    constraint_name VARCHAR,
    table_name VARCHAR,
    column_name VARCHAR,
    ref_table_name VARCHAR,
    ref_column_name VARCHAR
  );

  INSERT INTO temp_foreign_key (constraint_name, table_name, column_name, ref_table_name, ref_column_name)
  SELECT fk.constraint_name, child.table_name, child.column_name, parent.table_name, parent.column_name
    FROM information_schema.referential_constraints fk 
         JOIN information_schema.key_column_usage AS child ON fk.constraint_name = child.constraint_name
         JOIN information_schema.key_column_usage AS parent ON fk.unique_constraint_name = parent.constraint_name
   WHERE fk.constraint_schema = 'public'
     AND child.position_in_unique_constraint = parent.ordinal_position
     AND fk.delete_rule = 'NO ACTION';

  -- Step 2.2 Create a function the replace foreign keys with new on DELETE option
  CREATE OR REPLACE FUNCTION replace_foreign_key (new_option VARCHAR) RETURNS void AS
  $BODY$
  DECLARE
    fks CURSOR FOR
        SELECT * FROM temp_foreign_key;
  BEGIN
    FOR rec IN fks LOOP
      EXECUTE 'alter table "' || rec.table_name || '" '
	   || 'drop constraint "' || rec.constraint_name || '" ,'
	   || 'add constraint "' || rec.constraint_name || '" FOREIGN KEY ("' || rec.column_name || '") REFERENCES "' || rec.ref_table_name || '" ("' || rec.ref_column_name || '") ' || new_option || ';' ;
    END LOOP;
  END;
  $BODY$
  LANGUAGE plpgsql;

  -- Step 2.3 execute the function to replace all foreign keys with CASCADE on Delete
  SELECT * 
    FROM replace_foreign_key('on delete cascade');

/* Step 3. Delete entities marked as Soft Deleted
   ##############################################################################################################################
 */
  -- 3.1 Create a function to delete all SoftDeleted records
  CREATE OR REPLACE FUNCTION delete_softdeleted_records(keep_for_days int) RETURNS void AS
  $BODY$
  DECLARE
    entity_tables CURSOR FOR
           SELECT table_name 
             FROM information_schema.columns
            WHERE table_schema='public'
              AND column_name='Deleted';
  BEGIN
    FOR tbl IN entity_tables LOOP
        EXECUTE 'delete from "' || tbl.table_name || '" where "Deleted" = true and "ModifiedDate" <= CURRENT_DATE - ' || keep_for_days || ';';
    END LOOP;
  END;
  $BODY$
  LANGUAGE plpgsql;

  -- Step 3.2 execute the function to delete entities
  SELECT * 
    FROM delete_softdeleted_records(3);

/* Step 4. Resume foreign keys to No Action on Delete
   ##############################################################################################################################
 */
  SELECT *
    FROM replace_foreign_key('');

/* Step 5. Drop temp objects
   ##############################################################################################################################
 */
DROP FUNCTION delete_softdeleted_records(keep_for_days int);
DROP FUNCTION replace_foreign_key(new_option varchar);
DROP TABLE temp_foreign_key;

