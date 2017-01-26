-- Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
-- Copyright [2016] EMBL-European Bioinformatics Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

# patch_85_86_d.sql
#
# Title: protein feature uniqueness
#
# Description:
#   change unique key aln_idx to be analysis specific

ALTER TABLE protein_feature 
	DROP INDEX aln_idx,
        ADD UNIQUE KEY aln_idx (translation_id,hit_name,seq_start,seq_end,hit_start,hit_end,analysis_id);

# Patch identifier
INSERT INTO meta (species_id, meta_key, meta_value)
  VALUES (NULL, 'patch', 'patch_85_86_d.sql|protein_featue_uniqueness);
