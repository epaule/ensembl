# Patch SQL required to convert Ensembl version 27 schemas to version 28

# Now have 2 separate RefSeq external_db entries
UPDATE external_db SET db_name='RefSeq_dna' WHERE db_name='RefSeq';
INSERT INTO external_db VALUES (1810, 'RefSeq_peptide', 1, 'KNOWN');

# Modify column definition of xref.dbprimary_acc to remove binary property
# and make display_label binary
ALTER TABLE xref MODIFY dbprimary_acc VARCHAR(40) NOT NULL;
ALTER TABLE xref MODIFY display_label VARCHAR(40) binary NOT NULL;

# Add analysis_description table
CREATE TABLE analysis_description (
  analysis_id	               int(10) unsigned NOT NULL,
  description                  text,
  display_label                varchar(255),

  KEY analysis_idx( analysis_id )
);
