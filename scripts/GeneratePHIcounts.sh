#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

process_division.sh EF | grep core | sort | while read db; do mysql-staging-2 -t $db -e 'select meta.meta_value, count(*) from coord_system join meta on (coord_system.species_id=meta.species_id and meta.meta_key="species.display_name") join seq_region on (coord_system.coord_system_id=seq_region.coord_system_id) join transcript on (seq_region.seq_region_id=transcript.seq_region_id) join translation on (transcript.transcript_id=translation.transcript_id) join object_xref on (translation.translation_id=object_xref.ensembl_id and object_xref.ensembl_object_type="Translation") join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name="PHI" group by meta.meta_value;'; done | grep -v meta_value | grep -v + | sed -e 's/\ \ //g' | sed -e 's/^|\ //g' | sed -e 's/\ |$//g' | sed -e 's/\ |/|/g' | sed -e 's/|/\t/g' | sort
