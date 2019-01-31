\timing on

SET client_min_messages TO WARNING;

DROP TABLE IF EXISTS towns;
CREATE TABLE Towns (
  id SERIAL,
  code VARCHAR(10),
  article TEXT,
  name TEXT, -- not unique
  department VARCHAR(4)
);
insert into towns (
    code, article, name, department
) select
    left(md5(i::text), 10),
    md5(random()::text),
    md5(random()::text),
    left(md5(random()::text), 4)
from generate_series(1, 2500000) s(i);

-- export to a file because Citus can't include subquery from a non-distributed table
\copy towns to 'towns.csv';


-- non-citus table: ltowns -- local table on master
DROP TABLE IF EXISTS ltowns;
CREATE TABLE lTowns (
  id SERIAL,
  code VARCHAR(10),
  article TEXT,
  name TEXT, -- not unique
  department VARCHAR(4)
);
\copy ltowns from 'towns.csv';

-- citus table: dtowns -- partitioned table
DROP TABLE IF EXISTS dtowns;
CREATE TABLE dTowns (
  id SERIAL,
  code VARCHAR(10),
  article TEXT,
  name TEXT, -- not unique
  department VARCHAR(4)
);
select create_distributed_table('dtowns', 'id');
\copy dtowns from 'towns.csv';

-- citus table: rtowns -- reference table (replicated on all nodes)
DROP TABLE IF EXISTS rtowns;
CREATE TABLE rTowns (
  id SERIAL,
  code VARCHAR(10),
  article TEXT,
  name TEXT, -- not unique
  department VARCHAR(4)
);
select create_reference_table('rtowns');
\copy rtowns from 'towns.csv';

-- run a query that requires postgis on the worker nodes
-- if postgis isn't working, you'll get parse_address doesn't exist
create table test_for_postgis(i bigint, s text);
select create_reference_table('test_for_postgis');
insert into test_for_postgis values (1000, '1 Devonshire Place PH301, Boston, MA 02109');
select * from dtowns where id = (select (a).num::bigint from (select parse_address(s) as a from test_for_postgis ) as foo)::bigint;

-- should be slow
select min(id::text||code||article||name||department) from ltowns;
select min(id::text||code||article||name||department) from rtowns;
-- should be fast
select min(id::text||code||article||name||department) from dtowns;

