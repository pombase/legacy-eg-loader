#!/usr/bin/env python

#get library modules
import sys, os, re#, argparse

motif_list_forward = { 
  'SO:0001864': {'name': 'Sap1_recognition_motif', 'pattern': [re.compile('TA[AG]GCAG.T.[CT]AACG[AC]G')]},
  'SO:0001842': {'name': 'AP_1_binding_site', 'pattern': [re.compile('TGACTCA')]},
  'SO:0001865': {'name': 'calcineurin-dependent_response_element_(CDRE_motif)', 'pattern': [re.compile('G.GGC[GT]CA')]},
  'SO:0001843': {'name': 'cyclic_AMP_response_element_(CRE)', 'pattern': [re.compile('TGACGTCA')]},
  'SO:0001839': {'name': 'CSL_response_element', 'pattern': [re.compile('GTG[AG]GAA')]},
  'SO:0001844': {'name': 'copper-response_element_(CuRE)', 'pattern': [re.compile('[ACT]T[ACT]..GCTG[AGT]')]},
  'SO:0001845': {'name': 'DNA_damage_response_element_(DRE)', 'pattern': [re.compile('CG[AT]GG[AT].G[AC][AC]')]},
  'SO:0001846': {'name': 'FLEX_element', 'pattern': [re.compile('GTAAACAAACAAA[AC]')]},
  'SO:0001847': {'name': 'forkhead_motif', 'pattern': [re.compile('TTT[AG]TTTACA')]},
  'SO:0001848': {'name': 'homol_D_box', 'pattern': [re.compile('CAGTCACA')]},
  'SO:0001849': {'name': 'homol_E_box', 'pattern': [re.compile('ACCCTACCCT')]},
  'SO:0001850': {'name': 'heat_shock_element_(HSE)', 'pattern': [re.compile('.GAA..GAA..GAA.')]},
  'SO:0001851': {'name': 'iron_repressed_GATA_element', 'pattern': [re.compile('[AT]GATAA')]},
  'SO:0001852': {'name': 'mating_type_M_box', 'pattern': [re.compile('ACAAT')]},
  'SO:0001861': {'name': 'sterol_regulatory_element', 'pattern': [re.compile('ATCACCCCAC')]},
  'SO:0001859': {'name': 'STREP_motif', 'pattern': [re.compile('CCCCTC')]},
  'SO:0001858': {'name': 'TR_box', 'pattern': [re.compile('TTCTTTGTT[CT]')]},
  'SO:0001857': {'name': 'Ace2_UAS', 'pattern': [re.compile('CCAGCC')]},
  'SO:0001856': {'name': 'CCAAT_motif', 'pattern': [re.compile('CCAAT')]},
  'SO:0001855': {'name': 'MluI_cell_cycle_box_(MCB)', 'pattern': [re.compile('ACGCGT')]},
  'SO:0001871': {'name': 'pombe_cell_cycle_box_(PCB)', 'pattern': [re.compile('G.AAC[AG]')]}
}

motif_list_reverse = {
  'SO:0001864': {'name': 'Sap1_recognition_motif', 'pattern': [re.compile('C[TG]CGTT[GA].A.CTGC[TC]TA')]},
  'SO:0001842': {'name': 'AP_1_binding_site', 'pattern': [re.compile('TGAGTCA')]},
  'SO:0001865': {'name': 'calcineurin-dependent_response_element_(CDRE_motif)', 'pattern': [re.compile('TG[AC]GCC.C')]},
  'SO:0001843': {'name': 'cyclic_AMP_response_element_(CRE)', 'pattern': [re.compile('TGACGTCA')]},
  'SO:0001839': {'name': 'CSL_response_element', 'pattern': [re.compile('TTC[CT]CAC')]},
  'SO:0001844': {'name': 'copper-response_element_(CuRE)', 'pattern': [re.compile('[ACT]CAGC..[AGT]A[AGT]')]},
  'SO:0001845': {'name': 'DNA_damage_response_element_(DRE)', 'pattern': [re.compile('[GT][GT]C.[AT]CC[AT]CG')]},
  'SO:0001846': {'name': 'FLEX_element', 'pattern': [re.compile('[GT]TTTGTTTGTTTAC')]},
  'SO:0001847': {'name': 'forkhead_motif', 'pattern': [re.compile('TGTAAA[CT]AAA')]},
  'SO:0001848': {'name': 'homol_D_box', 'pattern': [re.compile('TGTGACTG')]},
  'SO:0001849': {'name': 'homol_E_box', 'pattern': [re.compile('AGGGTAGGGT')]},
  'SO:0001850': {'name': 'heat_shock_element_(HSE)', 'pattern': [re.compile('.TTC..TTC..TTC.')]},
  'SO:0001851': {'name': 'iron_repressed_GATA_element', 'pattern': [re.compile('TTATC[AT]')]},
  'SO:0001852': {'name': 'mating_type_M_box', 'pattern': [re.compile('ATTGT')]},
  'SO:0001861': {'name': 'sterol_regulatory_element', 'pattern': [re.compile('GTGGGGTGAT')]},
  'SO:0001859': {'name': 'STREP_motif', 'pattern': [re.compile('GAGGGG')]},
  'SO:0001858': {'name': 'TR_box', 'pattern': [re.compile('[AG]AACAAAGAA')]},
  'SO:0001857': {'name': 'Ace2_UAS', 'pattern': [re.compile('GGCTGG')]},
  'SO:0001856': {'name': 'CCAAT_motif', 'pattern': [re.compile('ATTGG')]},
  'SO:0001855': {'name': 'MluI_cell_cycle_box_(MCB)', 'pattern': [re.compile('ACGCGT')]},
  'SO:0001871': {'name': 'pombe_cell_cycle_box_(PCB)', 'pattern': [re.compile('[CT]GTT.C')]}

}

for chrom in ['I', 'II', 'III', 'MT']:
  print chrom
  fi = open("data/tmp/bindingMotif/Schizosaccharomyces_pombe.ASM294v2.30.dna." + chrom + ".fa", "r")
  lines = fi.readlines()
  fi.close()
  lines = lines[1:]
  lines = map(lambda s: s.strip(), lines)
  dna = ""
  dna = "".join(lines)

  fo = open("data/tmp/bindingMotif/binding_motifs_chr" + chrom + ".bed", "w")
  for k in motif_list_forward.keys():
    for p in motif_list_forward[k]['pattern']:
      for m in re.finditer(p, dna):
        fo.write(chrom + "\t" + str(m.start()+1) + "\t" + str(m.end()) + "\t" + motif_list_forward[k]['name'] + "\t0\t+\n")
  for k in motif_list_reverse.keys():
    for p in motif_list_reverse[k]['pattern']:
      for m in re.finditer(p, dna):
        fo.write(chrom + "\t" + str(m.end()) + "\t" + str(m.start()+1) + "\t" + motif_list_reverse[k]['name'] + "\t0\t-\n")
  fo.close()

